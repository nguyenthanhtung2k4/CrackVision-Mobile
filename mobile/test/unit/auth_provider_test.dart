import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:crackvision/features/auth/data/auth_repository.dart';
import 'package:crackvision/features/auth/domain/user_model.dart';
import 'package:crackvision/features/auth/presentation/auth_provider.dart';

// Extend concrete class so mocktail can override methods
class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository mockRepo;
  late ProviderContainer container;

  const fakeUser = UserModel(
    id: 'u1',
    email: 'test@test.com',
    fullName: 'Test User',
    isActive: true,
  );

  setUp(() {
    mockRepo = _MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => AuthNotifier(mockRepo)),
      ],
    );
  });

  tearDown(() => container.dispose());

  AuthNotifier notifier() => container.read(authProvider.notifier);
  AuthState authState() => container.read(authProvider);

  // ── Initial state ─────────────────────────────────────────────

  test('initial state is AuthStatus.initial', () {
    expect(authState().status, AuthStatus.initial);
    expect(authState().user, isNull);
    expect(authState().error, isNull);
  });

  // ── login — success ───────────────────────────────────────────

  test('login success → authenticated with user', () async {
    when(() => mockRepo.login(any(), any()))
        .thenAnswer((_) async => fakeUser);

    await notifier().login('test@test.com', 'password123');

    expect(authState().status, AuthStatus.authenticated);
    expect(authState().user, fakeUser);
    expect(authState().error, isNull);
  });

  // ── login — wrong credentials (401) ──────────────────────────

  test('login 401 → error with Vietnamese message about password', () async {
    when(() => mockRepo.login(any(), any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    await notifier().login('bad@test.com', 'wrongpass');

    expect(authState().status, AuthStatus.error);
    expect(authState().error, contains('mật khẩu'));
  });

  // ── login — server error (500) ────────────────────────────────

  test('login 500 → server error message', () async {
    when(() => mockRepo.login(any(), any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    await notifier().login('a@b.com', 'pass');

    expect(authState().status, AuthStatus.error);
    expect(authState().error, contains('server'));
  });

  // ── login — connection timeout ────────────────────────────────

  test('login timeout → user-friendly message', () async {
    when(() => mockRepo.login(any(), any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    await notifier().login('a@b.com', 'pass');

    expect(authState().status, AuthStatus.error);
    expect(authState().error, isNotNull);
    expect(authState().error, isNot(contains('Exception')));
  });

  // ── register — success ────────────────────────────────────────

  test('register success → AuthStatus.registered', () async {
    when(() => mockRepo.register(any(), any(), any()))
        .thenAnswer((_) async {});

    await notifier().register('new@test.com', 'password123', 'New User');

    expect(authState().status, AuthStatus.registered);
    expect(authState().error, isNull);
  });

  // ── register — duplicate email (409) ─────────────────────────

  test('register 409 → error message mentions registration', () async {
    when(() => mockRepo.register(any(), any(), any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 409,
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    await notifier().register('dup@test.com', 'pass123', 'Dup');

    expect(authState().status, AuthStatus.error);
    expect(authState().error, contains('đăng ký'));
  });

  // ── logout ────────────────────────────────────────────────────

  test('logout → unauthenticated state, user cleared', () async {
    when(() => mockRepo.logout()).thenAnswer((_) async {});

    await notifier().logout();

    expect(authState().status, AuthStatus.unauthenticated);
    expect(authState().user, isNull);
  });

  // ── checkAuth — token valid ───────────────────────────────────

  test('checkAuth with valid token → authenticated', () async {
    when(() => mockRepo.getMe()).thenAnswer((_) async => fakeUser);

    await notifier().checkAuth();

    expect(authState().status, AuthStatus.authenticated);
    expect(authState().user, fakeUser);
  });

  // ── checkAuth — token expired ─────────────────────────────────

  test('checkAuth failure → unauthenticated', () async {
    when(() => mockRepo.getMe()).thenThrow(Exception('Token expired'));

    await notifier().checkAuth();

    expect(authState().status, AuthStatus.unauthenticated);
  });

  // ── AuthState immutability ────────────────────────────────────

  test('AuthState.copyWith preserves unchanged fields', () {
    const original = AuthState(
      status: AuthStatus.authenticated,
      user: fakeUser,
    );
    final next = original.copyWith(status: AuthStatus.loading);

    expect(next.status, AuthStatus.loading);
    expect(next.user, fakeUser);
    expect(next.error, isNull);
  });
}
