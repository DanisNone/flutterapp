import 'package:flutter/material.dart';

class MySnackBar extends SnackBar {
  MySnackBar({super.key, required String text, required Color backgroundColor})
      : super(
          content: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
}