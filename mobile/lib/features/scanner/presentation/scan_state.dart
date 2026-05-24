import 'package:image_picker/image_picker.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';

export 'package:image_picker/image_picker.dart' show XFile;

enum ScanStatus { idle, loading, success, error }

class ScanState {
  final ScanStatus status;
  final XFile? selectedImage;
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
    XFile? selectedImage,
    ScanResultModel? result,
    String? error,
  }) =>
      ScanState(
        status: status ?? this.status,
        selectedImage: selectedImage ?? this.selectedImage,
        result: result ?? this.result,
        error: error,
      );

  ScanState withImage(XFile image) =>
      ScanState(status: ScanStatus.idle, selectedImage: image);

  ScanState reset() => const ScanState();
}
