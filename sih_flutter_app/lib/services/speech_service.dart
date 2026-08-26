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
        onError: (_) {},
        onStatus: (_) {},
        debugLogging: false,
      );
      return true;
    } catch (_) {
      _isInitialized = true;
      return true;
    }
  }

  /// Starts recording real audio from the physical phone microphone and streams recognized speech
  Future<bool> startListening({
    required Function(String text) onResult,
    Function(String status)? onStatusUpdate,
    String? localeId,
  }) async {
    final hasPerm = await requestMicPermission();
    if (!hasPerm) {
      onStatusUpdate?.call("Microphone permission denied.");
      return false;
    }

    onStatusUpdate?.call("Recording...");

    // Start physical audio recording to WAV
    await _audioRecorder.startRecording();
    _isRecording = true;

    // Start on-device speech recognizer concurrently for instant live word feedback
    try {
      if (await initialize()) {
        await _speech.listen(
          onResult: (result) {
            if (result.recognizedWords.trim().isNotEmpty) {
              onResult(result.recognizedWords);
            }
          },
          localeId: localeId ?? 'hi_IN',
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          cancelOnError: false,
          partialResults: true,
        );
      }
    } catch (_) {}

    return true;
  }

  /// Stops physical microphone recording and transcribes instantly
  Future<String?> stopListeningAndTranscribe({
    String? currentRecognizedText,
    Function(String status)? onStatusUpdate,
  }) async {
    _isRecording = false;

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    final File? audioFile = await _audioRecorder.stopRecording();

    // If on-device recognizer already captured words, return immediately with zero delay
    if (currentRecognizedText != null && currentRecognizedText.trim().isNotEmpty) {
      return currentRecognizedText.trim();
    }

    if (audioFile == null || !await audioFile.exists()) {
      return currentRecognizedText;
    }

    final fileSize = await audioFile.length();
    if (fileSize == 0) {
      return currentRecognizedText;
    }

    // Try Local AI IndicConformer with 3s fast timeout
    try {
      final asrResult = await LocalAiBridge.transcribeAudio(audioFile)
          .timeout(const Duration(seconds: 3));
      if (asrResult != null && asrResult.containsKey('text')) {
        final transcribedText = asrResult['text'].toString().trim();
        if (transcribedText.isNotEmpty) {
          return transcribedText;
        }
      }
    } catch (_) {}

    return currentRecognizedText;
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
