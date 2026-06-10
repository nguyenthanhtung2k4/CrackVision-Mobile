import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Web dùng Hive (localStorage), Mobile dùng FlutterSecureStorage
class SecureStorage {
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _boxName = 'auth_tokens';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Web helpers ───────────────────────────────────────────────
  static Future<Box> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  // ── Public API ────────────────────────────────────────────────
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      final box = await _box();
      await box.put(_keyAccess, accessToken);
      await box.put(_keyRefresh, refreshToken);
    } else {
      await Future.wait([
        _secureStorage.write(key: _keyAccess, value: accessToken),
        _secureStorage.write(key: _keyRefresh, value: refreshToken),
      ]);
    }
  }

  static Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final box = await _box();
      return box.get(_keyAccess) as String?;
    }
    return _secureStorage.read(key: _keyAccess);
  }

  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final box = await _box();
      return box.get(_keyRefresh) as String?;
    }
    return _secureStorage.read(key: _keyRefresh);
  }

  static Future<void> clearTokens() async {
    if (kIsWeb) {
      final box = await _box();
      await box.delete(_keyAccess);
      await box.delete(_keyRefresh);
    } else {
      await Future.wait([
        _secureStorage.delete(key: _keyAccess),
        _secureStorage.delete(key: _keyRefresh),
      ]);
    }
  }
}
