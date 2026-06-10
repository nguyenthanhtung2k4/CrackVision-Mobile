import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/core/network/api_client.dart';
import 'package:crackvision/features/auth/data/auth_repository.dart';
import 'package:crackvision/features/auth/domain/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, registered, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({this.status = AuthStatus.initial, this.user, this.error});

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
    onForceLogout.listen((_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    });
  }

  Future<void> _init() => checkAuth();

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await _repo.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _parseError(e, isLogin: true));
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await _repo.register(email, password, fullName);
      // Đăng ký xong → về màn login, KHÔNG tự đăng nhập
      state = const AuthState(status: AuthStatus.registered);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _parseError(e, isLogin: false));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repo.getMe();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  String _parseError(Object e, {required bool isLogin}) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 401) {
        return isLogin
            ? 'Email hoặc mật khẩu không đúng.'
            : 'Xác thực thất bại.';
      }
      if (status == 400) {
        return isLogin
            ? 'Email hoặc mật khẩu không đúng.'
            : 'Thông tin đăng ký không hợp lệ.';
      }
      if (status == 409) return 'Email này đã được đăng ký. Vui lòng đăng nhập.';
      if (status == 404) return 'Tài khoản không tồn tại.';
      if (status != null && status >= 500) return 'Lỗi server. Vui lòng thử lại sau.';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Kết nối quá chậm. Vui lòng thử lại.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối server. Kiểm tra mạng.';
      }
    }
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
