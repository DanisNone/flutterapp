import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/screens/chat_screen.dart';
import 'package:flutterapp/service/api.dart' as api;
import 'package:flutterapp/service/follower_service.dart';
import 'package:flutterapp/service/image_loader_service.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  final UserInfo user;
  final int currentUserId;

  const UserProfileScreen({
    super.key,
    required this.user,
    required this.currentUserId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isOpeningChat = false;
  bool _isSubscribing = false;

  String _initials(String username) {
    final parts = username
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _openConversation() async {
    if (widget.user.id == widget.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: 'Это ваш профиль',
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isOpeningChat = true);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: LoadingIndicator()),
      );

      final (conversationId, _) = await api.getOrCreateDialog(widget.user.username);

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            userId: widget.currentUserId,
            chatName: widget.user.username,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: 'Не удалось открыть переписку: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  Future<void> _subscribe() async {
    if (widget.user.id == widget.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: 'Нельзя подписаться на себя',
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubscribing = true);

    try {
      final success = await FollowerService().follow(widget.user.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          MySnackBar(
            text: 'Вы подписались на ${widget.user.username}',
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: 'Не удалось подписаться: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  Widget _buildActionButtons(bool isFollowing, ThemeData theme) {
    final canInteract = widget.user.id != widget.currentUserId;

    if (!canInteract) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Column(
        children: [
          Row(
            children: [
              // Кнопка подписки
              Expanded(
                child: _buildSubscribeButton(isFollowing, theme),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              // Кнопка сообщения
              Expanded(
                child: _buildMessageButton(theme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(bool isFollowing, ThemeData theme) {
    final bgColor = isFollowing
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primary;
    final fgColor = isFollowing
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onPrimary;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: InkWell(
        onTap: isFollowing || _isSubscribing ? null : _subscribe,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
          child: _isSubscribing
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fgColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFollowing ? Icons.check : Icons.person_add,
                      size: 20,
                      color: fgColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFollowing ? 'Подписаны' : 'Подписаться',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: fgColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMessageButton(ThemeData theme) {
    return Material(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: InkWell(
        onTap: _isOpeningChat ? null : _openConversation,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Написать',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowingBadge(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.paddingS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.2),
            theme.colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Вы подписаны',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    int? maxLines,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayValue = value.trim().isEmpty ? 'Не указано' : value;

    final cardTint = isDark ? AppColors.surfaceElevatedSolid : AppColors.cardLightBackground;

    return MyContainer(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      tintColor: cardTint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayValue,
                  maxLines: maxLines,
                  overflow: maxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: value.trim().isEmpty
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = widget.user.fullName?.trim() ?? '';
    final bio = widget.user.bio?.trim() ?? '';
    final hasAvatar = widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty;

    final canOpenChat = widget.user.id != widget.currentUserId;
    final headerAccent = theme.colorScheme.primary.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.12);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Профиль пользователя'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          actions: [
            if (canOpenChat)
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Открыть переписку',
                onPressed: _isOpeningChat ? null : _openConversation,
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'copy_username':
                    Clipboard.setData(ClipboardData(text: '@${widget.user.username}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('@${widget.user.username} скопирован')),
                    );
                    break;
                  case 'open_chat':
                    if (canOpenChat) _openConversation();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (canOpenChat)
                  const PopupMenuItem<String>(
                    value: 'open_chat',
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline),
                        SizedBox(width: 12),
                        Text('Открыть переписку'),
                      ],
                    ),
                  ),
                const PopupMenuItem<String>(
                  value: 'copy_username',
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      SizedBox(width: 12),
                      Text('Скопировать username'),
                    ],
                  ),
                ),
              ],
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Hero(
                    tag: 'user_avatar_${widget.user.id}',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: headerAccent,
                          width: 2,
                        ),
                      ),
                      child: ImageLoader().loadImage(
                        widget.user.avatarUrl,
                        112,
                        Container(
                          width: 112,
                          height: 112,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary.withValues(alpha: theme.brightness == Brightness.dark ? 0.16 : 0.10),
                          ),
                          child: Text(
                            _initials(widget.user.username),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    '@${widget.user.username}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (fullName.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text(
                      fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  Consumer<FollowerService>(
                    builder: (context, service, child) {
                      final isFollowing = service.isFollowing(widget.user.id);
                      return isFollowing ? _buildFollowingBadge(theme) : const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Consumer<FollowerService>(
                    builder: (context, service, child) {
                      final isFollowing = service.isFollowing(widget.user.id);
                      return _buildActionButtons(isFollowing, theme);
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  _infoCard(
                    context: context,
                    title: 'Имя пользователя',
                    value: widget.user.username,
                    icon: Icons.alternate_email,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  _infoCard(
                    context: context,
                    title: 'Полное имя',
                    value: fullName,
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  _infoCard(
                    context: context,
                    title: 'О себе',
                    value: bio,
                    icon: Icons.info_outline,
                    maxLines: 6,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  _infoCard(
                    context: context,
                    title: 'ID',
                    value: widget.user.id.toString(),
                    icon: Icons.numbers,
                  ),
                  if (!hasAvatar) ...[
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      'У пользователя пока нет аватарки',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
