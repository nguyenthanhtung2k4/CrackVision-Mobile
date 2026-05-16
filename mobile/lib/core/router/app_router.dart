import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crackvision/features/auth/presentation/auth_provider.dart';
import 'package:crackvision/features/auth/presentation/login_screen.dart';
import 'package:crackvision/features/auth/presentation/register_screen.dart';

// Screens — sẽ tạo ở Ngày 4 & 5
// import 'package:crackvision/features/home/presentation/home_screen.dart';

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
      final isLoginRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // Đang check auth lần đầu → không redirect
      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return null;
      }

      final isAuth = status == AuthStatus.authenticated;

      if (!isAuth && !isLoginRoute) return AppRoutes.login;
      if (isAuth && isLoginRoute) return AppRoutes.home;
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
        path: AppRoutes.home,
        builder: (context, state) => const _HomePlaceholder(),
      ),
      GoRoute(
        path: AppRoutes.scanner,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Scanner — Ngày 4'))),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('History — Ngày 5'))),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Settings — Ngày 5'))),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Không tìm thấy trang: ${state.uri}')),
    ),
  );
});

// Cho go_router biết khi authProvider thay đổi → re-evaluate redirect
class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

// Placeholder Home — sẽ thay bằng HomeScreen ở Ngày 5
class _HomePlaceholder extends ConsumerWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('CrackVision'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Xin chào, ${user?.fullName ?? ''}!\nHome Screen sẽ làm ở Ngày 5.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
