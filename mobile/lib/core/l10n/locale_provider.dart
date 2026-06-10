import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/core/storage/app_settings_store.dart';

class LocaleNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'vi';
  }

  Future<void> _load() async {
    final saved =
        await AppSettingsStore.read<String>(AppSettingsStore.keyLanguage);
    if (saved == 'vi' || saved == 'en') state = saved!;
  }

  Future<void> setLocale(String code) async {
    if (code != 'vi' && code != 'en') return;
    state = code;
    await AppSettingsStore.write(AppSettingsStore.keyLanguage, code);
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, String>(LocaleNotifier.new);
