import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/screens/user_profile_screen.dart';
import 'package:flutterapp/service/image_loader_service.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';

class GroupInfoScreen extends StatelessWidget {
  final ConversationInfo conversation;
  final int currentUserId;

  const GroupInfoScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  String _initials(String title) {
    final parts = title
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _openUserProfile(BuildContext context, UserInfo user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(user: user, currentUserId: currentUserId),
      ),
    );
  }

  Widget _memberTile(BuildContext context, UserInfo user) {
    final theme = Theme.of(context);
    final isCurrentUser = user.id == currentUserId;
    final fullName = user.fullName?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openUserProfile(context, user),
        child: MyContainer(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          borderRadius: 16,
          child: Row(
            children: [
              ImageLoader().loadImage(
                user.avatarUrl,
                52,
                Center(
                  child: Text(
                    _initials(user.username),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '@${user.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Вы',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (fullName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = conversation.name?.trim().isNotEmpty == true
        ? conversation.name!.trim()
        : 'Группа';
    final avatarUrl = conversation.getAvatarUrl(currentUserId);
    final memberCount = conversation.usersInfo.length;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Информация о группе'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Скопировать название',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: title));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('«$title» скопировано')),
                );
              },
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingL,
                AppDimensions.paddingL,
                AppDimensions.paddingL,
                AppDimensions.paddingXL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: ImageLoader().loadImage(
                      avatarUrl,
                      116,
                      Container(
                        width: 116,
                        height: 116,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withValues(alpha: 0.10),
                        ),
                        child: Icon(
                          Icons.group,
                          size: 54,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXS),
                  Text(
                    '$memberCount ${memberCount == 1 ? 'участник' : memberCount < 5 ? 'участника' : 'участников'}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  MyContainer(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    child: Row(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Чат группы',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '#${conversation.id}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Text(
                    'Участники',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  ...conversation.usersInfo.map((user) => Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
                        child: _memberTile(context, user),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
