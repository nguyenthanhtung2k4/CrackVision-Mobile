import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiEndpoints {
  // SECURITY: Đang dùng http:// cho môi trường dev (localhost).
  // Khi deploy production PHẢI đổi sang https:// và cấu hình qua
  // --dart-define=BASE_URL=https://api.yourdomain.com/api/v1
  //
  // Test trên Android thật (physical device):
  //   flutter run --dart-define=BASE_URL=http://192.168.99.4:8000/api/v1
  // Test trên Android Emulator: dùng 10.0.2.2 (tự động bên dưới)
  static String get baseUrl {
    const prodUrl = String.fromEnvironment('BASE_URL', defaultValue: '');
    if (prodUrl.isNotEmpty) return prodUrl;
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    // 10.0.2.2 chỉ hoạt động trên Android Emulator, không phải physical device.
    // Physical device cần IP LAN thật — truyền qua --dart-define=BASE_URL=...
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    return 'http://localhost:8000/api/v1';
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  static String get serverBase {
    const prodUrl = String.fromEnvironment('BASE_URL', defaultValue: '');
    if (prodUrl.isNotEmpty) return prodUrl.replaceAll('/api/v1', '');
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static String imageUrl(String imagePath) => '$serverBase/$imagePath';

  // Scan
  static const String scanUpload = '/scan/upload';

  // History
  static const String history = '/history';
  static String historyDetail(String id) => '/history/$id';
}
