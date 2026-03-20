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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
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
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceSolid,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
        surfaceContainerHighest: AppColors.surfaceElevated,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        primaryContainer: AppColors.messageSelected,
        errorContainer: AppColors.error.withValues(alpha: 0.2),
      ),
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
      dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1),
      iconTheme: IconThemeData(
        color: AppColors.textSecondary,
        size: AppDimensions.iconL,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: AppColors.primary,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        titleTextStyle: AppTextStyles.title.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          textStyle: AppTextStyles.button.copyWith(color: Colors.white),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          side: BorderSide(
            color: AppColors.primaryDark.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primaryDark),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLightThemeContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: BorderSide(color: AppColors.borderLightTheme, width: 1),
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
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHintDark),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: AppColors.cardLightBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          side: BorderSide(color: AppColors.borderLightTheme, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLightTheme,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryDark,
        onError: Colors.white,
        surfaceContainerHighest: AppColors.surfaceLightThemeContainer,
        onSurfaceVariant: AppColors.textSecondaryDark,
        outline: AppColors.borderLightTheme,
        primaryContainer: AppColors.primaryLight.withValues(alpha: 0.2),
        errorContainer: AppColors.error.withValues(alpha: 0.1),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.headline1.copyWith(color: AppColors.textPrimaryDark),
        headlineMedium: AppTextStyles.headline2.copyWith(color: AppColors.textPrimaryDark),
        headlineSmall: AppTextStyles.headline3.copyWith(color: AppColors.textPrimaryDark),
        titleLarge: AppTextStyles.title.copyWith(color: AppColors.textPrimaryDark),
        titleMedium: AppTextStyles.subtitle.copyWith(color: AppColors.textSecondaryDark),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimaryDark),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
        labelLarge: AppTextStyles.button.copyWith(color: AppColors.textPrimaryDark),
      ),
      dividerTheme: DividerThemeData(color: AppColors.borderLightTheme, thickness: 1),
      iconTheme: IconThemeData(
        color: AppColors.textSecondaryDark,
        size: AppDimensions.iconL,
      ),
    );
  }

  static ThemeData getTheme(bool isDark) => isDark ? darkTheme : lightTheme;
}

// Container widget for reuse - FIXED FOR LIGHT MODE
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final BoxDecoration decoration;
    if (isDark) {
      // Dark mode: white transparency works well
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (tintColor ?? Colors.white).withValues(alpha: opacity),
            (tintColor ?? Colors.white).withValues(alpha: opacity * 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: AppColors.border,
              width: 1,
            ),
      );
    } else {
      // Light mode: use solid surface colors with subtle border
      decoration = BoxDecoration(
        color: tintColor ?? AppColors.cardLightBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: AppColors.borderLightTheme,
              width: 1,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    return Container(
      margin: margin,
      width: width,
      height: height,
      padding: padding,
      decoration: decoration,
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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

// Background gradient container - theme aware
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [AppColors.backgroundStart, AppColors.backgroundEnd]
              : [AppColors.backgroundLightStart, AppColors.backgroundLightEnd],
        ),
      ),
      child: child,
    );
  }
}