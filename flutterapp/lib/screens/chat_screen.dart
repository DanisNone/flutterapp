import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:flutterapp/service/user.dart';
import 'package:flutterapp/service/conversations.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/error_view.dart';
import 'package:flutterapp/widgets/chat/message_bubble.dart';
import 'package:flutterapp/widgets/chat/chat_input.dart';
import 'package:flutterapp/widgets/common/connection_status.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final JWTToken token;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.token,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  User? _user;
  List<Message> _messages = [];

  late WebSocketChannel _channel;
  bool _isConnected = false;
  bool _isLoading = true;
  String? _error;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await getUser(widget.token);
      final history = await getConversationMessages(
        widget.conversationId,
        widget.token,
      );

      if (!mounted) return;

      setState(() {
        _user = user;
        _messages = history;
        _isLoading = false;
      });

      _connectSocket();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  void _connectSocket() {
    try {
      final uri = Uri.parse(webSocketUrl).replace(
        queryParameters: {"token": widget.token.accessToken},
      );
      
      _channel = WebSocketChannel.connect(uri);

      _channel.stream.listen(
        _handleIncomingMessage,
        onDone: _handleConnectionClosed,
        onError: _handleConnectionError,
      );

      setState(() => _isConnected = true);
    } catch (e) {
      setState(() {
        _isConnected = false;
        _error = 'Ошибка подключения: $e';
      });
    }
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      final decoded = jsonDecode(data);
      final message = Message.fromJson(decoded);

      if (!mounted) return;

      if (message.conversationId == widget.conversationId) {
        setState(() {
          _messages.add(message);
        });

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  void _handleConnectionClosed() {
    if (mounted) {
      setState(() => _isConnected = false);
      
      // Показываем уведомление о разрыве соединения
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Соединение разорвано'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Пытаемся переподключиться через 3 секунды
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _connectSocket();
        }
      });
    }
  }

  void _handleConnectionError(error) {
    if (mounted) {
      setState(() {
        _isConnected = false;
        _error = 'Ошибка сокета: $error';
      });
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isConnected) return;

    final payload = jsonEncode({
      "conversation_id": widget.conversationId,
      "text": text,
    });

    _channel.sink.add(payload);
    _controller.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _tryReconnect() {
    setState(() {
      _error = null;
    });
    _connectSocket();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Чат #${widget.conversationId}',
              style: const TextStyle(fontSize: 16),
            ),
            ConnectionStatus(isConnected: _isConnected),
          ],
        ),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _tryReconnect,
              tooltip: 'Переподключиться',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(),
          ),
          ChatInput(
            controller: _controller,
            onSend: _sendMessage,
            isConnected: _isConnected,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Загрузка сообщений...');
    }

    if (_error != null) {
      return ErrorView(
        error: _error!,
        onRetry: _tryReconnect,
      );
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
          final isMine = message.senderId == _user!.id;

          return MessageBubble(
            text: message.text,
            isMine: isMine,
            timestamp: message.createdAt,
          );
        },
      ),
    );
  }
}
