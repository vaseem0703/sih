import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'audio_recorder_service.dart';
import 'local_ai_bridge.dart';

class SpeechService {
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isRecording = false;

  bool get isListening => _isRecording || _speech.isListening;

  Future<bool> requestMicPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted || status.isLimited) return true;

      final result = await Permission.microphone.request();
      if (result.isGranted || result.isLimited) return true;

      return await _audioRecorder.hasPermission();
    } catch (_) {
      return true;
    }
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    final hasPerm = await requestMicPermission();
    if (!hasPerm) return false;

    try {
      _isInitialized = await _speech.initialize(
        onError: (errorNotification) {
          // ignore: avoid_print
          print('STT Speech Error: ${errorNotification.errorMsg}');
        },
        onStatus: (status) {
          // ignore: avoid_print
          print('STT Speech Status: $status');
        },
        debugLogging: false,
      );
      return true;
    } catch (_) {
      _isInitialized = true;
      return true;
    }
  }

  /// Starts recording real audio from the physical phone microphone
  Future<bool> startListening({
    required Function(String text) onResult,
    Function(String status)? onStatusUpdate,
    String? localeId,
  }) async {
    final hasPerm = await requestMicPermission();
    if (!hasPerm) {
      onStatusUpdate?.call("Microphone permission denied. Please allow in settings.");
      return false;
    }

    onStatusUpdate?.call("Recording real microphone audio...");

    // Start physical audio recording to WAV
    final path = await _audioRecorder.startRecording();
    if (path != null) {
      _isRecording = true;
      return true;
    }

    // Fallback to STT engine if AudioRecorder initialization failed
    try {
      await initialize();
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.trim().isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        localeId: localeId ?? 'hi_IN',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        cancelOnError: false,
        partialResults: true,
      );
      _isRecording = true;
      return true;
    } catch (e) {
      onStatusUpdate?.call("Microphone unavailable.");
      return false;
    }
  }

  /// Stops physical microphone recording and sends the real audio file to IndicConformer ASR
  Future<String?> stopListeningAndTranscribe({
    Function(String status)? onStatusUpdate,
  }) async {
    _isRecording = false;

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    final File? audioFile = await _audioRecorder.stopRecording();
    if (audioFile == null || !await audioFile.exists()) {
      return null;
    }

    final fileSize = await audioFile.length();
    if (fileSize == 0) {
      onStatusUpdate?.call("Empty audio recorded.");
      return null;
    }

    onStatusUpdate?.call("Processing Hindi ASR (${(fileSize / 1024).toStringAsFixed(1)} KB)...");

    // Send real WAV audio to Local IndicConformer ASR with 8s fast timeout
    try {
      final asrResult = await LocalAiBridge.transcribeAudio(audioFile);
      if (asrResult != null && asrResult.containsKey('text')) {
        final transcribedText = asrResult['text'].toString().trim();
        if (transcribedText.isNotEmpty) {
          onStatusUpdate?.call("Hindi transcript received.");
          return transcribedText;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> stopListening() async {
    _isRecording = false;
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      await _audioRecorder.stopRecording();
    } catch (_) {}
  }
}
