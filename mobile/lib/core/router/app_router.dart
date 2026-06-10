import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crackvision/features/auth/presentation/auth_provider.dart';
import 'package:crackvision/features/auth/presentation/login_screen.dart';
import 'package:crackvision/features/auth/presentation/register_screen.dart';
import 'package:crackvision/features/home/presentation/home_screen.dart';
import 'package:crackvision/features/scanner/presentation/scanner_screen.dart';
import 'package:crackvision/features/result/presentation/result_screen.dart';
import 'package:crackvision/features/history/presentation/history_screen.dart';
import 'package:crackvision/features/history/presentation/history_detail_screen.dart';
import 'package:crackvision/features/settings/presentation/settings_screen.dart';
import 'package:crackvision/features/scanner/domain/scan_result_model.dart';
import 'package:crackvision/core/theme/app_theme.dart';
import 'package:crackvision/shared/widgets/main_shell.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/';
  static const scanner = '/scanner';
  static const result = '/result';
  static const history = '/history';
  static const historyDetail = '/history/:id';
  static const settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _AuthNotifierListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.register;

      if (status == AuthStatus.initial || status == AuthStatus.loading) return null;

      final isAuth = status == AuthStatus.authenticated;
      if (!isAuth && !isAuthRoute) return AppRoutes.login;
      if (isAuth && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.scanner,
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.result,
        builder: (context, state) {
          final result = state.extra as ScanResultModel?;
          if (result == null) return const _ErrorScreen(message: 'Không có kết quả scan.');
          return ResultScreen(result: result);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.historyDetail,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return HistoryDetailScreen(id: id);
            },
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        _ErrorScreen(message: 'Không tìm thấy trang: ${state.uri}'),
  );
});

class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(message, style: const TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}
