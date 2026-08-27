import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'audio_recorder_service.dart';
import 'local_ai_bridge.dart';

class SpeechService {
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _sttInitialized = false;
  bool _isWavRecording = false;
  String? _hindiLocaleId;

  bool get isListening => _isWavRecording || _speech.isListening;

  // ─────────────────────────────────────────────────────
  // Permission
  // ─────────────────────────────────────────────────────
  Future<bool> requestMicPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted || status.isLimited) return true;

      final result = await Permission.microphone.request();
      if (result.isGranted || result.isLimited) return true;

      return await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint('[SpeechService] Permission check error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────
  // STT Initialization
  // ─────────────────────────────────────────────────────
  Future<bool> _initSTT({Function(String status)? onStatusUpdate}) async {
    if (_sttInitialized && _speech.isAvailable) return true;

    _sttInitialized = false;
    debugPrint('[SpeechService] Calling speech.initialize()...');

    try {
      final result = await _speech.initialize(
        debugLogging: true, // Enable debug logging on all builds
        onError: (errorNotification) {
          final rawMsg = errorNotification.errorMsg.toLowerCase();
          debugPrint(
            '[SpeechService] STT raw notice: $rawMsg (permanent=${errorNotification.permanent})',
          );

          // Any offline / language / network / no_match notice from Google STT
          if (rawMsg.contains('language') ||
              rawMsg.contains('unavailable') ||
              rawMsg.contains('no_match') ||
              rawMsg.contains('network') ||
              rawMsg.contains('timeout') ||
              rawMsg.contains('no match')) {
            onStatusUpdate?.call(
              'Recording audio for offline IndicConformer ASR...',
            );
          } else {
            debugPrint('[SpeechService] Suppressed STT notice: $rawMsg');
          }

          if (errorNotification.permanent) {
            _sttInitialized = false;
          }
        },
        onStatus: (status) {
          debugPrint('[SpeechService] STT status: $status');
          if (status == 'done' || status == 'notListening') {
            // Handled
          }
        },
      );

      _sttInitialized = result;
      debugPrint('[SpeechService] initialize() returned: $result');

      if (!result) {
        onStatusUpdate?.call('On-device speech recognition unavailable.');
      }
    } catch (e) {
      debugPrint('[SpeechService] initialize() exception: $e');
      _sttInitialized = false;
      onStatusUpdate?.call('STT Init Exception: $e');
    }
    return _sttInitialized;
  }

  // ─────────────────────────────────────────────────────
  // Find Hindi Locale
  // ─────────────────────────────────────────────────────
  Future<String?> _findHindiLocale() async {
    if (_hindiLocaleId != null) return _hindiLocaleId;

    try {
      final locales = await _speech.locales();
      debugPrint(
        '[SpeechService] Discovered device locales count: ${locales.length}',
      );
      for (final l in locales) {
        debugPrint(
          '[SpeechService] Locale: id="${l.localeId}", name="${l.name}"',
        );
      }

      // Priority matching: hi_IN, hi-IN, hi
      for (final candidate in ['hi_IN', 'hi-IN', 'hi', 'hi_US']) {
        final match = locales.firstWhere(
          (l) => l.localeId.toLowerCase() == candidate.toLowerCase(),
          orElse: () => stt.LocaleName('', ''),
        );
        if (match.localeId.isNotEmpty) {
          debugPrint(
            '[SpeechService] Selected exact Hindi locale: ${match.localeId}',
          );
          _hindiLocaleId = match.localeId;
          return _hindiLocaleId;
        }
      }

      // Any locale starting with 'hi'
      final anyHindi = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith('hi'),
        orElse: () => stt.LocaleName('', ''),
      );
      if (anyHindi.localeId.isNotEmpty) {
        debugPrint(
          '[SpeechService] Selected fuzzy Hindi locale: ${anyHindi.localeId}',
        );
        _hindiLocaleId = anyHindi.localeId;
        return _hindiLocaleId;
      }
    } catch (e) {
      debugPrint('[SpeechService] Locale lookup error: $e');
    }

    _hindiLocaleId = 'hi_IN';
    return _hindiLocaleId;
  }

  // ─────────────────────────────────────────────────────
  // Start Listening — Live STT Streaming + Parallel WAV Recording
  // ─────────────────────────────────────────────────────
  Future<bool> startListening({
    required Function(String text) onResult,
    Function(String status)? onStatusUpdate,
    String? localeId,
  }) async {
    // 1. Permission Check
    final hasPerm = await requestMicPermission();
    if (!hasPerm) {
      onStatusUpdate?.call('Microphone permission denied.');
      return false;
    }

    // 2. Start WAV Audio Recorder with 100% EXCLUSIVE hardware microphone access
    try {
      final recPath = await _audioRecorder.startRecording();
      if (recPath != null) {
        _isWavRecording = true;
        debugPrint(
          '[SpeechService] EXCLUSIVE mic capture started for IndicConformer ASR: $recPath',
        );
      }
    } catch (e) {
      debugPrint('[SpeechService] WAV Recording start exception: $e');
    }

    onStatusUpdate?.call('Listening — speak Hindi...');
    return _isWavRecording;
  }

  // ─────────────────────────────────────────────────────
  // Stop Listening & Transcribe
  // ─────────────────────────────────────────────────────
  Future<String?> stopListeningAndTranscribe({
    String? currentRecognizedText,
    Function(String status)? onStatusUpdate,
  }) async {
    File? audioFile;
    if (_isWavRecording) {
      _isWavRecording = false;
      audioFile = await _audioRecorder.stopRecording();
      final len = (audioFile != null && await audioFile.exists())
          ? await audioFile.length()
          : 0;
      debugPrint(
        '[SpeechService] WAV recorder stopped. File: ${audioFile?.path} (size: $len bytes)',
      );
    }

    if (audioFile != null &&
        await audioFile.exists() &&
        await audioFile.length() > 0) {
      onStatusUpdate?.call('Transcribing audio with IndicConformer ASR...');
      try {
        final asrResult = await LocalAiBridge.transcribeAudio(
          audioFile,
        ).timeout(const Duration(seconds: 20));
        if (asrResult != null && asrResult.containsKey('text')) {
          final text = asrResult['text'].toString().trim();
          if (text.isNotEmpty) {
            debugPrint(
              '[SpeechService] IndicConformer ASR transcribed: "$text"',
            );
            return text;
          }
        }
      } catch (e) {
        debugPrint('[SpeechService] IndicConformer ASR error: $e');
      }
      onStatusUpdate?.call('Local ASR unavailable');
      return null;
    }

    onStatusUpdate?.call('Local ASR unavailable');
    return null;
  }

  Future<void> stopListening() async {
    _isWavRecording = false;
    try {
      if (_speech.isListening) await _speech.stop();
      await _audioRecorder.stopRecording();
    } catch (_) {}
  }

  Future<void> warmUp() async {
    final hasPerm = await requestMicPermission();
    if (!hasPerm) return;
    await _initSTT();
    if (_sttInitialized) await _findHindiLocale();
  }
}
