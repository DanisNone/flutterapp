import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_text_styles.dart';
import 'package:flutterapp/theme/app_theme.dart';

class CreateConversationSheet extends StatefulWidget {
  final Function(String username) onCreate;

  const CreateConversationSheet({super.key, required this.onCreate});

  @override
  State<CreateConversationSheet> createState() =>
      _CreateConversationSheetState();
}

class _CreateConversationSheetState extends State<CreateConversationSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.paddingL,
        right: AppDimensions.paddingL,
        top: AppDimensions.paddingXL,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppDimensions.paddingXL,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Новая переписка',
              style: AppTextStyles.headline3.copyWith(color: AppColors.glow),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.text,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Username собеседника',
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
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
                filled: true,
                fillColor: AppColors.surface,
                prefixIcon: const Icon(
                  Icons.person_add,
                  color: AppColors.primary,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите username пользователя';
                }
                if (value.contains(' ')) {
                  return 'Username не должен содержать пробелов';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: AppDimensions.paddingXL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingL,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                      ),
                      side: BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    child: Text(
                      'Отмена',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: NeonButton(
                    onPressed: _submit,
                    child: const Text('Создать'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final username = _controller.text.trim();
      widget.onCreate(username);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}