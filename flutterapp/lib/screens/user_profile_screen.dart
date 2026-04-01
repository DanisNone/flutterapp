import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _toggleFollow(FollowerService service, bool isFollowing) async {
    if (widget.user.id == widget.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: 'Нельзя подписаться на себя',
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final success = isFollowing
        ? await service.unfollow(widget.user.id)
        : await service.follow(widget.user.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: isFollowing
              ? 'Вы отписались от ${widget.user.username}'
              : 'Вы подписались на ${widget.user.username}',
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    final error = service.mutationError ?? 'Не удалось обновить подписку';
    ScaffoldMessenger.of(context).showSnackBar(
      MySnackBar(
        text: error,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, bool isFollowing) {
    if (!isFollowing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Подписаны',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryFollowButton(
    ThemeData theme,
    FollowerService service,
    bool isFollowing,
  ) {
    final isPending = service.isRelationPending(widget.user.id);
    final isSelf = widget.user.id == widget.currentUserId;
    final label = isPending
        ? 'В процессе...'
        : isFollowing
            ? 'Отписаться'
            : 'Подписаться';

    final background = isFollowing
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primary;
    final foreground = isFollowing
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: isSelf || isPending ? null : () => _toggleFollow(service, isFollowing),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isPending
              ? SizedBox(
                  key: const ValueKey('follow-loading'),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              : Row(
                  key: ValueKey(label),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFollowing ? Icons.person_remove_alt_1 : Icons.person_add_alt_1,
                      size: 20,
                      color: foreground,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMessageButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isOpeningChat ? null : _openConversation,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          foregroundColor: theme.colorScheme.onSurface,
        ),
        icon: _isOpeningChat
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : const Icon(Icons.chat_bubble_outline, size: 20),
        label: Text(
          'Написать сообщение',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
    final displayValue = value.trim().isEmpty ? 'Не указано' : value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
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
    final headerAccent = theme.colorScheme.primary.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Профиль пользователя'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          actions: [
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Hero(
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
                  const SizedBox(height: AppDimensions.paddingM),
                  Consumer<FollowerService>(
                    builder: (context, service, child) {
                      final isFollowing = service.isFollowing(widget.user.id) || widget.user.isFollowing == true;
                      return Center(child: _buildStatusChip(theme, isFollowing));
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Consumer<FollowerService>(
                    builder: (context, service, child) {
                      final isFollowing = service.isFollowing(widget.user.id) || widget.user.isFollowing == true;
                      return Column(
                        children: [
                          _buildPrimaryFollowButton(theme, service, isFollowing),
                          if (canOpenChat) ...[
                            const SizedBox(height: AppDimensions.paddingM),
                            _buildMessageButton(theme),
                          ],
                        ],
                      );
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
