import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_dimensions.dart';

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType keyboardType;
  final bool enabled;
  final String? Function(String?)? validator;
  
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.validator,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
