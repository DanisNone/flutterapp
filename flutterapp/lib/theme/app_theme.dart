import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: AppColors.primary,
      fontFamily: 'Inter',

      // AppBar theme with glass effect
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.title.copyWith(
          color: AppColors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      ),

      // Elevated button with neon glow
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(
                double.infinity,
                AppDimensions.buttonHeight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              elevation: 0,
              shadowColor: AppColors.primary.withValues(alpha: 0.5),
              textStyle: AppTextStyles.button,
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                AppColors.glow.withValues(alpha: 0.2),
              ),
            ),
      ),

      // Outlined button with neon border
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(
                double.infinity,
                AppDimensions.buttonHeight,
              ),
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              textStyle: AppTextStyles.button,
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
      ),

      // Input decoration with glass effect
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.all(AppDimensions.paddingL),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // Card theme with glass effect
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Floating action button with glow
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        ),
      ),

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.backgroundStart,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: Colors.white,
      ),

      // Text theme
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.headline1,
        headlineMedium: AppTextStyles.headline2,
        headlineSmall: AppTextStyles.headline3,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.subtitle,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1),

      // Icon theme
      iconTheme: IconThemeData(
        color: AppColors.textSecondary,
        size: AppDimensions.iconL,
      ),
    );
  }
}

// Glass container widget for reuse
class MyContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? tintColor;
  final double opacity;
  final Border? border;

  const MyContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.tintColor,
    this.opacity = 0.04,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (tintColor ?? Colors.white).withValues(alpha: opacity),
            (tintColor ?? Colors.white).withValues(alpha: opacity * 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppColors.border, width: 1),
        ),
      child: child,
    );
  }
}

// Neon glow button
class NeonButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double height;

  const NeonButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : DefaultTextStyle(
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }
}

// Background gradient container
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
        ),
      ),
      child: child,
    );
  }
}
