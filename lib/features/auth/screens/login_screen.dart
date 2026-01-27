import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final l10n = AppLocalizations.of(context)!;

    // 로그인 상태 변화 감지 - 로그인 성공 시 홈으로 이동
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final previousUser = previous?.value;
      final currentUser = next.value;
      // 로그아웃 → 로그인 상태로 변경되면 홈으로 이동
      if (previousUser == null && currentUser != null) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // 로고 & 타이틀
              Icon(
                Icons.sports_soccer,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.matchLog,
                style: AppTextStyles.headline1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.myFootballRecord,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 폼
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.enterEmail;
                        }
                        if (!value.contains('@')) {
                          return l10n.invalidEmailFormat;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.enterPasswordPlease;
                        }
                        if (value.length < 6) {
                          return l10n.passwordTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 회원가입 시 이용약관 동의
                    if (!_isLogin) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() => _agreedToTerms = value ?? false);
                              },
                              activeColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showTermsOfService(),
                              child: RichText(
                                text: TextSpan(
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  children: [
                                    TextSpan(text: l10n.agreeToTermsPrefix),
                                    TextSpan(
                                      text: l10n.termsOfService,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(text: l10n.agreeToTermsSuffix),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 제출 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading || (!_isLogin && !_agreedToTerms) ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isLogin ? l10n.loginAction : l10n.signUpAction),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 로그인/회원가입 전환
              TextButton(
                onPressed: () {
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text(
                  _isLogin
                      ? l10n.noAccountSignUp
                      : l10n.hasAccountLogin,
                ),
              ),

              const SizedBox(height: 8),

              // 구분선
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.orDivider,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 24),

              // 구글 로그인
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _signInWithGoogle,
                  icon: Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 24,
                    height: 24,
                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata),
                  ),
                  label: Text(l10n.continueWithGoogle),
                ),
              ),

              // Apple 로그인 (iOS만)
              if (Platform.isIOS) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _signInWithApple,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.black),
                    ),
                    icon: const Icon(Icons.apple, size: 24),
                    label: Text(l10n.continueWithApple),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 비밀번호 찾기
              if (_isLogin)
                TextButton(
                  onPressed: _showForgotPassword,
                  child: Text(l10n.forgotPassword),
                ),

              // 에러 메시지
              if (authState.hasError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getErrorMessage(context, authState.error.toString()),
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
    if (error.contains('email-already-in-use')) {
      return l10n.emailAlreadyInUse;
    } else if (error.contains('invalid-email')) {
      return l10n.invalidEmailError;
    } else if (error.contains('weak-password')) {
      return l10n.weakPasswordError;
    } else if (error.contains('user-not-found')) {
      return l10n.userNotFoundError;
    } else if (error.contains('wrong-password')) {
      return l10n.wrongPasswordError;
    } else if (error.contains('internal-error')) {
      return l10n.authServiceUnavailable;
    }
    return l10n.genericAuthError;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isLogin) {
      ref.read(authNotifierProvider.notifier).signInWithEmail(
        email: email,
        password: password,
      );
    } else {
      ref.read(authNotifierProvider.notifier).signUpWithEmail(
        email: email,
        password: password,
      );
    }
  }

  void _signInWithGoogle() {
    ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  void _signInWithApple() {
    ref.read(authNotifierProvider.notifier).signInWithApple();
  }

  void _showTermsOfService() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.termsOfServiceTitle),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              l10n.termsOfServiceContent,
              style: AppTextStyles.body2,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showForgotPassword() {
    final emailController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetPasswordTitle),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: l10n.emailLabel,
            hintText: l10n.enterRegisteredEmail,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                ref.read(authNotifierProvider.notifier).sendPasswordResetEmail(email);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.passwordResetEmailSent),
                  ),
                );
              }
            },
            child: Text(l10n.sendButton),
          ),
        ],
      ),
    );
  }
}
