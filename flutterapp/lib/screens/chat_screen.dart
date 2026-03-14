import 'dart:collection';

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

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final int userId;
  final JWTToken token;
  final ChatManager manager;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.userId,
    required this.token,
    required this.manager,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  User? _user;
  final List<Message> _messages = [];
  bool _isLoading = true;
  late ChatListener _listener;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.manager.setToken(widget.token);

    _listener = ChatListener(
      newMessage: _handleIncomingMessage,
    );
    _scrollController.addListener(_onScroll);

    widget.manager.addListener(_listener);

    _init();
  }

  Future<void> _init() async 
  {
    late User user;
    while (true) {
      try {
        user = await getUser(widget.token);
        widget.manager.loadLast(
          widget.conversationId
        );
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

  void _handleIncomingMessage(Message message, bool isNew) {
    if (_messages.isNotEmpty && _messages.first.id == message.id) return;
    try {
      if (!mounted) return;

      if (message.conversationId == widget.conversationId) {
        setState(() {
          if (message.senderId != _user!.id) {
            if (isNew) {_messages.add(message);}
            else {_messages.insert(0, message);}
          }
          else {
            bool find = false;
            for (var userMessage in _messages) {
              if (userMessage.id == null && userMessage.text == message.text) {
                userMessage.id = message.id;
                userMessage.createdAt = message.createdAt;
                find = true;
                break;
              }
            }
            if (!find) {
              if (isNew) {_messages.add(message);}
              else {_messages.insert(0, message);}
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!widget.manager.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Нет соединения с сервером'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    setState(() {
      _messages.add(Message(
        id: null,
        text: text,
        senderId: widget.userId,
        createdAt: DateTime.now().toUtc(),
        conversationId: widget.conversationId
      ));
      _scrollToBottom();
    });

    widget.manager.sendMessage(
      widget.conversationId,
      text,
    );

    _controller.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final min = _scrollController.position.minScrollExtent;
        _scrollController.jumpTo(
          min
        );
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (_messages.isNotEmpty) {
        final oldestMessage = _messages.first;
        widget.manager.loadBefore(oldestMessage);
      }
    }
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          title: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 12,
            opacity: 0.04,
            child: Text(
              'Беседа #${widget.conversationId}',
              style: AppTextStyles.title,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: _buildBody(),
            ),
            ChatInput(
              controller: _controller,
              onSend: _sendMessage
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return GlassContainer(
          borderRadius: 24,
          opacity: 0.08,
          border: Border.all(
            color: AppColors.borderGlow,
            width: 1.5,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.copy, color: AppColors.textSecondary),
                  title: Text('Копировать', style: AppTextStyles.bodyLarge),
                  onTap: () {
                    Navigator.pop(context);
                    _copyMessage(message);
                  },
                ),
                if (message.senderId == _user?.id)
                  ListTile(
                    leading: const Icon(Icons.delete, color: AppColors.error),
                    title: Text('Удалить', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteMessage(message);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copyMessage(Message message) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Сообщение скопировано'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _deleteMessage(Message message) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Это не реализовано'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Загрузка сообщений...');
    }

    if (_messages.isEmpty) {
      return EmptyState(
        message: 'Сообщений пока нет.\nНапишите что-нибудь!',
        icon: Icons.chat_bubble_outline,
      );
    }

    final messagesList = _messages.toList();

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
            final previousMessage = messagesList[messagesList.length - index - 2];
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
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    borderRadius: 20,
                    opacity: 0.04,
                    child: Text(
                      _formatDate(message.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
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
              onLongPress: () => _showMessageOptions(context, message),
              child: MessageBubble(
                isSended: message.id != null,
                text: message.text,
                isMine: isMine,
                timestamp: message.createdAt,
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return 'Сегодня';
    if (messageDate == today.subtract(const Duration(days: 1))) return 'Вчера';

    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
