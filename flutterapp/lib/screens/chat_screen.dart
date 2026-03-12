import 'package:flutter/material.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/service/user.dart';
import 'package:flutterapp/service/conversations.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/chat/message_bubble.dart';
import 'package:flutterapp/widgets/chat/chat_input.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';

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
  List<Message> _messages = [];
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

    widget.manager.addListener(_listener);

    _init();
  }

  Future<void> _init() async 
  {
    late User user;
    late List<Message> history;
    while (true) {
      try {
        user = await getUser(widget.token);
        history = await getConversationMessages(
          widget.conversationId,
          widget.token,
        );
        break;
      } catch (e) {
        if (!mounted) return;
      }
    }

    if (!mounted) return;

    setState(() {
      _user = user;
      _messages = history;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _handleIncomingMessage(Message message) {
    try {
      if (!mounted) return;

      if (message.conversationId == widget.conversationId) {
        setState(() {
          if (message.senderId != _user!.id) {
            _messages.add(message);
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
              _messages.add(message);
            }
          }
        });

        _scrollToBottom();
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
        const SnackBar(
          content: Text('Нет соединения с сервером'),
          duration: Duration(seconds: 2),
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
        final max = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    widget.manager.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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

    return Container(
      color: Colors.grey.shade50,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isMine = _user != null && message.senderId == _user!.id;

          return MessageBubble(
            isSended: message.id != null,
            text: message.text,
            isMine: isMine,
            timestamp: message.createdAt,
          );
        },
      ),
    );
  }
}