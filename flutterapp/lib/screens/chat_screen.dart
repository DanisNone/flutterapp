import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterapp/service/image_loader_service.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/model/chat_thread_state.dart';
import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/service/chat_repository.dart';
import 'package:flutterapp/screens/group_info_screen.dart';
import 'package:flutterapp/screens/user_profile_screen.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/chat/chat_input.dart';
import 'package:flutterapp/widgets/chat/message_bubble.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/error_view.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final int userId;
  final String chatName;
  final int? initialMessageReadId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.chatName,
    required this.userId,
    this.initialMessageReadId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatRepository _repository;
  bool _initialized = false;

  final TextEditingController _controller = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  final Set<Message> _selectedMessages = {};

  bool _isSelectionMode = false;
  bool _initialPositionRestored = false;
  bool _isRestoringInitialPosition = false;
  bool _paginationArmed = true;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    _repository = context.read<ChatRepository>();
    _repository.ensureThreadLoaded(widget.conversationId);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onItemPositionsChanged() {
    if (_isRestoringInitialPosition) return;

    final thread = _repository.threadFor(widget.conversationId);
    if (thread == null) return;

    _handlePagination(thread);
    _syncReadReceipt(thread);
  }

  void _handlePagination(ChatThreadState thread) {
    if (!thread.canLoadOlder || thread.loadingOlder) {
      _paginationArmed = true;
      return;
    }

    final visibleCount = _visibleMessages(thread).length;
    if (visibleCount == 0) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    int maxVisibleIndex = -1;
    for (final pos in positions) {
      if (pos.index > maxVisibleIndex) maxVisibleIndex = pos.index;
    }

    // reverse: true => "older" messages are near the top of the screen,
    // that corresponds to larger indices in the visible list.
    final nearTop = maxVisibleIndex >= visibleCount - 3;

    if (!nearTop) {
      _paginationArmed = true;
      return;
    }

    if (_paginationArmed) {
      _paginationArmed = false;
      _repository.loadOlder(widget.conversationId);
    }
  }

  void _syncReadReceipt(ChatThreadState thread) {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    int minVisibleIndex = 1 << 30;

    for (final pos in positions) {
      if (pos.index < minVisibleIndex) {
        minVisibleIndex = pos.index;
      }
    }

    final visibleMessages = _visibleMessages(thread);

    if (minVisibleIndex >= visibleMessages.length) return;

    final message = visibleMessages[minVisibleIndex];

    if (message.id == null) return;
 
    _repository.markConversationAsRead(
      widget.conversationId,
      message.id!,
    );
  }

  List<Message> _visibleMessages(ChatThreadState thread) {
    return thread.messages.reversed.toList(growable: false);
  }

  Future<void> _restoreInitialPosition() async {
    if (_initialPositionRestored || !mounted) return;
    _initialPositionRestored = true;
    _isRestoringInitialPosition = true;

    try {
      final targetId = widget.initialMessageReadId;
      final thread = _repository.threadFor(widget.conversationId);

      if (thread == null || thread.messages.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      var currentThread = _repository.threadFor(widget.conversationId);
      if (currentThread == null || currentThread.messages.isEmpty) {
        _scrollToBottom();
        return;
      }

      if (targetId == null) {
        _scrollToBottom();
        return;
      }

      while (currentThread != null) {
        final visibleMessages = _visibleMessages(currentThread);
        final targetIndex =
            visibleMessages.indexWhere((message) => message.id == targetId);

        if (targetIndex != -1) {
          await Future<void>.delayed(Duration.zero);

          if (_itemScrollController.isAttached) {
            await _itemScrollController.scrollTo(
              index: targetIndex,
              alignment: 0.25,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }

          return;
        }

        if (!currentThread.canLoadOlder) break;

        await Future.sync(() => _repository.loadOlder(widget.conversationId));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        currentThread = _repository.threadFor(widget.conversationId);
      }

      _scrollToBottom();
    } finally {
      _isRestoringInitialPosition = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!_itemScrollController.isAttached) return;

      _itemScrollController.jumpTo(index: 0);
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!_repository.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: 'Нет соединения с сервером',
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    _repository.sendMessage(
      widget.conversationId,
      text,
      senderId: widget.userId,
    );

    _controller.clear();
    _scrollToBottom();
  }

  void _toggleSelection(Message message, {bool isTap = false}) {
    if (isTap && !_isSelectionMode) return;

    if (!_isSelectionMode) {
      _isSelectionMode = true;
      _selectedMessages.clear();
      _selectedMessages.add(message);
    } else {
      if (_selectedMessages.contains(message)) {
        _selectedMessages.remove(message);
      } else {
        _selectedMessages.add(message);
      }

      if (_selectedMessages.isEmpty) {
        _isSelectionMode = false;
      }
    }

    setState(() {});
  }

  void _clearSelection() {
    _isSelectionMode = false;
    _selectedMessages.clear();
    setState(() {});
  }

  void _copySelectedMessages() {
    if (_selectedMessages.isEmpty) return;

    final sorted = _selectedMessages.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final text = sorted.map((m) => m.text).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    _clearSelection();
  }

  void _deleteSelectedMessages() {
    if (_selectedMessages.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      MySnackBar(
        text: 'Это не реализовано',
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  ConversationInfo? _conversationForCurrentChat() {
    for (final c in _repository.conversations) {
      if (c.id == widget.conversationId) return c;
    }
    return null;
  }

  List<UserInfo> _getReadByUsers(Message message) {
    final conversation = _conversationForCurrentChat();
    return conversation?.readByUsers(message, widget.userId) ?? <UserInfo>[];
  }

  ConversationInfo? _dialogConversation() {
    final conversation = _conversationForCurrentChat();
    if (conversation?.chatType == ChatType.dialog) return conversation;
    return null;
  }

  UserInfo? _dialogPartner() {
    final conversation = _dialogConversation();
    if (conversation == null) return null;

    final others = conversation.otherUsers(widget.userId);
    if (others.isEmpty) return null;
    return others.first;
  }

  UserInfo? _currentUserInfo() {
    final conversation = _conversationForCurrentChat();
    if (conversation == null) return null;

    final me = conversation.userInfoById(widget.userId);
    if (me != null) return me;

    if (conversation.usersInfo.isNotEmpty) {
      return conversation.usersInfo.first;
    }

    return null;
  }

  void _openConversationDetails() {
    final conversation = _conversationForCurrentChat();
    if (conversation == null) return;

    switch (conversation.chatType) {
      case ChatType.saved:
        final me = _currentUserInfo();
        if (me != null) {
          _openUserProfile(me);
        }
        return;
      case ChatType.dialog:
        final dialogPartner = _dialogPartner();
        if (dialogPartner != null) {
          _openUserProfile(dialogPartner);
        }
        return;
      case ChatType.group:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupInfoScreen(
              conversation: conversation,
              currentUserId: widget.userId,
            ),
          ),
        );
        return;
    }
  }

  void _openUserProfile(UserInfo user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(user: user, currentUserId: widget.userId),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  String _formatDate(DateTime date) {
    date = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return 'Сегодня';
    if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера';
    }

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<ChatRepository>();
    final thread = repo.threadFor(widget.conversationId);

    if (!_initialPositionRestored && thread?.messages.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _restoreInitialPosition();
      });
    }

    return GradientBackground(
      child: PopScope(
        canPop: !_isSelectionMode,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _isSelectionMode) {
            _clearSelection();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _isSelectionMode
              ? _buildSelectionAppBar(theme)
              : _buildNormalAppBar(theme),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: _buildBody(theme, thread),
                ),
                ChatInput(
                  controller: _controller,
                  onSend: _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildNormalAppBar(ThemeData theme) {
    final conversation = _conversationForCurrentChat();
    final titleWidget = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: conversation == null ? null : _openConversationDetails,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                conversation?.chatType == ChatType.group
                    ? Icons.group_outlined
                    : conversation?.chatType == ChatType.saved
                        ? Icons.bookmark_outline
                        : Icons.person_outline,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.chatName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.onSurface,
      centerTitle: true,
      title: titleWidget,
    );
  }

  AppBar _buildSelectionAppBar(ThemeData theme) {
    final canDelete = _selectedMessages.isNotEmpty &&
        _selectedMessages.every((message) => message.senderId == widget.userId);

    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      foregroundColor: theme.colorScheme.onSurface,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Закрыть',
        onPressed: _clearSelection,
      ),
      title: Text(
        '${_selectedMessages.length} выбрано',
        style: theme.textTheme.titleMedium,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Копировать',
          onPressed: _copySelectedMessages,
        ),
        if (canDelete)
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Удалить',
            onPressed: _deleteSelectedMessages,
          ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, ChatThreadState? thread) {
    if (thread == null || thread.isLoadingInitial) {
      return const LoadingIndicator(message: 'Загрузка сообщений...');
    }

    if (thread.errorMessage != null && thread.messages.isEmpty) {
      return ErrorView(
        error: thread.errorMessage!,
        onRetry: () {
          _repository.ensureThreadLoaded(
            widget.conversationId,
            force: true,
          );
        },
      );
    }

    if (thread.messages.isEmpty) {
      return const EmptyState(
        message: 'Сообщений пока нет.\nНапишите что-нибудь!',
        icon: Icons.chat_bubble_outline,
      );
    }

    final visibleMessages = _visibleMessages(thread);
    final showOlderLoader = thread.loadingOlder;

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      reverse: true,
      //keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: visibleMessages.length + (showOlderLoader ? 1 : 0),
      itemBuilder: (context, index) {
          if (showOlderLoader && index == visibleMessages.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final message = visibleMessages[index];
          final previousMessage = index < visibleMessages.length - 1 ? visibleMessages[index + 1] : null;

          final showDateHeader = previousMessage == null ||
              !_isSameDay(previousMessage.createdAt, message.createdAt);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDateHeader) _buildDateHeader(theme, message.createdAt),
              _buildMessageItem(theme, index, visibleMessages),
            ],
          );
        }
    );
  }

  Widget _buildDateHeader(ThemeData theme, DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatDate(date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(ThemeData theme, int index, List<Message> messages) {
    final message = messages[index];
    final isMine = message.senderId == widget.userId;

    final previousMessage =
        index < messages.length - 1 ? messages[index + 1] : null;
    final nextMessage = index > 0 ? messages[index - 1] : null;

    final showSenderName =
        !isMine && (previousMessage == null || previousMessage.senderId != message.senderId);

    final showAvatar =
        !isMine && (nextMessage == null || nextMessage.senderId != message.senderId);

    final isSelected = _selectedMessages.contains(message);
    final conv = _conversationForCurrentChat();
    final userInfo = conv?.userInfoById(message.senderId);

    Widget bubble = MessageBubble(
      isSended: message.id != null,
      text: message.text,
      isMine: isMine,
      timestamp: message.createdAt,
      readByUsers: _getReadByUsers(message),
      showReaded: conv?.chatType != ChatType.saved,
    );

    if (isMine) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _toggleSelection(message),
        onTap: () => _toggleSelection(message, isTap: true),
        onSecondaryTap: () => _toggleSelection(message),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: bubble,
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSenderName)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 4),
              child: Text(
                userInfo?.username ?? 'Неизвестный',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => _toggleSelection(message),
            onTap: () => _toggleSelection(message, isTap: true),
            onSecondaryTap: () => _toggleSelection(message),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: userInfo == null ? null : () => _openUserProfile(userInfo),
                      child: ImageLoader().loadImage(
                        userInfo?.avatarUrl,
                        userInfo?.id == 3 ? 64 : 32,
                        Center(
                          child: Text(
                            userInfo != null && userInfo.username.isNotEmpty
                                ? userInfo.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  else SizedBox(width: userInfo?.id == 3 ? 72 : 40),
                Expanded(child: bubble),
              ],
            ),
          ),
        ],
      );
    }
  }
}