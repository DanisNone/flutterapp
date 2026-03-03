import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';

class ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.shade300,
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              'Произошла ошибка',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              error,
              style: TextStyle(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.paddingXL),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Повторить попытку'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
