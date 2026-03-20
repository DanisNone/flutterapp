import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterapp/constants/app_dimensions.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const ChatInput({super.key, required this.controller, required this.onSend});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  static const int _maxLength = 5000;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surfaceContainer,
          border: Border(top: BorderSide(color: theme.colorScheme.outline, width: 1)),
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
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        borderSide: BorderSide(
                          color: isOverLimit
                              ? theme.colorScheme.error.withValues(alpha: 0.5)
                              : theme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        borderSide: BorderSide(
                          color: isOverLimit ? theme.colorScheme.error : theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: isOverLimit
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingL,
                        vertical: AppDimensions.paddingM,
                      ),
                      counterStyle: isOverLimit
                          ? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)
                          : theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    minLines: 1,
                    maxLines: 4,
                    maxLength: _maxLength,
                    maxLengthEnforcement: MaxLengthEnforcement.none,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                      return Container(
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        child: Text(
                          '$currentLength/$_maxLength',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOverLimit ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
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
                    : LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      ),
                color: _isExceedingLimit ? theme.colorScheme.onSurfaceVariant : null,
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
