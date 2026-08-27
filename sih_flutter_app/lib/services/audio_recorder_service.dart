import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  static final AudioRecorderService _instance = AudioRecorderService._internal();
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
      String filePath = '${tempDir.path}/live_teacher_input_${DateTime.now().millisecondsSinceEpoch}.wav';

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
        filePath = '${tempDir.path}/live_teacher_input_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
          // ignore: avoid_print
          print('Recorded valid audio file: $path (${await file.length()} bytes)');
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
