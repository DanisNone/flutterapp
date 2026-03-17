import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/service/user.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/chat/message_bubble.dart';
import 'package:flutterapp/widgets/chat/chat_input.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/constants/app_text_styles.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';

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

  // Состояние выделения
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
          backgroundColor: AppColors.warning,
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
    final text = _selectedMessages.map((m) => m.text).join('\n\n');
    Clipboard.setData(ClipboardData(text: text));
    _clearSelection();
  }

  void _deleteSelectedMessages() {
    if (_selectedMessages.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      MySnackBar(
        text: 'Это не реализовано',
        backgroundColor: AppColors.warning,
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
    return GradientBackground(
      child: PopScope(
        canPop: !_isSelectionMode,
        onPopInvokedWithResult: (bool didPop, dynamic) {
          if (!didPop && _isSelectionMode) {
            _clearSelection();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
          body: Column(
            children: [
              Expanded(child: _buildBody()),
              ChatInput(controller: _controller, onSend: _sendMessage),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSolid,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(widget.chatName, style: AppTextStyles.title),
      ),
      centerTitle: true,
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.toolbarBackground,
      foregroundColor: AppColors.textPrimary,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text(
        '${_selectedMessages.length} выбрано',
        style: AppTextStyles.title,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: _copySelectedMessages,
        ),
        if (_selectedMessages.every((message) => message.senderId == _user!.id)) IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _deleteSelectedMessages,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading || _messages == null) {
      return const LoadingIndicator(message: 'Загрузка сообщений...');
    }

    if (_messages!.isEmpty) {
      return EmptyState(
        message: 'Сообщений пока нет.\nНапишите что-нибудь!',
        icon: Icons.chat_bubble_outline,
      );
    }

    final messagesList = _messages!.toList();

    return Container(
      color: Colors.transparent,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        itemCount: messagesList.length,
        itemBuilder: (context, index) {
          final message = messagesList[messagesList.length - 1 - index];
          final isMine = _user != null && message.senderId == _user!.id;

          bool showDateHeader = false;
          if (index == messagesList.length - 1) {
            showDateHeader = true;
          } else {
            final previousMessage =
                messagesList[messagesList.length - index - 2];
            if (!_isSameDay(previousMessage.createdAt, message.createdAt)) {
              showDateHeader = true;
            }
          }

          List<Widget> children = [];
          if (showDateHeader) {
            children.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSolid,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDate(message.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondarySolid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          children.add(
            GestureDetector(
              onLongPress: () => _toggleSelection(message), // телефон
              onTap: () => _toggleSelection(message, isTap: true), // выбор нескольких
              onSecondaryTap: () => _toggleSelection(message), // для ПК
              child: Container(
                decoration: _selectedMessages.contains(message)
                    ? BoxDecoration(
                        color: AppColors.messageSelected,
                        border: Border.all(
                          color: AppColors.messageSelectedBorder,
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
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        },
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
