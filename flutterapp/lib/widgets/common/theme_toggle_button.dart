import 'package:flutter/material.dart';
import 'package:flutterapp/service/theme_service.dart';
import 'package:provider/provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return IconButton(
          icon: Icon(
            themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: theme.colorScheme.onSurface,
          ),
          tooltip: themeService.isDarkMode ? 'Светлая тема' : 'Тёмная тема',
          onPressed: () => themeService.toggleTheme(),
        );
      },
    );
  }
}