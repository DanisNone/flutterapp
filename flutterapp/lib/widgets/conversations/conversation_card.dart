import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/model/ConversationInfo.dart';

class ConversationCard extends StatelessWidget {
  final ConversationInfo info;
  final int currentUserId;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final VoidCallback onTap;
  
  const ConversationCard({
    super.key,
    required this.info,
    required this.currentUserId,
    this.lastMessage,
    this.lastMessageTime,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    String name;
    if (info.userfInfo == null || info.userfInfo!.length != 2) {
      name = 'Беседа #${info.id}';
    } else {
      if (info.userfInfo![0].$1 == currentUserId) {
        name = info.userfInfo![1].$2;
      } else {
        name = info.userfInfo![0].$2;
      }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppDimensions.paddingM),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          radius: 24,
          child: Text(
            info.id.toString(),
            style: TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: lastMessage != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    lastMessage!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (lastMessageTime != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(lastMessageTime!),
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                'Нет сообщений',
                style: TextStyle(color: AppColors.textHint),
              ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chevron_right,
            color: AppColors.primary,
          ),
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
