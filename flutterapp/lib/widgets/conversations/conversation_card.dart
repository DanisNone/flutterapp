import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/service/image_loader_service.dart';
import 'package:flutterapp/theme/app_theme.dart';

class ConversationCard extends StatelessWidget {
  final ConversationInfo info;
  final int currentUserId;
  final VoidCallback onTap;

  const ConversationCard({
    super.key,
    required this.info,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String name = info.getName(currentUserId);
    String? avatarUrl = info.getAvatarUrl(currentUserId);
    bool isGroup = !info.isDialog;

    return MyContainer(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      borderRadius: AppDimensions.radiusL,
      opacity: 0.04,
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppDimensions.paddingM),
        leading: ImageLoader().loadImage(
          avatarUrl,
          48,
          Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '#',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white : AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            if (isGroup) ...[
              Icon(
                Icons.group,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: info.lastMessage != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    info.lastMessage!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(info.lastUpdate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              )
            : Text(
                'Нет сообщений',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.2),
                theme.colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }
}