import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/constants/app_text_styles.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInput({super.key, required this.controller, required this.onSend});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  static const int _maxLength = 500;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..onKeyEvent = _handleKeyEvent;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isExceedingLimit => widget.controller.text.length > _maxLength;

  void _handleSubmitted() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty && !_isExceedingLimit) {
      widget.onSend();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final platform = defaultTargetPlatform;

    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      final shiftPressed = HardwareKeyboard.instance.logicalKeysPressed.any(
        (key) =>
            key == LogicalKeyboardKey.shiftLeft ||
            key == LogicalKeyboardKey.shiftRight,
      );

      if (!shiftPressed) {
        _handleSubmitted();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, child) {
                  final isOverLimit = value.text.length > _maxLength;
                  return TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                        borderSide: BorderSide(
                          color: isOverLimit
                              ? AppColors.error.withOpacity(0.5)
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                        borderSide: BorderSide(
                          color: isOverLimit
                              ? AppColors.error
                              : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: isOverLimit
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingL,
                        vertical: AppDimensions.paddingM,
                      ),
                      counterStyle: isOverLimit
                          ? const TextStyle(color: AppColors.error)
                          : AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                    ),
                    minLines: 1,
                    maxLines: 4,
                    maxLength: _maxLength,
                    maxLengthEnforcement: MaxLengthEnforcement.none,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) {
                          return Container(
                            padding: const EdgeInsets.only(right: 8, bottom: 4),
                            child: Text(
                              '$currentLength/$_maxLength',
                              style: TextStyle(
                                color: isOverLimit
                                    ? AppColors.error
                                    : AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                  );
                },
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Container(
              decoration: BoxDecoration(
                gradient: _isExceedingLimit
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                color: _isExceedingLimit ? AppColors.textMuted : null,
                shape: BoxShape.circle,
                boxShadow: _isExceedingLimit
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: IconButton(
                onPressed: _isExceedingLimit ? null : _handleSubmitted,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
