import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/constants/app_text_styles.dart';
import 'package:flutterapp/theme/app_theme.dart';

class ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Text('Произошла ошибка', style: AppTextStyles.headline3),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.paddingXL),
              NeonButton(
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
