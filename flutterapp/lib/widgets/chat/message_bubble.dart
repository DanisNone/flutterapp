import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/utils/responsive.dart';

class MessageBubble extends StatelessWidget {
  final bool isSended;
  final String text;
  final bool isMine;
  final DateTime timestamp;
  final List<UserInfo> readByUsers;
  final bool showReaded;

  const MessageBubble({
    super.key,
    required this.isSended,
    required this.text,
    required this.isMine,
    required this.timestamp,
    required this.readByUsers,
    required this.showReaded
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);
    final maxWidth =
        isDesktop ? 400.0 : MediaQuery.of(context).size.width * 0.7;

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
    final indicatorColor =
        isMine ? Colors.white : theme.colorScheme.onSurfaceVariant;

    final canOpenReaders = isMine && isSended;

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
                  if (canOpenReaders && showReaded) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _showReadersSheet(context),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          readByUsers.isEmpty ? Icons.done : Icons.done_all,
                          size: 14,
                          color: indicatorColor,
                        ),
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

  Future<void> _showReadersSheet(BuildContext context) async {
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Кто прочитал',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (readByUsers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Пока никто не прочитал это сообщение',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: readByUsers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final user = readByUsers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: (user.avatarUrl != null &&
                                    user.avatarUrl!.isNotEmpty)
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: (user.avatarUrl == null ||
                                    user.avatarUrl!.isEmpty)
                                ? Text(_initials(user.username))
                                : null,
                          ),
                          title: Text(user.username),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials(String username) {
    final parts = username.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatTime(DateTime time) {
    time = time.toLocal();
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}