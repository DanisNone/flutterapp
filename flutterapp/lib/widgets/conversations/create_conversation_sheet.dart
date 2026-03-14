import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_text_styles.dart';
import 'package:flutterapp/theme/app_theme.dart';

class CreateConversationSheet extends StatefulWidget {
  final Function(int userId) onCreate;

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
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.glow,
                shadows: [
                  Shadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'ID собеседника',
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
                  return 'Введите ID пользователя';
                }
                if (int.tryParse(value) == null) {
                  return 'Введите корректный числовой ID';
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
      final id = int.parse(_controller.text);
      widget.onCreate(id);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
