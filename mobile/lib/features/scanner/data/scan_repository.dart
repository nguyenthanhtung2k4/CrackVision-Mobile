import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/core/network/api_client.dart';
import 'package:crackvision/core/constants/api_endpoints.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';

class ScanRepository {
  final Dio _dio;

  ScanRepository(this._dio);

  Future<ScanResultModel> uploadAndScan(File imageFile) async {
    final fileSize = await imageFile.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw const ScanException('Ảnh quá lớn. Tối đa 10MB.');
    }

    final ext = imageFile.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(ext)) {
      throw const ScanException('Chỉ hỗ trợ ảnh JPEG và PNG.');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    });

    try {
      final res = await _dio.post(
        ApiEndpoints.scanUpload,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return ScanResultModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400) throw const ScanException('Ảnh không hợp lệ. Vui lòng chọn ảnh khác.');
      if (status == 401) throw const ScanException('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      if (status == 413) throw const ScanException('Ảnh quá lớn. Tối đa 10MB.');
      if (status == 503) throw const ScanException('AI model chưa sẵn sàng. Vui lòng thử lại sau.');
      if (status != null && status >= 500) throw const ScanException('Lỗi server. Vui lòng thử lại.');
      if (e.type == DioExceptionType.connectionError) {
        throw const ScanException('Không có kết nối mạng.');
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
