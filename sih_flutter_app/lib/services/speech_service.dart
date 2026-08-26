import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> requestMicPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) return true;

      final result = await Permission.microphone.request();
      if (result.isGranted) return true;

      if (result.isPermanentlyDenied) {
        await openAppSettings();
      }
      return result.isGranted;
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
          print('Speech Error: ${errorNotification.errorMsg}');
        },
        onStatus: (status) {
          print('Speech Status: $status');
        },
      );
      return _isInitialized;
    } catch (e) {
      print('STT Init Exception: $e');
      return false;
    }
  }

  bool get isListening => _speech.isListening;

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

    final available = await initialize();
    if (!available) {
      onStatusUpdate?.call("Speech recognizer initializing...");
    }

    onStatusUpdate?.call("Listening to speech...");

    try {
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
      return true;
    } catch (e) {
      // Retry with default locale
      try {
        await _speech.listen(
          onResult: (result) {
            if (result.recognizedWords.trim().isNotEmpty) {
              onResult(result.recognizedWords);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          cancelOnError: false,
          partialResults: true,
        );
        return true;
      } catch (err) {
        onStatusUpdate?.call("Voice input ready");
        return false;
      }
    }
  }

  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
  }
}
