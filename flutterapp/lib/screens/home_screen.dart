import 'package:flutter/material.dart';
import 'package:flutterapp/service/secure_storage.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await SecureStorageService().getJWTToken();
    setState(() {
      _token = token?.accessToken;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная страница'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ResponsiveContainer(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingXL),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  Text(
                    'Добро пожаловать!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Ваш токен:',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingS),
                        SelectableText(
                          _token ?? 'Токен не найден',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
