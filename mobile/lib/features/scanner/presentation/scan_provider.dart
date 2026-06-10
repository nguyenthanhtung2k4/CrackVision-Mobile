import 'dart:io' show File;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/features/scanner/data/scan_repository.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';
import 'package:crackvision/features/scanner/presentation/scan_state.dart';
import 'package:crackvision/features/settings/presentation/settings_provider.dart';
import 'package:crackvision/services/tflite_service.dart';

export 'package:crackvision/features/scanner/presentation/scan_state.dart';

class ScanNotifier extends StateNotifier<ScanState> {
  final ScanRepository _repo;
  final Ref _ref;

  ScanNotifier(this._repo, this._ref) : super(const ScanState());

  void selectImage(XFile image) => state = state.withImage(image);
  void reset() => state = state.reset();

  Future<void> analyze() async {
    final xFile = state.selectedImage;
    if (xFile == null) return;

    state = state.copyWith(status: ScanStatus.loading, error: null);

    final settings = _ref.read(appSettingsProvider);
    final hasNet = kIsWeb ? true : await _hasInternet();
    final canUseOnDevice = settings.offlineMode && !kIsWeb;
    final preferServer = settings.highAccuracy || !canUseOnDevice;

    try {
      ScanResultModel result;
      if (hasNet && preferServer) {
        result = await _repo.uploadAndScan(
          xFile,
          saveResult: settings.autoSave,
        );
      } else if (canUseOnDevice) {
        result = await _predictOnDevice(xFile);
      } else if (hasNet) {
        result = await _repo.uploadAndScan(
          xFile,
          saveResult: settings.autoSave,
        );
      } else {
        state = state.copyWith(
          status: ScanStatus.error,
          error: settings.offlineMode
              ? 'Không có kết nối mạng. Vui lòng kiểm tra lại.'
              : 'Chế độ offline đang tắt. Vui lòng bật lại hoặc kết nối mạng.',
        );
        return;
      }
      state = state.copyWith(status: ScanStatus.success, result: result);
    } on ScanException catch (e) {
      if (hasNet && canUseOnDevice) {
        try {
          final result = await _predictOnDevice(xFile);
          state = state.copyWith(status: ScanStatus.success, result: result);
          return;
        } catch (_) {}
      }
      state = state.copyWith(status: ScanStatus.error, error: e.message);
    } catch (_) {
      if (canUseOnDevice) {
        try {
          final result = await _predictOnDevice(xFile);
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

  Future<ScanResultModel> _predictOnDevice(XFile xFile) {
    return TFLiteService.instance.predict(File(xFile.path));
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
  return ScanNotifier(ref.watch(scanRepositoryProvider), ref);
});
