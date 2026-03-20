import 'package:flutter/material.dart';
import 'package:flutterapp/screens/auth/login_screen.dart';
import 'package:flutterapp/screens/main/main_screen.dart';
import 'package:flutterapp/service/register.dart';
import 'package:flutterapp/service/secure_storage.dart';
import 'package:flutterapp/utils/responsive.dart';
import 'package:flutterapp/widgets/auth/auth_field.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutterapp/service/theme_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Пожалуйста, заполните все поля');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Пароли не совпадают');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await register(
        _emailController.text,
        _usernameController.text,
        _fullNameController.text,
        _passwordController.text,
        _confirmPasswordController.text,
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
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      MySnackBar(
        text: message,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveBuilder(
        builder: (context, isMobile, isTablet, isDesktop) {
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
                    // Neon icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isDark
                              ? [theme.colorScheme.secondary, theme.colorScheme.primary]
                              : [theme.colorScheme.secondary, theme.colorScheme.primary],
                        ),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Регистрация',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: isDark ? theme.colorScheme.secondary : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Создайте новый аккаунт',
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
                      controller: _usernameController,
                      label: 'Имя пользователя',
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    AuthField(
                      controller: _fullNameController,
                      label: 'Полное имя',
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    AuthField(
                      controller: _passwordController,
                      label: 'Пароль',
                      obscure: true,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    AuthField(
                      controller: _confirmPasswordController,
                      label: 'Подтвердите пароль',
                      obscure: true,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 32),
                    NeonButton(
                      onPressed: _register,
                      isLoading: _isLoading,
                      child: const Text('Зарегистрироваться'),
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
                                      child: LoginScreen(),
                                    ),
                                  ),
                                );
                              },
                        child: Text(
                          'Уже есть аккаунт? Войти',
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
    _usernameController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
