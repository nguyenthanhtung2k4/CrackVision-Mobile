import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crackvision/core/constants/api_endpoints.dart';
import 'package:crackvision/core/network/api_client.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';

class ScanRepository {
  final Dio _dio;

  ScanRepository(this._dio);

  Future<ScanResultModel> uploadAndScan(
    XFile imageFile, {
    bool saveResult = true,
  }) async {
    final fileSize = await imageFile.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw const ScanException('Ảnh quá lớn. Tối đa 10MB.');
    }

    final bytes = await imageFile.readAsBytes();
    final isJpeg = bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
    final isPng = bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    if (!isJpeg && !isPng) {
      throw const ScanException('File không phải ảnh JPEG hoặc PNG hợp lệ.');
    }

    final detectedExt = isJpeg ? 'jpg' : 'png';
    final rawName = imageFile.name;
    final hasExt = rawName.contains('.') && !rawName.startsWith('blob:');
    final filename = hasExt ? rawName : 'image.$detectedExt';

    debugPrint(
      '[ScanRepo] name=${imageFile.name} -> upload as $filename, '
      'bytes=${bytes.length}, isWeb=$kIsWeb, save=$saveResult',
    );

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    try {
      final res = await _dio.post(
        ApiEndpoints.scanUpload,
        data: formData,
        queryParameters: {'save': saveResult},
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return ScanResultModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint(
        '[ScanRepo] DioException type=${e.type} '
        'status=${e.response?.statusCode} msg=${e.message}',
      );
      final status = e.response?.statusCode;
      if (status == 400) {
        throw const ScanException('Ảnh không hợp lệ. Vui lòng chọn ảnh khác.');
      }
      if (status == 401) {
        throw const ScanException(
          'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
        );
      }
      if (status == 413) {
        throw const ScanException('Ảnh quá lớn. Tối đa 10MB.');
      }
      if (status == 503) {
        throw const ScanException(
          'AI model chưa sẵn sàng. Vui lòng thử lại sau.',
        );
      }
      if (status != null && status >= 500) {
        throw const ScanException('Lỗi server. Vui lòng thử lại.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const ScanException(
          'Không thể kết nối server. Kiểm tra backend đang chạy.',
        );
      }
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const ScanException('Kết nối quá chậm. Vui lòng thử lại.');
      }
      rethrow;
    }
  }
}

class ScanException implements Exception {
  final String message;
  const ScanException(this.message);

  @override
  String toString() => message;
}

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepository(ref.watch(dioProvider));
});
