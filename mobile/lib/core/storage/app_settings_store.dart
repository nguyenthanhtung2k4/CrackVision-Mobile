import 'package:hive_flutter/hive_flutter.dart';

class AppSettingsStore {
  AppSettingsStore._();

  static const boxName = 'app_settings';

  static const keyHighAccuracy = 'high_accuracy';
  static const keyAutoSave = 'auto_save';
  static const keyOfflineMode = 'offline_mode';
  static const keyNotifications = 'notifications_enabled';
  static const keyDarkMode = 'dark_mode';
  static const keyLanguage = 'language';

  static Future<Box> box() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return Hive.openBox(boxName);
  }

  static Future<T?> read<T>(String key) async {
    final b = await box();
    return b.get(key) as T?;
  }

  static Future<void> write<T>(String key, T value) async {
    final b = await box();
    await b.put(key, value);
  }
}
