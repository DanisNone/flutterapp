import 'package:flutter/material.dart';
import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/screens/chat_screen.dart';
import 'package:flutterapp/screens/main/profile_content.dart';
import 'package:flutterapp/screens/search_users_screen.dart';
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/service/image_loader_service.dart';
import 'package:flutterapp/service/user.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/error_view.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:flutterapp/widgets/common/theme_toggle_button.dart';
import 'package:flutterapp/widgets/conversations/conversation_card.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/theme/app_theme.dart';

class ConversationsContent extends StatefulWidget {
  final JWTToken token;
  const ConversationsContent({super.key, required this.token});

  @override
  State<ConversationsContent> createState() => _ConversationsContentState();
}

class _ConversationsContentState extends State<ConversationsContent> {
  User? _user;
  List<ConversationInfo>? _conversations;
  bool _isLoading = false;
  String? _errorMessage;
  final ChatManager manager = ChatManager();

  @override
  void initState() {
    super.initState();
    manager.setToken(widget.token);
    manager.addListener(
      ChatListener(
        newMessage: _lastMessageUpdate,
        conversations: (c) {
          setState(() {
            _conversations = c;
          });
        },
      ),
    );
    _loadConversations();
  }

  void _lastMessageUpdate(Message message) {
    if (_conversations == null) return;
    for (int i = 0; i < _conversations!.length; i++) {
      if (_conversations![i].id != message.conversationId) {
        continue;
      }
      ConversationInfo conv = _conversations!.removeAt(i);
      conv.lastMessage = message.text;
      conv.lastUpdate = DateTime.now().toUtc();
      _conversations!.insert(0, conv);
      setState(() {});
      return;
    }
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await getUser(widget.token);
      manager.loadConversations();
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _loadConversations();
  }

  Widget _buildUserInfo() {
    if (_user == null) return const SizedBox();
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileContent(token: widget.token),
          ),
        );
      },
      child: MyContainer(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        borderRadius: 16,
        opacity: 0.06,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        child: Row(
          children: [
            ImageLoader().loadImage(
              _user!.avatarUrl,
              48,
              Icon(
                Icons.person,
                color: theme.colorScheme.onSurfaceVariant,
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _user!.username,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: AppDimensions.iconM,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Мои переписки', style: theme.textTheme.headlineSmall),
        if (!_isLoading && _conversations != null && _conversations!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingXS,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            ),
            child: Text(
              '${_conversations!.length}',
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
    final theme = Theme.of(context);
    if (_conversations == null || _isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: LoadingIndicator(message: 'Загрузка переписок...'),
      );
    }
    if (_errorMessage != null) {
      return ErrorView(error: _errorMessage!, onRetry: _refresh);
    }
    if (_conversations!.isEmpty) {
      return EmptyState(
        message: 'У вас пока нет переписок',
        icon: Icons.chat_bubble_outline,
        buttonText: 'Создать первую',
        onButtonPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchUsersScreen(
              token: widget.token,
              manager: manager,
              currentUser: _user!,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _conversations!.length,
      itemBuilder: (context, index) {
        final info = _conversations![index];
        final id = info.id;
        return ConversationCard(
          info: info,
          currentUserId: _user!.id,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: id,
                  userId: _user!.id,
                  chatName: info.getName(_user!.id),
                  token: widget.token,
                  manager: manager,
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Мои переписки'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        // foregroundColor is handled by theme, but ensuring contrast
        foregroundColor: theme.colorScheme.onSurface, 
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Обновить',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_user == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SearchUsersScreen(
                token: widget.token,
                manager: manager,
                currentUser: _user!,
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        backgroundColor: theme.colorScheme.surface,
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.paddingM),
              _buildUserInfo(),
              const SizedBox(height: AppDimensions.paddingXL),
              _buildHeader(),
              const SizedBox(height: AppDimensions.paddingL),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }
}