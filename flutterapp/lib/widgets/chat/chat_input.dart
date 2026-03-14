import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

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

    // На мобильных не перехватываем Enter → обычный перенос строки
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return KeyEventResult.ignored;
    }

    // На desktop/web Enter отправляет сообщение
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
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
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        borderSide: BorderSide(
                          color: isOverLimit ? Colors.red.shade300 : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        borderSide: BorderSide(
                          color: isOverLimit ? Colors.red.shade400 : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: isOverLimit ? Colors.red.shade50 : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingL,
                        vertical: AppDimensions.paddingM,
                      ),
                      // Use maxLength but allow exceeding via MaxLengthEnforcement.none
                      counterStyle: isOverLimit
                          ? const TextStyle(color: Colors.red)
                          : null,
                    ),
                    minLines: 1,
                    maxLines: 4,
                    maxLength: _maxLength,
                    maxLengthEnforcement: MaxLengthEnforcement.none,
                    buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) {
                      return Container(
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        child: Text(
                          '$currentLength/$_maxLength',
                          style: TextStyle(
                            color: isOverLimit ? Colors.red : Colors.grey,
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
                color: _isExceedingLimit ? Colors.grey : AppColors.primary,
                shape: BoxShape.circle,
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