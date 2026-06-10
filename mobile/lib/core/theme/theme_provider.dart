import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/core/storage/app_settings_store.dart';

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false; // false = light, true = dark
  }

  Future<void> _load() async {
    final saved =
        await AppSettingsStore.read<bool>(AppSettingsStore.keyDarkMode);
    if (saved != null) state = saved;
  }

  void toggle() => set(!state);

  Future<void> set(bool dark) async {
    state = dark;
    await AppSettingsStore.write(AppSettingsStore.keyDarkMode, dark);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, bool>(ThemeNotifier.new);
