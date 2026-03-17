import 'package:flutter/material.dart';

class AppColors {
  // Deep dark background gradient colors
  static const backgroundStart = Color(0xFF050012);
  static const backgroundEnd = Color(0xFF120022);
  
  // Solid background (non-transparent)
  static const backgroundDark = Color(0xFF120022);
  static const backgroundDarker = Color(0xFF050012);

  // Primary neon accent
  static const primary = Color(0xFF8A5CFF);
  static const primaryLight = Color(0xFFB794FF);
  static const primaryDark = Color(0xFF6B3FD4);
  
  // Accent alias (same as primary) - NEW
  static const accent = primary;
  static const accentLight = primaryLight;

  // Glow accent
  static const glow = Color(0xFFCFA7FF);

  // Secondary accent (pink)
  static const secondary = Color(0xFFFF7ACB);
  static const secondaryLight = Color(0xFFFFA8E0);

  // Semantic colors with neon twist
  static const success = Color(0xFF00E5A0);
  static const error = Color(0xFFFF5252);
  static const warning = Color(0xFFFFD740);

  // Surface colors with glassmorphism (transparent - legacy)
  static const surface = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)
  static const surfaceDark = Color(0x9912081E); // rgba(18,8,30,0.6)
  static const surfaceElevated = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // SOLID surface colors (non-transparent) - NEW
  static const surfaceSolid = Color(0xFF1B0A2A);
  static const surfaceElevatedSolid = Color(0xFF241433);
  static const surfaceLight = Color(0xFF2D1A3D);
  static const surfaceLighter = Color(0xFF3D2550);

  // Text colors (transparent - legacy)
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xBFFFFFFF);
  static const textMuted = Color(0x59FFFFFF);
  static const textHint = Color(0x4DFFFFFF);

  // SOLID text colors (non-transparent) - NEW
  static const textSecondarySolid = Color(0xFFC3BFC7);
  static const textMutedSolid = Color(0xFF64596F);
  static const textHintSolid = Color(0xFF594C64);

  // Message bubbles
  static const myMessage = primary;
  static const theirMessage = Color(0x14FFFFFF);

  // Message selection colors - NEW
  static const messageSelected = Color(0xFF2D1A5A);
  static const messageSelectedBorder = primary;
  static const selectionOverlay = Color(0xFF1B0A4A);

  // Status indicators
  static const online = success;
  static const offline = Color(0x59FFFFFF);

  // Border colors (transparent - legacy)
  static const border = Color(0x1AFFFFFF);
  static const borderGlow = Color(0x408A5CFF);

  // SOLID border colors - NEW
  static const borderSolid = Color(0xFF291938);
  static const borderLight = Color(0xFF3D2550);
  static const borderAccent = primary;

  // Toolbar colors - NEW
  static const toolbarBackground = surfaceSolid;
  static const toolbarAction = primaryLight;
  static const toolbarActionDestructive = secondary;

  // Checkbox colors - NEW
  static const checkboxActive = primary;
  static const checkboxInactive = Color(0xFF594C64);

  // Interactive states - NEW
  static const hover = surfaceLight;
  static const pressed = surfaceLighter;
  static const ripple = Color(0x408A5CFF);

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
  
  // SOLID glow for non-transparent usage - NEW
  static const glowSolid = Color(0xFF4A3A6A);
}