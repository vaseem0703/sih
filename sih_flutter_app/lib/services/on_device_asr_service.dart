import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

enum OnDeviceAsrStatus { notInstalled, downloading, ready, loadFailed }

class OnDeviceAsrService {
  static final OnDeviceAsrService _instance = OnDeviceAsrService._internal();
  factory OnDeviceAsrService() => _instance;
  OnDeviceAsrService._internal();

  OnDeviceAsrStatus _status = OnDeviceAsrStatus.notInstalled;
  sherpa_onnx.OfflineRecognizer? _recognizer;
  String? _modelPath;
  String? _tokensPath;
  double _downloadProgress = 0.0;
  String _statusMessage = 'Hindi offline speech model not installed.';

  OnDeviceAsrStatus get status => _status;
  double get downloadProgress => _downloadProgress;
  String get statusMessage => _statusMessage;
  bool get isReady => _status == OnDeviceAsrStatus.ready && _recognizer != null;

  static const String _modelDownloadUrl =
      'https://huggingface.co/parismitaglobalsolutions/indicconformer-sherpa-onnx/resolve/main/hi/model.int8.onnx';
  static const String _tokensDownloadUrl =
      'https://huggingface.co/parismitaglobalsolutions/indicconformer-sherpa-onnx/resolve/main/tokens.txt';

  Future<String> _getModelDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${docsDir.path}/models/sherpa_onnx/hi');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  Future<OnDeviceAsrStatus> checkModelStatus() async {
    try {
      final dirPath = await _getModelDir();
      final modelFile = File('$dirPath/model.int8.onnx');
      final tokensFile = File('$dirPath/tokens.txt');

      if (await modelFile.exists() &&
          await modelFile.length() > 10 * 1024 * 1024 &&
          await tokensFile.exists() &&
          await tokensFile.length() > 100) {
        _modelPath = modelFile.path;
        _tokensPath = tokensFile.path;
        _status = OnDeviceAsrStatus.ready;
        _statusMessage = 'Hindi Offline ASR Ready';
        debugPrint(
          '[OnDeviceAsrService] Model files verified ready: $_modelPath',
        );
        await _initRecognizer();
        return _status;
      }
    } catch (e) {
      debugPrint('[OnDeviceAsrService] Model check error: $e');
    }

