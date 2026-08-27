import 'package:flutter_test/flutter_test.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

void main() {
  test('Verify sherpa_onnx configuration classes and exports', () {
    print('Testing sherpa_onnx API exports...');

    // Check OfflineNemoEncDecCtcModelConfig / OfflineModelConfig / OfflineRecognizerConfig
    final nemoConfig = sherpa_onnx.OfflineNemoEncDecCtcModelConfig(
      model: 'path/to/model.int8.onnx',
    );
    print('OfflineNemoEncDecCtcModelConfig model: ${nemoConfig.model}');

    final modelConfig = sherpa_onnx.OfflineModelConfig(
      nemoCtc: nemoConfig,
      tokens: 'path/to/tokens.txt',
      debug: true,
    );
    print('OfflineModelConfig nemoCtc model: ${modelConfig.nemoCtc.model}');

    final recognizerConfig = sherpa_onnx.OfflineRecognizerConfig(
      model: modelConfig,
    );
    print('OfflineRecognizerConfig debug: ${recognizerConfig.model.debug}');

    // Test getResult signature check
    final recognizer = sherpa_onnx.OfflineRecognizer(recognizerConfig);
    print('Recognizer created: $recognizer');
  });
}
