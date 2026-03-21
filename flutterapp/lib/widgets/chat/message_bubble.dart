import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/utils/responsive.dart';

class MessageBubble extends StatelessWidget {
  final bool isSended;
  final String text;
  final bool isMine;
  final DateTime timestamp;
  const MessageBubble({
    super.key,
    required this.isSended,
    required this.text,
    required this.isMine,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);
    final maxWidth = isDesktop ? 400.0 : MediaQuery.of(context).size.width * 0.7;

    final bubbleGradient = isMine
        ? LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final bubbleColor = isMine ? null : theme.colorScheme.surfaceContainerHighest;
    final messageColor = isMine ? Colors.white : theme.colorScheme.onSurface;
    final timeColor = isMine
        ? Colors.white.withValues(alpha: 0.7)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final indicatorColor = isMine ? Colors.white : theme.colorScheme.onSurfaceVariant;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXS),
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            gradient: bubbleGradient,
            color: bubbleColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(color: messageColor),
              ),
              const SizedBox(height: AppDimensions.paddingXS),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(color: timeColor),
                  ),
                  if (!isSended) ...[
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    time = time.toLocal();
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}