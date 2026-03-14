import 'package:flutter/material.dart';
import 'package:flutterapp/screens/auth/register_screen.dart';
import 'package:flutterapp/screens/conversations_screen.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/service/login.dart';
import 'package:flutterapp/service/secure_storage.dart';
import 'package:flutterapp/widgets/auth/auth_field.dart';
import 'package:flutterapp/utils/responsive.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_text_styles.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingToken = true;

  @override
  void initState() {
    super.initState();
    _checkExistingToken();
  }

  Future<void> _checkExistingToken() async {
    setState(() => _isCheckingToken = true);

    try {
      final JWTToken? token = await SecureStorageService().getJWTToken();
      if (token != null && await token.updateToken()) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationsScreen(token: token),
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('Ошибка при проверке токена: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingToken = false);
      }
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final token = await login(
        _emailController.text,
        _passwordController.text,
      );

      await SecureStorageService().saveJWTToken(token);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationsScreen(token: token),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: 'Ошибка входа: $e',
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveBuilder(
        builder: (context, isMobile, isTablet, isDesktop) {
          if (_isCheckingToken) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassContainer(
                width: isMobile ? double.infinity : 420,
                padding: const EdgeInsets.all(32),
                borderRadius: 20,
                opacity: 0.06,
                border: Border.all(color: AppColors.borderGlow, width: 1.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Neon logo/title
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.glow],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Вход',
                      style: AppTextStyles.headline2.copyWith(
                        color: AppColors.glow,
                        shadows: [
                          Shadow(
                            color: AppColors.primary.withOpacity(0.8),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Войдите в свой аккаунт',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 32),
                    AuthField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    AuthField(
                      controller: _passwordController,
                      label: 'Пароль',
                      obscure: true,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 32),
                    NeonButton(
                      onPressed: _login,
                      isLoading: _isLoading,
                      child: const Text('Войти'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const GradientBackground(
                                          child: RegisterScreen(),
                                        ),
                                  ),
                                );
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'Создать аккаунт',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
