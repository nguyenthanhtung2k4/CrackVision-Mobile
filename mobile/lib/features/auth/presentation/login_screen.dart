import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crackvision/core/router/app_router.dart';
import 'package:crackvision/core/theme/app_theme.dart';
import 'package:crackvision/shared/widgets/app_button.dart';
import 'package:crackvision/shared/widgets/app_text_field.dart';
import 'package:crackvision/features/auth/presentation/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  static const _maxAttempts = 5;
  static const _lockoutSeconds = 30;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? get _lockoutMessage {
    if (_lockoutUntil == null) return null;
    final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _lockoutUntil = null;
      _failedAttempts = 0;
      return null;
    }
    return 'Quá nhiều lần thử. Vui lòng đợi $remaining giây.';
  }

  bool get _isLockedOut {
    if (_lockoutUntil == null) return false;
    return DateTime.now().isBefore(_lockoutUntil!);
  }

  Future<void> _submit() async {
    if (_isLockedOut) return;
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );

    final status = ref.read(authProvider).status;
    if (status == AuthStatus.error) {
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _lockoutUntil =
            DateTime.now().add(const Duration(seconds: _lockoutSeconds));
        _failedAttempts = 0;
      }
      setState(() {});
    } else {
      _failedAttempts = 0;
      _lockoutUntil = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen để navigate ngay khi state = authenticated
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go(AppRoutes.home);
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                _buildHeader(),
                const SizedBox(height: 40),
                AppTextField(
                  label: 'Email',
                  hint: 'example@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập email.';
                    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
                    if (!emailRegex.hasMatch(v)) return 'Email không hợp lệ.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Mật khẩu',
                  hint: '••••••••',
                  controller: _passwordCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu.';
                    if (v.length < 8) return 'Mật khẩu tối thiểu 8 ký tự.';
                    return null;
                  },
                ),
                if (_lockoutMessage != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: _lockoutMessage!),
                ] else if (authState.error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: authState.error!),
                ],
                const SizedBox(height: 32),
                AppButton(
                  label: 'Đăng nhập',
                  onPressed: isLoading || _isLockedOut ? null : _submit,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                _buildRegisterLink(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.search, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 20),
        const Text(
          'CrackVision',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Đăng nhập để tiếp tục',
          style: TextStyle(fontSize: 15, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Chưa có tài khoản? ', style: TextStyle(color: AppColors.textMuted)),
        GestureDetector(
          onTap: () => context.push(AppRoutes.register),
          child: const Text(
            'Đăng ký',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.crackPositive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.crackPositive.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.crackPositive, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.crackPositive),
            ),
          ),
        ],
      ),
    );
  }
}
