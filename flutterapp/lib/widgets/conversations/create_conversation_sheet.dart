import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/constants/app_colors.dart';

class CreateConversationSheet extends StatefulWidget {
  final Function(int userId) onCreate;
  
  const CreateConversationSheet({
    super.key,
    required this.onCreate,
  });
  
  @override
  State<CreateConversationSheet> createState() => _CreateConversationSheetState();
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
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.paddingXL,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Новая переписка',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'ID собеседника',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                prefixIcon: const Icon(Icons.person_add),
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
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingL,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                    ),
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
