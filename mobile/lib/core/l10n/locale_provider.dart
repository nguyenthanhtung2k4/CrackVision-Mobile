import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends Notifier<String> {
  @override
  String build() => 'vi';

  void setLocale(String code) => state = code;
}

final localeProvider = NotifierProvider<LocaleNotifier, String>(LocaleNotifier.new);
