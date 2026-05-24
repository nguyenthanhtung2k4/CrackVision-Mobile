import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';

class TFLiteService {
  static const _modelPath = 'assets/models/crack_model.tflite';
  static const _inputSize = 224;
  static const _threshold = 0.5;
  static const _visionMaxSide = 640;
  static const _visionLineThresholds = [6, 8, 10, 12];

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
    final preprocessed = await _preprocessImage(imageFile);
    final input = preprocessed.input;
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
        .reshape(outputShape);

    _interpreter!.run(input, output);
    sw.stop();

    final modelProbPositive = (output[0][0] as double);
    final probPositive = math.max(modelProbPositive, preprocessed.visionScore);
    final hasCrack = probPositive >= _threshold;
    final confidence = hasCrack ? probPositive : 1.0 - probPositive;
    final source = preprocessed.visionScore > modelProbPositive && hasCrack
        ? 'tflite+vision'
        : 'tflite';

    return ScanResultModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      predLabel: hasCrack ? 'CRACK' : 'NO_CRACK',
      meaning: hasCrack ? 'Có vết nứt' : 'Không có vết nứt',
      probPositive: probPositive,
      confidence: confidence,
      threshold: _threshold,
      inferenceTimeSeconds: sw.elapsedMilliseconds / 1000.0,
      imageFilename: imageFile.path.split('/').last,
      source: source,
      isSynced: false,
      createdAt: DateTime.now(),
    );
  }

  Future<_PreprocessedImage> _preprocessImage(File file) async {
    final bytes = await file.readAsBytes();
    var image = img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) throw Exception('Không thể đọc ảnh.');
    final visionScore = _crackLineScore(image);
    image = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.nearest,
    );

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = image!.getPixel(x, y);
            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    );
    return _PreprocessedImage(input: input, visionScore: visionScore);
  }

  double _crackLineScore(img.Image source) {
    var image = source;
    final maxSide = math.max(image.width, image.height);
    if (maxSide > _visionMaxSide) {
      final scale = _visionMaxSide / maxSide;
      image = img.copyResize(
        image,
        width: math.max(1, (image.width * scale).round()),
        height: math.max(1, (image.height * scale).round()),
        interpolation: img.Interpolation.linear,
      );
    }

    final width = image.width;
    final height = image.height;
    final gray = List<int>.filled(width * height, 0);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        gray[y * width + x] =
            (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b)
                .round()
                .clamp(0, 255)
                .toInt();
      }
    }

    final radius = math.max(3, (math.min(width, height) * 0.02).round());
    final background = _boxBlurGray(gray, width, height, radius);

    var best = 0.0;
    for (final threshold in _visionLineThresholds) {
      final mask = Uint8List(width * height);
      for (var i = 0; i < mask.length; i++) {
        if (background[i] - gray[i] > threshold) {
          mask[i] = 1;
        }
      }
      best = math.max(best, _scoreDarkLineMask(mask, width, height));
    }
    return best;
  }

  List<int> _boxBlurGray(List<int> gray, int width, int height, int radius) {
    final integralWidth = width + 1;
    final integral = List<int>.filled((width + 1) * (height + 1), 0);

    for (var y = 0; y < height; y++) {
      var rowSum = 0;
      for (var x = 0; x < width; x++) {
        rowSum += gray[y * width + x];
        integral[(y + 1) * integralWidth + x + 1] =
            integral[y * integralWidth + x + 1] + rowSum;
      }
    }

    final blurred = List<int>.filled(width * height, 0);
    for (var y = 0; y < height; y++) {
      final y1 = math.max(0, y - radius);
      final y2 = math.min(height - 1, y + radius);
      for (var x = 0; x < width; x++) {
        final x1 = math.max(0, x - radius);
        final x2 = math.min(width - 1, x + radius);
        final area = (x2 - x1 + 1) * (y2 - y1 + 1);
        final sum = integral[(y2 + 1) * integralWidth + x2 + 1] -
            integral[y1 * integralWidth + x2 + 1] -
            integral[(y2 + 1) * integralWidth + x1] +
            integral[y1 * integralWidth + x1];
        blurred[y * width + x] = (sum / area).round();
      }
    }
    return blurred;
  }

  double _scoreDarkLineMask(Uint8List mask, int width, int height) {
    final seen = Uint8List(mask.length);
    var best = 0.0;

    for (var start = 0; start < mask.length; start++) {
      if (mask[start] == 0 || seen[start] != 0) continue;

      final stack = <int>[start];
      seen[start] = 1;
      var count = 0;
      var minX = width;
      var maxX = 0;
      var minY = height;
      var maxY = 0;

      while (stack.isNotEmpty) {
        final index = stack.removeLast();
        final y = index ~/ width;
        final x = index - y * width;
        count++;
        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);

        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final ny = y + dy;
            final nx = x + dx;
            if (ny < 0 || ny >= height || nx < 0 || nx >= width) continue;
            final next = ny * width + nx;
            if (mask[next] != 0 && seen[next] == 0) {
              seen[next] = 1;
              stack.add(next);
            }
          }
        }
      }

      final componentHeight = maxY - minY + 1;
      final componentWidth = maxX - minX + 1;
      final slenderness = componentHeight / math.max(componentWidth, 1);
      final isCrackLike = componentHeight >= math.min(width, height) * 0.22 &&
          componentWidth <= math.max(14, width * 0.08) &&
          slenderness >= 5.0 &&
          count >= 30;
      if (!isCrackLike) continue;

      final lengthScore = math.min(1.0, componentHeight / (height * 0.55));
      final slenderScore =
          math.min(1.0, math.max(0.0, (slenderness - 5.0) / 6.0));
      final areaScore = math.min(1.0, count / (height * width * 0.002));
      final quality = lengthScore * slenderScore * areaScore;
      best = math.max(best, 0.65 + 0.35 * quality);
    }

    return best;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

class _PreprocessedImage {
  final List<List<List<List<double>>>> input;
  final double visionScore;

  const _PreprocessedImage({
    required this.input,
    required this.visionScore,
  });
}
