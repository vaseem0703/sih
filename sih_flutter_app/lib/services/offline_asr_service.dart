import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

class OfflineAsrService {
  static final OfflineAsrService _instance = OfflineAsrService._internal();
  factory OfflineAsrService() => _instance;
  OfflineAsrService._internal();

  sherpa_onnx.OfflineRecognizer? _recognizer;
  bool _isInitializing = false;
  bool _isInitialized = false;
  String? _initError;

  bool get isReady => _recognizer != null;
  String? get initError => _initError;

  static const String _modelAssetDir = 'assets/models/sherpa-onnx-whisper-tiny';
  static const String _encoderFileName = 'tiny-encoder.int8.onnx';
  static const String _decoderFileName = 'tiny-decoder.int8.onnx';
  static const String _tokensFileName = 'tiny-tokens.txt';

  /// Initializes the on-device Sherpa-ONNX runtime and extracts model files
  Future<bool> initialize() async {
    if (_isInitialized && _recognizer != null) return true;
    if (_isInitializing) return false;

    _isInitializing = true;
    _initError = null;

    try {
      // 1. Initialize native C++ dynamic bindings
      try {
        await sherpa_onnx.initBindingsAsync();
      } catch (e) {
        // Fallback to sync binding init on supported platforms
        try {
          sherpa_onnx.initBindings();
        } catch (_) {}
      }

      // 2. Prepare target model directory in app document directory
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${appDir.path}/sherpa-onnx-whisper-tiny');
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      final encoderFile = File('${modelDir.path}/$_encoderFileName');
      final decoderFile = File('${modelDir.path}/$_decoderFileName');
      final tokensFile = File('${modelDir.path}/$_tokensFileName');

      // 3. Extract asset files to filesystem if needed
      await _copyAssetToFile('$_modelAssetDir/$_encoderFileName', encoderFile);
      await _copyAssetToFile('$_modelAssetDir/$_decoderFileName', decoderFile);
      await _copyAssetToFile('$_modelAssetDir/$_tokensFileName', tokensFile);

      if (!await encoderFile.exists() ||
          !await decoderFile.exists() ||
          !await tokensFile.exists()) {
        _initError = 'Offline Hindi speech model files are missing.';
        _isInitializing = false;
        return false;
      }

      // 4. Configure Whisper offline recognizer for Hindi transcription
      final whisperConfig = sherpa_onnx.OfflineWhisperModelConfig(
        encoder: encoderFile.path,
        decoder: decoderFile.path,
        language: 'hi',
        task: 'transcribe',
        tailPaddings: 400,
      );

      final modelConfig = sherpa_onnx.OfflineModelConfig(
        whisper: whisperConfig,
        tokens: tokensFile.path,
        modelType: 'whisper',
        numThreads: 2,
        debug: false,
        provider: 'cpu',
      );

      final recognizerConfig = sherpa_onnx.OfflineRecognizerConfig(
        model: modelConfig,
        decodingMethod: 'greedy_search',
        maxActivePaths: 4,
      );

      _recognizer = sherpa_onnx.OfflineRecognizer(recognizerConfig);
      _isInitialized = true;
      _isInitializing = false;
      return true;
    } catch (e) {
      _initError = 'Failed to initialize offline ASR: $e';
      _isInitialized = false;
      _isInitializing = false;
      return false;
    }
  }

  Future<void> _copyAssetToFile(String assetPath, File targetFile) async {
    try {
      if (await targetFile.exists()) {
        final length = await targetFile.length();
        if (length > 0) return; // Already extracted
      }

      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await targetFile.writeAsBytes(bytes, flush: true);
    } catch (e) {
      // ignore: avoid_print
      print('Error copying asset $assetPath: $e');
    }
  }

  /// Transcribes a recorded 16 kHz mono WAV audio file locally on the device
  Future<String?> transcribeWavFile(File audioFile) async {
    if (!await audioFile.exists()) return null;
    if (_recognizer == null) {
      final ok = await initialize();
      if (!ok || _recognizer == null) return null;
    }

    try {
      final stopwatch = Stopwatch()..start();
      final wave = sherpa_onnx.readWave(audioFile.path);
      if (wave.samples.isEmpty || wave.sampleRate == 0) {
        return null;
      }

      final stream = _recognizer!.createStream();
      stream.acceptWaveform(samples: wave.samples, sampleRate: wave.sampleRate);
      _recognizer!.decode(stream);
      final result = _recognizer!.getResult(stream);
      stream.free();
      stopwatch.stop();

      String text = result.text.trim();
      // Clean leading Whisper artifact tokens/brackets if present
      text = text
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .replaceAll(RegExp(r'^[ \-\.]+'), '')
          .trim();

      // ignore: avoid_print
      print('[Sherpa-ONNX ASR] Decoded ${wave.samples.length} samples in ${stopwatch.elapsedMilliseconds}ms -> "$text"');
      return text.isNotEmpty ? text : null;
    } catch (e) {
      // ignore: avoid_print
      print('Offline ASR decoding error: $e');
      return null;
    }
  }

  void dispose() {
    try {
      _recognizer?.free();
      _recognizer = null;
      _isInitialized = false;
    } catch (_) {}
  }
}
