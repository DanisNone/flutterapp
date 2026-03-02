import 'package:flutter/material.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/screens/chat_screen.dart';
import 'package:flutterapp/service/conversations.dart';
import 'package:flutterapp/service/user.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/error_view.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:flutterapp/widgets/conversations/conversation_card.dart';
import 'package:flutterapp/widgets/conversations/create_conversation_sheet.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/utils/responsive.dart';

class ConversationsScreen extends StatefulWidget {
  final JWTToken token;

  const ConversationsScreen({
    super.key,
    required this.token,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  User? _user;
  List<int> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Кэш для последних сообщений (можно заменить на реальные данные из API)
  final Map<int, String> _lastMessages = {};
  final Map<int, DateTime> _lastMessageTimes = {};

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await getUser(widget.token);
      final convs = await getAllUserConversations(user, widget.token);

      if (!mounted) return;

      setState(() {
        _user = user;
        _conversations = convs;
        _isLoading = false;
      });
      
      // Загружаем последние сообщения для каждой переписки
      _loadLastMessages();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLastMessages() async {
    // Здесь можно загрузить последние сообщения для каждой переписки
    // Пока оставим заглушку
    for (final id in _conversations) {
      _lastMessages[id] = 'Последнее сообщение...';
      _lastMessageTimes[id] = DateTime.now().subtract(Duration(minutes: id));
    }
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    await _loadConversations();
  }

  void _openCreateConversationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
      ),
      builder: (context) => CreateConversationSheet(
        onCreate: _createConversation,
      ),
    );
  }

  Future<void> _createConversation(int otherUserId) async {
    if (_user == null) return;

    Navigator.pop(context); // Закрываем bottom sheet

    try {
      final (conversationId, alreadyExists) = await getOrCreateDialog(
        _user!,
        otherUserId,
        widget.token,
      );

      if (!mounted) return;

      final message = alreadyExists
          ? 'Переписка уже существует'
          : 'Переписка создана';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$message (ID: $conversationId)'),
          backgroundColor: alreadyExists ? Colors.orange : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _refresh();

      if (!mounted) return;
      
      // Плавный переход в чат
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            token: widget.token,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildUserInfo() {
    if (_user == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: AppDimensions.iconM,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Пользователь',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _user!.username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Мои переписки',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!_isLoading && _conversations.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            ),
            child: Text(
              '${_conversations.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: LoadingIndicator(message: 'Загрузка переписок...'),
      );
    }

    if (_errorMessage != null) {
      return ErrorView(
        error: _errorMessage!,
        onRetry: _refresh,
      );
    }

    if (_conversations.isEmpty) {
      return EmptyState(
        message: 'У вас пока нет переписок',
        icon: Icons.chat_bubble_outline,
        buttonText: 'Создать первую',
        onButtonPressed: _openCreateConversationSheet,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final id = _conversations[index];

        return ConversationCard(
          id: id,
          lastMessage: _lastMessages[id],
          lastMessageTime: _lastMessageTimes[id],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: id,
                  token: widget.token,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои переписки'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Обновить',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateConversationSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.paddingM),
              _buildUserInfo(),
              const SizedBox(height: AppDimensions.paddingXL),
              _buildHeader(),
              const SizedBox(height: AppDimensions.paddingL),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
