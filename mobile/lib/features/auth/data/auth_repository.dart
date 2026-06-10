import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/core/network/api_client.dart';
import 'package:crackvision/core/storage/secure_storage.dart';
import 'package:crackvision/core/constants/api_endpoints.dart';
import 'package:crackvision/features/auth/domain/user_model.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<UserModel> login(String email, String password) async {
    final res = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = res.data as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;
    await SecureStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    // Truyền token thẳng vào header để tránh race condition với storage async
    return _getMeWithToken(accessToken);
  }

  Future<void> register(String email, String password, String fullName) async {
    await _dio.post(
      ApiEndpoints.register,
      data: {'email': email, 'password': password, 'full_name': fullName},
    );
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> _getMeWithToken(String token) async {
    final res = await _dio.get(
      ApiEndpoints.me,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post(ApiEndpoints.logout, data: {'refresh_token': refreshToken});
      }
    } catch (_) {
      // always clear local tokens
    } finally {
      await SecureStorage.clearTokens();
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
