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
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXS),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        constraints: BoxConstraints(
          maxWidth: Responsive.isDesktop(context)
              ? 400
              : MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          gradient: isMine
              ? LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMine ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: isMine
                  ? theme.textTheme.bodyMedium?.copyWith(color: Colors.white)
                  : theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.7)
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
                if (!isSended)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isMine ? Colors.white : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    time = time.toLocal();
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}