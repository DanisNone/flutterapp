import 'package:flutter/material.dart';
import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/screens/chat_screen.dart';
import 'package:flutterapp/screens/group_create/select_participants_screen.dart';
import 'package:flutterapp/screens/search_users_screen.dart';
import 'package:flutterapp/service/api.dart' show getUser;
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/error_view.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:flutterapp/widgets/common/theme_toggle_button.dart';
import 'package:flutterapp/widgets/common/fab_menu.dart';
import 'package:flutterapp/widgets/conversations/conversation_card.dart';
import 'package:flutterapp/constants/app_colors.dart';

class ConversationsContent extends StatefulWidget {
  final JWTToken token;
  const ConversationsContent({super.key, required this.token});

  @override
  State<ConversationsContent> createState() => _ConversationsContentState();
}

class _ConversationsContentState extends State<ConversationsContent> 
    with AutomaticKeepAliveClientMixin<ConversationsContent> {
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

  void _navigateToSearchUsers() {
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
  }

  void _navigateToCreateGroup() {
    if (_user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectParticipantsScreen(
          token: widget.token,
          manager: manager,
          currentUsername: _user!.username,
        ),
      ),
    );
  }

  Widget _buildContent() {
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
        onButtonPressed: _navigateToSearchUsers,
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
    super.build(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Мои переписки'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          const ThemeToggleButton(),
        ],
      ),
      floatingActionButton: FabMenu(
        items: [
          FabMenuItem(
            icon: Icons.person_search,
            label: 'Найти пользователя',
            iconColor: AppColors.primary,
            onTap: _navigateToSearchUsers,
          ),
          FabMenuItem(
            icon: Icons.group_add,
            label: 'Создать группу',
            iconColor: AppColors.secondary,
            onTap: _navigateToCreateGroup,
          ),
        ],
        child: const SizedBox.shrink(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        backgroundColor: theme.colorScheme.surface,
        child: ResponsiveContainer(
          child: _buildContent()
        ),
      ),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}