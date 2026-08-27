import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  static final AudioRecorderService _instance =
      AudioRecorderService._internal();
  factory AudioRecorderService() => _instance;
  AudioRecorderService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> hasPermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<String?> startRecording() async {
    try {
      final hasPerm = await hasPermission();
      if (!hasPerm) return null;

      final tempDir = await getTemporaryDirectory();
      String filePath =
          '${tempDir.path}/live_teacher_input_${DateTime.now().millisecondsSinceEpoch}.wav';

      try {
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: filePath,
        );
      } catch (e) {
        debugPrint('[AudioRecorderService] WAV encoder fallback to AAC: $e');
        filePath =
            '${tempDir.path}/live_teacher_input_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: filePath,
        );
      }

      _isRecording = true;
      _currentRecordingPath = filePath;
      debugPrint('[FLUTTER ASR] RECORD START');
      debugPrint('[FLUTTER ASR] RECORDING PATH: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('[AudioRecorderService] AudioRecorder start error: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<File?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null) {
        final file = File(path);
        if (await file.exists() && await file.length() > 0) {
          final len = await file.length();
          final bytes = await file.readAsBytes();

          double rms = 0.0;
          int peak = 0;
          int minSample = 0;
          int maxSample = 0;

          if (bytes.length > 44) {
            final pcmData = bytes.sublist(44);
            double sumSq = 0.0;
            int count = pcmData.length ~/ 2;
            for (int i = 0; i < pcmData.length - 1; i += 2) {
              int sample = pcmData[i] | (pcmData[i + 1] << 8);
              if (sample > 32767) sample -= 65536;
              final absSample = sample.abs();
              if (absSample > peak) peak = absSample;
              if (sample < minSample) minSample = sample;
              if (sample > maxSample) maxSample = sample;
              sumSq += (sample.toDouble() * sample.toDouble());
            }
            if (count > 0) {
              rms = sumSq / count;
            }
          }

          debugPrint('[PHONE MIC TEST] RECORDING STOPPED');
          debugPrint('[PHONE MIC TEST] AUDIO PATH: $path');
          debugPrint('[PHONE MIC TEST] AUDIO SIZE: $len bytes');
          debugPrint(
            '[PHONE MIC TEST] AUDIO FORMAT: ${path.endsWith('.wav') ? 'WAV (PCM 16-bit)' : 'AAC (.m4a)'}',
          );
          debugPrint('[PHONE MIC TEST] SAMPLE RATE: 16000 Hz');
          debugPrint('[PHONE MIC TEST] CHANNELS: 1 (Mono)');
          debugPrint(
            '[PHONE MIC TEST] DURATION: ${(len / 32000).toStringAsFixed(2)} seconds',
          );
          debugPrint(
            '[PHONE MIC TEST] AUDIO RMS / SIGNAL ENERGY: ${rms.toStringAsFixed(2)} (peak=$peak, min=$minSample, max=$maxSample)',
          );

          return file;
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('AudioRecorder stop error: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<void> dispose() async {
    try {
      await _audioRecorder.dispose();
    } catch (_) {}
  }
}
