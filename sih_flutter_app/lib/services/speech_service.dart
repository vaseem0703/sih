import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'audio_recorder_service.dart';
import 'offline_asr_service.dart';
import 'on_device_asr_service.dart';

class SpeechService {
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  final OfflineAsrService _offlineAsr = OfflineAsrService();
  final OnDeviceAsrService _onDeviceAsr = OnDeviceAsrService();
  bool _isWavRecording = false;

  bool get isListening => _isWavRecording;
  bool get isOfflineAsrReady => _offlineAsr.isReady || _onDeviceAsr.isReady;

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
  // Start Listening — Exclusive Microphone Audio Capture
  // ─────────────────────────────────────────────────────
  Future<bool> startListening({
    required Function(String text) onResult,
    Function(String status)? onStatusUpdate,
    String? localeId,
  }) async {
    final hasPerm = await requestMicPermission();
    if (!hasPerm) {
      onStatusUpdate?.call('Microphone permission denied.');
      return false;
    }

    // Pre-initialize offline ASR engines in background
    _offlineAsr.initialize();

    try {
      final recPath = await _audioRecorder.startRecording();
      if (recPath != null) {
        _isWavRecording = true;
        debugPrint(
          '[SpeechService] EXCLUSIVE mic capture started for Hindi ASR: $recPath',
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
      onStatusUpdate?.call('Transcribing audio with Hindi ASR...');

      // 1. Try On-Device Sherpa-ONNX IndicConformer ASR (if installed and ready)
      if (_onDeviceAsr.isReady) {
        try {
          debugPrint('[SpeechService] Using On-Device IndicConformer Sherpa-ONNX ASR...');
          final onDeviceText = await _onDeviceAsr.transcribeWavFile(audioFile);
          if (onDeviceText != null && onDeviceText.isNotEmpty) {
            debugPrint(
              '[ASR DEBUG] ON-DEVICE SHERPA ASR RESULT = "$onDeviceText"',
            );
            return onDeviceText;
          }
        } catch (e, stackTrace) {
          debugPrint(
            '[SpeechService] On-Device IndicConformer ASR error: $e\n$stackTrace',
          );
        }
      }

      // 2. PRIMARY OFFLINE PATH: Bundled Whisper INT8 Sherpa-ONNX ASR (100% Offline)
      try {
        debugPrint('[SpeechService] Using Bundled Sherpa-ONNX Whisper INT8 ASR...');
        final localText = await _offlineAsr.transcribeWavFile(audioFile);
        if (localText != null && localText.trim().isNotEmpty) {
          debugPrint(
            '[ASR DEBUG] BUNDLED SHERPA WHISPER RESULT = "${localText.trim()}"',
          );
          return localText.trim();
        }
      } catch (e, stackTrace) {
        debugPrint(
          '[SpeechService] Bundled Sherpa Whisper ASR error: $e\n$stackTrace',
        );
      }

      if (_offlineAsr.initError != null && !_onDeviceAsr.isReady) {
        onStatusUpdate?.call('Offline Hindi speech model is not installed.');
      } else {
        onStatusUpdate?.call('Offline ASR unavailable');
      }
      return null;
    }

    onStatusUpdate?.call('Local ASR unavailable');
    return null;
  }

  Future<void> stopListening() async {
    _isWavRecording = false;
    try {
      await _audioRecorder.stopRecording();
    } catch (_) {}
  }

  Future<void> warmUp() async {
    await requestMicPermission();
    _offlineAsr.initialize();
  }
}
