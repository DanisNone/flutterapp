import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/service/api.dart' show getUser;
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/chat/message_bubble.dart';
import 'package:flutterapp/widgets/chat/chat_input.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';
import 'package:flutterapp/constants/app_dimensions.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final int userId;
  final String chatName;
  final JWTToken token;
  final ChatManager manager;
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.chatName,
    required this.userId,
    required this.token,
    required this.manager,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  User? _user;
  List<Message>? _messages;
  bool _isLoading = true;
  late ChatListener _listener;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<Message> _selectedMessages = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    widget.manager.setToken(widget.token);
    _listener = ChatListener(
      newMessage: _handleIncomingMessage,
      loadMessages: _handleLoadMessage,
    );
    _scrollController.addListener(_onScroll);
    widget.manager.addListener(_listener);
    _init();
  }

  Future<void> _init() async {
    late User user;
    while (true) {
      try {
        user = await getUser(widget.token);
        widget.manager.loadLast(widget.conversationId);
        break;
      } catch (e) {
        if (!mounted) return;
      }
    }
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _handleIncomingMessage(Message message) {
    if (_messages != null &&
        _messages!.isNotEmpty &&
        _messages!.first.id == message.id) {
      return;
    }
    try {
      if (!mounted) return;
      if (message.conversationId == widget.conversationId) {
        setState(() {
          _messages ??= [];
          if (message.senderId != _user?.id) {
            _messages!.add(message);
          } else {
            bool find = false;
            for (var userMessage in _messages!) {
              if (userMessage.id == null && userMessage.text == message.text) {
                userMessage.id = message.id;
                userMessage.createdAt = message.createdAt;
                find = true;
                break;
              }
            }
            if (!find) {
              _messages!.add(message);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  void _handleLoadMessage(List<Message> messages) {
    _messages ??= [];
    for (var message in messages) {
      if (_messages!.isEmpty || _messages!.first.id != message.id) {
        _messages!.insert(0, message);
      }
    }
    setState(() {});
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!widget.manager.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: 'Нет соединения с сервером',
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    setState(() {
      _messages ??= [];
      _messages!.add(
        Message(
          id: null,
          text: text,
          senderId: widget.userId,
          createdAt: DateTime.now().toUtc(),
          conversationId: widget.conversationId,
        ),
      );
      _scrollToBottom();
    });
    widget.manager.sendMessage(widget.conversationId, text);
    _controller.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final min = _scrollController.position.minScrollExtent;
        _scrollController.jumpTo(min);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (_messages != null && _messages!.isNotEmpty) {
        final oldestMessage = _messages!.first;
        widget.manager.loadBefore(oldestMessage);
      }
    }
  }

  void _toggleSelection(Message message, {bool isTap = false}) {
    if (isTap && !_isSelectionMode) {
      return;
    }
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
    final text = _selectedMessages.map((m) => m.text).join('\n');
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
    widget.manager.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  child: _buildBody(theme),
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
    final canDelete = _user != null &&
        _selectedMessages.isNotEmpty &&
        _selectedMessages.every((message) => message.senderId == _user!.id);

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

  Widget _buildBody(ThemeData theme) {
    if (_isLoading || _messages == null) {
      return const LoadingIndicator(message: 'Загрузка сообщений...');
    }

    if (_messages!.isEmpty) {
      return const EmptyState(
        message: 'Сообщений пока нет.\nНапишите что-нибудь!',
        icon: Icons.chat_bubble_outline,
      );
    }

    final messages = _messages!;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        final previousMessage = index < messages.length - 1
            ? messages[messages.length - index - 2]
            : null;

        final showDateHeader =
            previousMessage == null || !_isSameDay(previousMessage.createdAt, message.createdAt);

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
    final isMine = _user != null && message.senderId == _user!.id;
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
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    date = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    if (messageDate == today) return 'Сегодня';
    if (messageDate == today.subtract(const Duration(days: 1))) return 'Вчера';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
