import 'package:flutter/material.dart';

class AppColors {
  // Deep dark background gradient colors
  static const backgroundStart = Color(0xFF060012);
  static const backgroundEnd = Color(0xFF130021);
  
  // Light background gradient colors - IMPROVED CONTRAST
  static const backgroundLightStart = Color(0xFFFBFBFF);
  static const backgroundLightEnd = Color(0xFFF2F0F6);
  
  // Solid background (non-transparent)
  static const backgroundDark = Color(0xFF130021);
  static const backgroundDarker = Color(0xFF060012);
  
  // Primary neon accent
  static const primary = Color(0xFF8C5CFF);
  static const primaryLight = Color(0xFFB796FF);
  static const primaryDark = Color(0xFF6C3DD9);
  
  // Accent alias (same as primary) - NEW
  static const accent = primary;
  static const accentLight = primaryLight;
  
  // Glow accent
  static const glow = Color(0xFFD0AAFF);
  
  // Secondary accent (pink)
  static const secondary = Color(0xFFFF6FC7);
  static const secondaryLight = Color(0xFFFFA3DE);
  
  // Semantic colors with neon twist
  static const success = Color(0xFF14D39A);
  static const error = Color(0xFFFF5A5F);
  static const warning = Color(0xFFFFCF4D);
  
  // Surface colors with glassmorphism (transparent - legacy)
  static const surface = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const surfaceDark = Color(0xCC140A23); // rgba(20,10,35,0.80)
  static const surfaceElevated = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  
  // SOLID surface colors (non-transparent) - NEW
  static const surfaceSolid = Color(0xFF1A0C2B);
  static const surfaceElevatedSolid = Color(0xFF241236);
  static const surfaceLight = Color(0xFF322043);
  static const surfaceLighter = Color(0xFF422B57);
  
  // Light theme surface colors - IMPROVED
  static const surfaceLightTheme = Color(0xFFFFFFFF);
  static const surfaceLightThemeElevated = Color(0xFFF6F4FA);
  static const surfaceLightThemeContainer = Color(0xFFF1EFF6);
  
  // Text colors (transparent - legacy)
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xCCFFFFFF);
  static const textMuted = Color(0x66FFFFFF);
  static const textHint = Color(0x4DFFFFFF);
  
  // Light theme text colors - IMPROVED CONTRAST
  static const textPrimaryDark = Color(0xFF17172A);
  static const textSecondaryDark = Color(0xFF4D4D63);
  static const textMutedDark = Color(0xFF6B6680);
  static const textHintDark = Color(0xFF8E8A9B);
  
  // SOLID text colors (non-transparent) - NEW
  static const textSecondarySolid = Color(0xFFC9C5D2);
  static const textMutedSolid = Color(0xFF6B6680);
  static const textHintSolid = Color(0xFF5D5770);
  
  // Message bubbles
  static const myMessage = primary;
  static const theirMessage = Color(0x14FFFFFF);
  
  // Message selection colors - NEW
  static const messageSelected = Color(0xFF2D1A5A);
  static const messageSelectedBorder = primary;
  static const selectionOverlay = Color(0xFF1D0B4D);
  
  // Status indicators
  static const online = success;
  static const offline = Color(0x66FFFFFF);
  static const offlineLight = Color(0xFFB4B4C4);
  
  // Border colors (transparent - legacy)
  static const border = Color(0x1AFFFFFF);
  static const borderGlow = Color(0x408C5CFF);
  
  // SOLID border colors - NEW
  static const borderSolid = Color(0xFF2A1A3B);
  static const borderLight = Color(0xFF422B57);
  static const borderAccent = primary;
  
  // Light theme border colors - IMPROVED
  static const borderLightTheme = Color(0xFFE2E1E8);
  static const borderLightThemeStrong = Color(0xFFC8C5D1);
  
  // Toolbar colors - NEW
  static const toolbarBackground = surfaceSolid;
  static const toolbarAction = primaryLight;
  static const toolbarActionDestructive = secondary;
  
  // Checkbox colors - NEW
  static const checkboxActive = primary;
  static const checkboxInactive = Color(0xFF5D5770);
  
  // Interactive states - NEW
  static const hover = surfaceLight;
  static const pressed = surfaceLighter;
  static const ripple = Color(0x408C5CFF);
  static const hoverLight = Color(0xFFF6F4FA);
  static const pressedLight = Color(0xFFE9E5F3);
  
  // Gradient definitions
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundEnd],
  );
  
  static const backgroundLightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundLightStart, backgroundLightEnd],
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
  static const glowSolid = Color(0xFF4D3A6A);
  
  // Light theme card/container background
  static const cardLightBackground = Color(0xFFFFFFFF);
  static const cardLightBackgroundElevated = Color(0xFFF8F7FB);
}