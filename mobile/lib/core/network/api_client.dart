import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crackvision/core/constants/api_endpoints.dart';
import 'package:crackvision/core/storage/secure_storage.dart';

// Fires when token refresh fails → AuthNotifier listens and forces logout
final _logoutController = StreamController<void>.broadcast();
Stream<void> get onForceLogout => _logoutController.stream;

final dioProvider = Provider<Dio>((ref) => buildDio());

Dio buildDio() {
  final dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(_AuthInterceptor(dio));
  return dio;
}

class _PendingRequest {
  final RequestOptions options;
  final Completer<Response<dynamic>> completer;
  _PendingRequest(this.options, this.completer);
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;

  // Separate Dio without auth interceptor — used only for token refresh
  // to avoid infinite interceptor loops if refresh itself returns 401
  final Dio _refreshDio;

  bool _isRefreshing = false;
  final List<_PendingRequest> _queue = [];

  _AuthInterceptor(this._dio)
      : _refreshDio = Dio(BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ));

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Another refresh is already in progress — queue this request
    if (_isRefreshing) {
      final completer = Completer<Response<dynamic>>();
      _queue.add(_PendingRequest(err.requestOptions, completer));
      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (_) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) {
        await _forceLogout(handler, err);
        return;
      }

      final resp = await _refreshDio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );
      final newAccess = resp.data['access_token'] as String;
      final newRefresh = resp.data['refresh_token'] as String;
      await SecureStorage.saveTokens(
          accessToken: newAccess, refreshToken: newRefresh);

      // Retry the original failed request with new token
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retried = await _dio.fetch(err.requestOptions);

      // Retry all queued requests that were waiting for the refresh
      for (final pending in _queue) {
        pending.options.headers['Authorization'] = 'Bearer $newAccess';
        try {
          final r = await _dio.fetch(pending.options);
          pending.completer.complete(r);
        } catch (e) {
          pending.completer.completeError(e);
        }
      }
      _queue.clear();

      return handler.resolve(retried);
    } catch (_) {
      await _forceLogout(handler, err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _forceLogout(
      ErrorInterceptorHandler handler, DioException err) async {
    await SecureStorage.clearTokens();
    for (final p in _queue) {
      p.completer.completeError(err);
    }
    _queue.clear();
    _logoutController.add(null); // signal AuthNotifier to update state
    handler.next(err);
  }
}
