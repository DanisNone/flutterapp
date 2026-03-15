import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/constants/app_text_styles.dart';
import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/model/user_info.dart';
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
    String name = info.getName(currentUserId);
    String? avatarUrl = info.getAvatarUrl(currentUserId);

    return MyContainer(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      borderRadius: AppDimensions.radiusL,
      opacity: 0.04,
      border: Border.all(color: AppColors.border, width: 1),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppDimensions.paddingM),
        leading: ImageLoader().loadImage(
          avatarUrl,
          48,
          Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '#',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w600),
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(info.lastUpdate),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              )
            : Text(
                'Нет сообщений',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
              ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.glow.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Icon(Icons.chevron_right, color: AppColors.primary),
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
