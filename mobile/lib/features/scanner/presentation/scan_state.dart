import 'dart:io';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';

enum ScanStatus { idle, loading, success, error }

class ScanState {
  final ScanStatus status;
  final File? selectedImage;
  final ScanResultModel? result;
  final String? error;

  const ScanState({
    this.status = ScanStatus.idle,
    this.selectedImage,
    this.result,
    this.error,
  });

  ScanState copyWith({
    ScanStatus? status,
    File? selectedImage,
    ScanResultModel? result,
    String? error,
  }) =>
      ScanState(
        status: status ?? this.status,
        selectedImage: selectedImage ?? this.selectedImage,
        result: result ?? this.result,
        error: error,
      );

  ScanState withImage(File image) =>
      ScanState(status: ScanStatus.idle, selectedImage: image);

  ScanState reset() => const ScanState();
}
