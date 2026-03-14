import 'package:flutter/material.dart';

class AppColors {
  // Deep dark background gradient colors
  static const backgroundStart = Color(0xFF050012);
  static const backgroundEnd = Color(0xFF120022);

  // Primary neon accent
  static const primary = Color(0xFF8A5CFF);
  static const primaryLight = Color(0xFFB794FF);
  static const primaryDark = Color(0xFF6B3FD4);

  // Glow accent
  static const glow = Color(0xFFCFA7FF);

  // Secondary accent (pink)
  static const secondary = Color(0xFFFF7ACB);
  static const secondaryLight = Color(0xFFFFA8E0);

  // Semantic colors with neon twist
  static const success = Color(0xFF00E5A0);
  static const error = Color(0xFFFF5252);
  static const warning = Color(0xFFFFD740);

  // Surface colors with glassmorphism
  static const surface = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)
  static const surfaceDark = Color(0x9912081E); // rgba(18,8,30,0.6)
  static const surfaceElevated = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // Text colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xBFFFFFFF); // rgba(255,255,255,0.75)
  static const textMuted = Color(0x59FFFFFF); // rgba(255,255,255,0.35)
  static const textHint = Color(0x4DFFFFFF); // rgba(255,255,255,0.30)

  // Message bubbles
  static const myMessage = primary;
  static const theirMessage = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // Status indicators
  static const online = success;
  static const offline = Color(0x59FFFFFF);

  // Border colors
  static const border = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const borderGlow = Color(0x408A5CFF); // rgba(138,92,255,0.25)

  // Gradient definitions
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundEnd],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const glowGradient = LinearGradient(
    begin: Alignment.center,
    end: Alignment.bottomCenter,
    colors: [glow, Colors.transparent],
  );
}
