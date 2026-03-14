import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';

class AuthForm extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final String submitText;
  final VoidCallback onSubmit;
  final bool isLoading;
  final Widget? footer;

  const AuthForm({
    super.key,
    required this.title,
    required this.fields,
    required this.submitText,
    required this.onSubmit,
    this.isLoading = false,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(AppDimensions.paddingXXL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXXL),
              ...fields,
              const SizedBox(height: AppDimensions.paddingXXL),
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          submitText,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: AppDimensions.paddingL),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
