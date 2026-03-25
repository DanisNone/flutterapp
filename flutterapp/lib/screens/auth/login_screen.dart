import 'package:flutter/material.dart';
import 'package:flutterapp/screens/auth/register_screen.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/screens/main/main_screen.dart';
import 'package:flutterapp/service/api.dart' show login;
import 'package:flutterapp/service/notification_service.dart';
import 'package:flutterapp/service/secure_storage.dart';
import 'package:flutterapp/widgets/auth/auth_field.dart';
import 'package:flutterapp/utils/responsive.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutterapp/service/theme_service.dart';

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
            builder: (context) => GradientBackground(
              child: MainScreen(token: token),
            ),
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
    final fcmToken = context.read<NotificationService>().token;
    try {
      final token = await login(
        _emailController.text,
        _passwordController.text,
        fcmToken
      );
      await SecureStorageService().saveJWTToken(token);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GradientBackground(
            child: MainScreen(token: token),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: 'Ошибка входа: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveBuilder(
        builder: (context, isMobile, isTablet, isDesktop) {
          if (_isCheckingToken) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            );
          }
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: MyContainer(
                width: isMobile ? double.infinity : 420,
                padding: const EdgeInsets.all(32),
                borderRadius: 20,
                opacity: 0.06,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Neon logo/title
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isDark
                              ? [theme.colorScheme.primary, theme.colorScheme.secondary]
                              : [theme.colorScheme.primary, theme.colorScheme.secondary],
                        ),
                      ),
                      child: Icon(
                        Icons.chat_bubble,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Вход',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: isDark ? theme.colorScheme.primary : theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Войдите в свой аккаунт',
                      style: theme.textTheme.bodyMedium,
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
                                    builder: (context) => const GradientBackground(
                                      child: RegisterScreen(),
                                    ),
                                  ),
                                );
                              },
                        child: Text(
                          'Создать аккаунт',
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                    ),
                    // Theme Toggle
                    const SizedBox(height: 24),
                    Consumer<ThemeService>(
                      builder: (context, themeService, child) {
                        return IconButton(
                          icon: Icon(
                            themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: () => themeService.toggleTheme(),
                        );
                      },
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
