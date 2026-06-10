import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crackvision/core/router/app_router.dart';
import 'package:crackvision/core/storage/app_settings_store.dart';
import 'package:crackvision/core/theme/app_theme.dart';
import 'package:crackvision/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await AppSettingsStore.box();
  runApp(const ProviderScope(child: CrackVisionApp()));
}

class CrackVisionApp extends ConsumerWidget {
  const CrackVisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDark = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'CrackVision',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
