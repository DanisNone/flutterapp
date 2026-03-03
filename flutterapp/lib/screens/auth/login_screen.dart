import 'package:flutter/material.dart';
import 'package:flutterapp/screens/auth/register_screen.dart';
import 'package:flutterapp/screens/conversations_screen.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/service/login.dart';
import 'package:flutterapp/service/secure_storage.dart';
import 'package:flutterapp/service/user.dart';
import 'package:flutterapp/widgets/auth/auth_form.dart';
import 'package:flutterapp/widgets/auth/auth_field.dart';
import 'package:flutterapp/utils/responsive.dart';

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
      // Получаем сохраненный токен
      final JWTToken? token = await SecureStorageService().getJWTToken();
      
      if (token != null) {
        // Проверяем валидность токена, пытаясь получить данные пользователя
        try {
          await getUser(token);
          
          // Если запрос успешен, переходим на следующий экран
          if (!mounted) return;
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationsScreen(token: token),
            ),
          );
          return;
        } catch (e) {
          // Токен невалидный - удаляем его и остаемся на экране входа
          await SecureStorageService().deleteJWTToken();
        }
      }
    } catch (e) {
      // Ошибка при проверке токена - просто остаемся на экране входа
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
        SnackBar(
          content: Text('Ошибка входа: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
      backgroundColor: Colors.blue[50],
      body: ResponsiveBuilder(
        builder: (context, isMobile, isTablet, isDesktop) {
          if (_isCheckingToken) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return AuthForm(
            title: 'Авторизация',
            fields: [
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
            ],
            submitText: 'Войти',
            onSubmit: _login,
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
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Регистрация'),
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