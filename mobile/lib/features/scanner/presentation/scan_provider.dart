import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/features/scanner/data/scan_repository.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';
import 'package:crackvision/features/scanner/presentation/scan_state.dart';
import 'package:crackvision/services/tflite_service.dart';

export 'package:crackvision/features/scanner/presentation/scan_state.dart';

class ScanNotifier extends StateNotifier<ScanState> {
  final ScanRepository _repo;

  ScanNotifier(this._repo) : super(const ScanState());

  void selectImage(File image) => state = state.withImage(image);
  void reset() => state = state.reset();

  Future<void> analyze() async {
    final image = state.selectedImage;
    if (image == null) return;

    state = state.copyWith(status: ScanStatus.loading, error: null);

    final hasNet = await _hasInternet();

    try {
      ScanResultModel result;
      if (hasNet) {
        result = await _repo.uploadAndScan(image);
      } else if (!kIsWeb) {
        result = await TFLiteService.instance.predict(image);
      } else {
        state = state.copyWith(
          status: ScanStatus.error,
          error: 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
        );
        return;
      }
      state = state.copyWith(status: ScanStatus.success, result: result);
    } on ScanException catch (e) {
      if (hasNet && !kIsWeb) {
        try {
          final result = await TFLiteService.instance.predict(image);
          state = state.copyWith(status: ScanStatus.success, result: result);
          return;
        } catch (_) {}
      }
      state = state.copyWith(status: ScanStatus.error, error: e.message);
    } catch (e) {
      if (!kIsWeb) {
        try {
          final result = await TFLiteService.instance.predict(image);
          state = state.copyWith(status: ScanStatus.success, result: result);
          return;
        } catch (_) {}
      }
      state = state.copyWith(
        status: ScanStatus.error,
        error: 'Đã có lỗi xảy ra. Vui lòng thử lại.',
      );
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
    } catch (_) {
      return false;
    }
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(ref.watch(scanRepositoryProvider));
});