    _status = OnDeviceAsrStatus.notInstalled;
    _statusMessage = 'Hindi offline speech model is not installed.';
    return _status;
  }

  Future<bool> downloadModel({
    Function(double progress, String status)? onProgress,
  }) async {
    if (_status == OnDeviceAsrStatus.downloading) return false;

    _status = OnDeviceAsrStatus.downloading;
    _downloadProgress = 0.0;
    _statusMessage = 'Downloading Hindi offline speech model...';
    onProgress?.call(0.0, _statusMessage);

    try {
      final dirPath = await _getModelDir();
      final modelFile = File('$dirPath/model.int8.onnx');
      final tokensFile = File('$dirPath/tokens.txt');

      // 1. Download tokens.txt
      debugPrint(
        '[OnDeviceAsrService] Downloading tokens.txt from $_tokensDownloadUrl...',
      );
      final tokensRes = await http.get(Uri.parse(_tokensDownloadUrl));
      if (tokensRes.statusCode == 200) {
        await tokensFile.writeAsBytes(tokensRes.bodyBytes);
        debugPrint(
          '[OnDeviceAsrService] tokens.txt downloaded successfully (${tokensRes.bodyBytes.length} bytes)',
        );
      } else {
        throw Exception(
          'Failed to download tokens.txt (HTTP ${tokensRes.statusCode})',
        );
      }

      // 2. Download model.int8.onnx with stream progress & redirect support
      debugPrint(
        '[OnDeviceAsrService] Downloading model.int8.onnx from $_modelDownloadUrl...',
      );
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_modelDownloadUrl));
      request.followRedirects = true;
      request.maxRedirects = 10;

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download model.int8.onnx (HTTP ${response.statusCode})',
        );
      }

      final totalBytes = response.contentLength ?? 150 * 1024 * 1024;
      int receivedBytes = 0;
      final sink = modelFile.openWrite();

      await for (final chunk in response.stream) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        _downloadProgress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
        final pct = (_downloadProgress * 100).toInt();
        _statusMessage = 'Downloading Hindi offline model: $pct%';
        onProgress?.call(_downloadProgress, _statusMessage);
      }

      await sink.close();
      debugPrint(
        '[OnDeviceAsrService] Model download completed: ${modelFile.path} ($receivedBytes bytes)',
      );

      _modelPath = modelFile.path;
      _tokensPath = tokensFile.path;
      _status = OnDeviceAsrStatus.ready;
      _statusMessage = 'Hindi Offline ASR Ready';
      onProgress?.call(1.0, _statusMessage);

      await _initRecognizer();
      return true;
    } catch (e) {
      debugPrint('[OnDeviceAsrService] Model download failed: $e');
      _status = OnDeviceAsrStatus.loadFailed;
      _statusMessage = 'Model download failed: $e';
      onProgress?.call(0.0, _statusMessage);
      return false;
    }
  }

  Future<bool> _initRecognizer() async {
    if (_recognizer != null) return true;
    if (_modelPath == null || _tokensPath == null) return false;

    try {
      debugPrint(
        '[OnDeviceAsrService] Initializing Sherpa-ONNX C++ bindings...',
      );
      sherpa_onnx.initBindings();

      final nemoConfig = sherpa_onnx.OfflineNemoEncDecCtcModelConfig(
        model: _modelPath!,
      );

      final modelConfig = sherpa_onnx.OfflineModelConfig(
        nemoCtc: nemoConfig,
        tokens: _tokensPath!,
        numThreads: 4,
        debug: kDebugMode,
      );

      final recognizerConfig = sherpa_onnx.OfflineRecognizerConfig(
        model: modelConfig,
      );

      _recognizer = sherpa_onnx.OfflineRecognizer(recognizerConfig);
      debugPrint(
        '[OnDeviceAsrService] Sherpa-ONNX OfflineRecognizer initialized successfully!',
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('[OnDeviceAsrService] Recognizer init error: $e\n$stackTrace');
      _status = OnDeviceAsrStatus.loadFailed;
      _statusMessage = 'Recognizer init error: $e';
      return false;
    }
  }

  Future<String?> transcribeWavFile(File audioFile) async {
    if (!isReady) {
      debugPrint('[OnDeviceAsrService] Recognizer not ready!');
      return null;
    }

    sherpa_onnx.OfflineStream? stream;
    try {
      final len = await audioFile.length();
      debugPrint(
        '[ON-DEVICE ASR] TRANSCRIBE START: ${audioFile.path} ($len bytes)',
      );

      final bytes = await audioFile.readAsBytes();
      if (bytes.length <= 44) return null;

      // Extract 16-bit PCM samples after 44-byte WAV header
      final pcmBytes = bytes.sublist(44);
      final sampleCount = pcmBytes.length ~/ 2;
      final samples = Float32List(sampleCount);

      for (int i = 0; i < sampleCount; i++) {
        int sample = pcmBytes[i * 2] | (pcmBytes[i * 2 + 1] << 8);
        if (sample > 32767) sample -= 65536;
        samples[i] = sample / 32768.0;
      }

      stream = _recognizer!.createStream();
      stream.acceptWaveform(samples: samples, sampleRate: 16000);
      _recognizer!.decode(stream);

      final result = _recognizer!.getResult(stream);
      final text = result.text.trim();
      debugPrint('[ON-DEVICE ASR] SHERPA-ONNX TRANSCRIBED: "$text"');
      return text.isNotEmpty ? text : null;
    } catch (e, stackTrace) {
      debugPrint('[ON-DEVICE ASR] Transcribe error: $e\n$stackTrace');
      return null;
    } finally {
      stream?.free();
    }
  }

  void dispose() {
    _recognizer?.free();
    _recognizer = null;
  }
}
