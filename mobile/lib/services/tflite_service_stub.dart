import 'dart:io';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';

class TFLiteService {
  static final TFLiteService instance = TFLiteService._();
  TFLiteService._();

  bool get isReady => false;

  Future<void> loadModel() async {
    throw UnsupportedError('TFLite không hỗ trợ trên nền tảng này.');
  }

  Future<ScanResultModel> predict(File imageFile) async {
    throw UnsupportedError('TFLite không hỗ trợ trên nền tảng này.');
  }

  void dispose() {}
}
