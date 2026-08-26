import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> requestMicPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted || status.isLimited) return true;

      final result = await Permission.microphone.request();
      if (result.isGranted || result.isLimited) return true;

      // Allow STT engine to try initializing directly as it has native permission hook
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> initialize() async {
    if (_isInitialized && _speech.isAvailable) return true;

    try {
      await requestMicPermission();
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
      return _isInitialized;
    } catch (e) {
      // ignore: avoid_print
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
    try {
      final available = await initialize();
      if (!available) {
        // Try one more time to re-init
        final retry = await _speech.initialize();
        if (!retry) {
          onStatusUpdate?.call("Speech recognition ready (tap again to record)");
        }
      }

      onStatusUpdate?.call("Listening...");

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
      // ignore: avoid_print
      print('STT Listen error: $e');
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
        onStatusUpdate?.call("Listening to classroom speech...");
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
