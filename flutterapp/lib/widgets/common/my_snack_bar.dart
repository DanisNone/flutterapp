import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_text_styles.dart';

class MySnackBar extends SnackBar {
  MySnackBar({super.key, required String text, required Color backgroundColor})
    : super(
        content: Text(
          text,
          style: AppTextStyles.headline3,
          textAlign: TextAlign.center,
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}
