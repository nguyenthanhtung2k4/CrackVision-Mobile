import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';

class TFLiteService {
  static const _modelPath = 'assets/models/crack_model.tflite';
  static const _inputSize = 224;
  static const _threshold = 0.5;

  Interpreter? _interpreter;
  bool get isReady => _interpreter != null;

  static final TFLiteService instance = TFLiteService._();
  TFLiteService._();

  Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      final opts = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(_modelPath, options: opts);
    } catch (e) {
      _interpreter = null;
      rethrow;
    }
  }

  Future<ScanResultModel> predict(File imageFile) async {
    if (_interpreter == null) await loadModel();
    if (_interpreter == null) throw Exception('TFLite model chưa sẵn sàng.');

    final sw = Stopwatch()..start();
    final input = await _preprocessImage(imageFile);
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
        .reshape(outputShape);

    _interpreter!.run(input, output);
    sw.stop();

    final probPositive = (output[0][0] as double);
    final hasCrack = probPositive >= _threshold;
    final confidence = hasCrack ? probPositive : 1.0 - probPositive;

    return ScanResultModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      predLabel: hasCrack ? 'CRACK' : 'NO_CRACK',
      meaning: hasCrack ? 'Có vết nứt' : 'Không có vết nứt',
      probPositive: probPositive,
      confidence: confidence,
      threshold: _threshold,
      inferenceTimeSeconds: sw.elapsedMilliseconds / 1000.0,
      imageFilename: imageFile.path.split('/').last,
      source: 'tflite',
      isSynced: false,
      createdAt: DateTime.now(),
    );
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(File file) async {
    final bytes = await file.readAsBytes();
    var image = img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) throw Exception('Không thể đọc ảnh.');
    image = img.copyResize(image, width: _inputSize, height: _inputSize);

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = image!.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    return input;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
