import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/constants/app_text_styles.dart';
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
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMine ? null : AppColors.theirMessage,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: isMine
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: isMine
                  ? AppTextStyles.myMessage
                  : AppTextStyles.theirMessage,
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary.withValues(alpha: 0.7),
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
                        isMine ? Colors.white : AppColors.textSecondary,
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
