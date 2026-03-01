import 'package:flutter/material.dart';
import 'package:flutterapp/screens/home_screen.dart';
import 'package:flutterapp/service/jwttoken.dart';
import 'package:flutterapp/service/register.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Контроллеры для полей ввода
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  void _register() async {
    // Получаем данные из полей
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Простая проверка на пустые поля
    if (email.isEmpty || 
        username.isEmpty || 
        fullName.isEmpty || 
        password.isEmpty || 
        confirmPassword.isEmpty) {
      _showError('Пожалуйста, заполните все поля');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Вызываем вашу функцию register
      final token = await register(
        email, 
        username, 
        fullName, 
        password, 
        confirmPassword
      );
      
      if (!mounted) return;

      // Переходим на главный экран
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(token: token)),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Показываем ошибку
      String error = e.toString();
      if (error.startsWith('Exception: ')) {
        error = error.substring(11);
      }
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Заголовок
                const Text(
                  'Создать аккаунт',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                
                // Имя пользователя
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя пользователя',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                
                // Полное имя
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Полное имя',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                
                // Пароль
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                
                // Подтверждение пароля
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Подтвердите пароль',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                
                // Кнопка регистрации
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Зарегистрироваться',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Ссылка на вход
                TextButton(
                  onPressed: _isLoading 
                      ? null 
                      : () => Navigator.pop(context),
                  child: const Text('Уже есть аккаунт? Войти'),
                ),
              ],
            ),
          ),
        ),
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