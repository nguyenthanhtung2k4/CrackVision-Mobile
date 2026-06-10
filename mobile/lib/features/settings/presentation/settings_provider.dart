import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/core/storage/app_settings_store.dart';

class AppSettings {
  final bool highAccuracy;
  final bool autoSave;
  final bool offlineMode;
  final bool notifications;

  const AppSettings({
    this.highAccuracy = true,
    this.autoSave = true,
    this.offlineMode = true,
    this.notifications = true,
  });

  AppSettings copyWith({
    bool? highAccuracy,
    bool? autoSave,
    bool? offlineMode,
    bool? notifications,
  }) {
    return AppSettings(
      highAccuracy: highAccuracy ?? this.highAccuracy,
      autoSave: autoSave ?? this.autoSave,
      offlineMode: offlineMode ?? this.offlineMode,
      notifications: notifications ?? this.notifications,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final highAccuracy =
        await AppSettingsStore.read<bool>(AppSettingsStore.keyHighAccuracy);
    final autoSave =
        await AppSettingsStore.read<bool>(AppSettingsStore.keyAutoSave);
    final offlineMode =
        await AppSettingsStore.read<bool>(AppSettingsStore.keyOfflineMode);
    final notifications =
        await AppSettingsStore.read<bool>(AppSettingsStore.keyNotifications);

    state = AppSettings(
      highAccuracy: highAccuracy ?? true,
      autoSave: autoSave ?? true,
      offlineMode: offlineMode ?? true,
      notifications: notifications ?? true,
    );
  }

  Future<void> setHighAccuracy(bool value) async {
    state = state.copyWith(highAccuracy: value);
    await AppSettingsStore.write(AppSettingsStore.keyHighAccuracy, value);
  }

  Future<void> setAutoSave(bool value) async {
    state = state.copyWith(autoSave: value);
    await AppSettingsStore.write(AppSettingsStore.keyAutoSave, value);
  }

  Future<void> setOfflineMode(bool value) async {
    state = state.copyWith(offlineMode: value);
    await AppSettingsStore.write(AppSettingsStore.keyOfflineMode, value);
  }

  Future<void> setNotifications(bool value) async {
    state = state.copyWith(notifications: value);
    await AppSettingsStore.write(AppSettingsStore.keyNotifications, value);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});
