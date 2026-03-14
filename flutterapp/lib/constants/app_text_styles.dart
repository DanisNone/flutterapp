import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Main headings - 34-40px, bold, increased letter spacing
  static const TextStyle headline1 = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
    fontFamily: 'Inter',
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.8,
    fontFamily: 'Inter',
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    fontFamily: 'Inter',
  );

  // Section headings - 22-28px, semibold
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
    fontFamily: 'Inter',
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
    fontFamily: 'Inter',
  );

  // Body text - 14-16px
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    fontFamily: 'Inter',
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    fontFamily: 'Inter',
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
    fontFamily: 'Inter',
  );

  // Button text - 16-18px, semibold
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    fontFamily: 'Inter',
  );

  // Message styles
  static const TextStyle myMessage = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white,
    letterSpacing: 0.1,
    fontFamily: 'Inter',
  );

  static const TextStyle theirMessage = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    fontFamily: 'Inter',
  );

  // Neon glow text effect
  static const TextStyle neonTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.glow,
    letterSpacing: 2.0,
    fontFamily: 'Inter',
    shadows: [
      Shadow(
        color: AppColors.primary,
        blurRadius: 20,
        offset: Offset(0, 0),
      ),
      Shadow(
        color: AppColors.glow,
        blurRadius: 40,
        offset: Offset(0, 0),
      ),
    ],
  );
}
