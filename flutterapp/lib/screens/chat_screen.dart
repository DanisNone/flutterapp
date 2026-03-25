import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterapp/model/chat_thread_state.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/service/chat_repository.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/error_view.dart';
import 'package:flutterapp/widgets/chat/message_bubble.dart';
import 'package:flutterapp/widgets/chat/chat_input.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final int userId;
  final String chatName;
  final JWTToken token;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.chatName,
    required this.userId,
    required this.token
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatRepository _repository;
  bool _initialized = false;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<Message> _selectedMessages = {};

  bool _isSelectionMode = false;
  bool _initialScrollScheduled = false;
  bool _paginationArmed = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    _repository = context.read<ChatRepository>();
    _repository.setToken(widget.token);
    _repository.ensureThreadLoaded(widget.conversationId);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final thread = _repository.threadFor(widget.conversationId);
    if (thread == null || !thread.canLoadOlder) {
      _paginationArmed = true;
      return;
    }

    final nearTop = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;

    if (!nearTop) {
      _paginationArmed = true;
      return;
    }

    if (!_paginationArmed) return;

    _paginationArmed = false;
    _repository.loadOlder(widget.conversationId);
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    });
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<ChatRepository>();
    final thread = repo.threadFor(widget.conversationId);

    if (!_initialScrollScheduled && thread?.messages.isNotEmpty == true) {
      _initialScrollScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom();
        }
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
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.onSurface,
      centerTitle: true,
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.chatName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ),
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

    final messages = thread.messages;
    final showOlderLoader = thread.loadingOlder;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: messages.length + (showOlderLoader ? 1 : 0),
      itemBuilder: (context, index) {
        if (showOlderLoader && index == messages.length) {
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

        final message = messages[messages.length - 1 - index];
        final previousMessage = index < messages.length - 1
            ? messages[messages.length - index - 2]
            : null;

        final showDateHeader = previousMessage == null ||
            !_isSameDay(previousMessage.createdAt, message.createdAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateHeader) _buildDateHeader(theme, message.createdAt),
            _buildMessageItem(theme, message),
          ],
        );
      },
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

  Widget _buildMessageItem(ThemeData theme, Message message) {
    final isMine = message.senderId == widget.userId;
    final isSelected = _selectedMessages.contains(message);

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
        child: MessageBubble(
          isSended: message.id != null,
          text: message.text,
          isMine: isMine,
          timestamp: message.createdAt,
        ),
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
    if (messageDate == today.subtract(const Duration(days: 1))) return 'Вчера';

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}