import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  
  const EmptyState({
    super.key,
    required this.message,
    required this.icon,
    this.buttonText,
    this.onButtonPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.secondary.shade400,
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppDimensions.paddingXL),
              ElevatedButton(
                onPressed: onButtonPressed,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
