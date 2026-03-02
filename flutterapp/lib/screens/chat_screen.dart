import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/service/user.dart';
import 'package:flutterapp/service/conversations.dart';

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
    _channel = WebSocketChannel.connect(Uri.parse(webSocketUrl).replace(
      queryParameters: {
        "token": widget.token.accessToken
      }
    ));

    
    _channel.stream.listen(
      (data) {
        final decoded = jsonDecode(data);
        final message = Message.fromJson(decoded);

        if (!mounted) return;

        setState(() {
          _messages.add(message);
        });

        _scrollToBottom();
      },
      onDone: () {
        setState(() => _isConnected = false);
      },
      onError: (error) {
        setState(() {
          _isConnected = false;
          _error = 'Ошибка сокета: $error';
        });
      },
    );

    setState(() => _isConnected = true);
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
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
        title: Text('Чат #${widget.conversationId}'),
        actions: [
          Icon(
            _isConnected ? Icons.circle : Icons.circle_outlined,
            color: _isConnected ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = message.senderId == _user!.id;

        return Align(
          alignment:
              isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: isMine ? Colors.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Введите сообщение...',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 4,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}