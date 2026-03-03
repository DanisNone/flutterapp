import 'package:flutter/material.dart';
import 'package:flutterapp/screens/auth/login_screen.dart';
import 'package:flutterapp/screens/conversations_screen.dart';
import 'package:flutterapp/service/register.dart';
import 'package:flutterapp/service/secure_storage.dart';
import 'package:flutterapp/utils/responsive.dart';
import 'package:flutterapp/widgets/auth/auth_form.dart';
import 'package:flutterapp/widgets/auth/auth_field.dart';

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
    // Валидация
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
        MaterialPageRoute(builder: (context) => ConversationsScreen(token: token)),
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: ResponsiveBuilder(
        builder: (context, isMobile, isTablet, isDesktop) {
          return AuthForm(
            title: 'Регистрация',
            fields: [
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
            ],
            submitText: 'Зарегистрироваться',
            onSubmit: _register,
            isLoading: _isLoading,
            footer: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Уже есть аккаунт? Войти'),
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
