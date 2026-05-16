import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiEndpoints {
  // Web/Windows → localhost | Android Emulator → 10.0.2.2
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    return 'http://localhost:8000/api/v1'; // Windows, macOS, Linux
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Scan
  static const String scanUpload = '/scan/upload';

  // History
  static const String history = '/history';
  static String historyDetail(String id) => '/history/$id';
}
