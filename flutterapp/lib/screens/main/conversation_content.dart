import 'package:flutter/material.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/screens/chat_screen.dart';
import 'package:flutterapp/screens/group_create/select_participants_screen.dart';
import 'package:flutterapp/screens/search_users_screen.dart';
import 'package:flutterapp/service/api.dart' show getOrCreateSaved, getUser;
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/service/chat_repository.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/error_view.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:flutterapp/widgets/common/theme_toggle_button.dart';
import 'package:flutterapp/widgets/common/fab_menu.dart';
import 'package:flutterapp/widgets/conversations/conversation_card.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:provider/provider.dart';

class ConversationsContent extends StatefulWidget {
  final JWTToken token;
  const ConversationsContent({super.key, required this.token});

  @override
  State<ConversationsContent> createState() => _ConversationsContentState();
}

class _ConversationsContentState extends State<ConversationsContent>
    with AutomaticKeepAliveClientMixin<ConversationsContent> {
  User? _user;
  String? _userError;
  bool _userLoading = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final repo = context.read<ChatRepository>();
    repo.setToken(widget.token);

    if (!repo.conversationsLoaded) {
      repo.loadConversations();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await getUser(widget.token);
      if (!mounted) return;
      setState(() {
        _user = user;
        _userLoading = false;
        _userError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userError = 'Ошибка загрузки профиля: $e';
        _userLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final repo = context.read<ChatRepository>();
    await repo.loadConversations(force: true);
  }

  Future<void> _openSavedMessages() async {
    if (_user == null) return;


    try {
      final (conversationId, exists) = await getOrCreateSaved(
        _user!,
        widget.token
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            userId: _user!.id,
            chatName: 'Избранное',
            token: widget.token,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _navigateToSearchUsers() {
    if (_user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchUsersScreen(
          token: widget.token,
          manager: context.read<ChatManager>(),
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
          manager: context.read<ChatManager>(),
          currentUsername: _user!.username,
        ),
      ),
    );
  }

  Widget _buildContent(ChatRepository repo) {
    if (_userLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: LoadingIndicator(message: 'Загрузка профиля...'),
      );
    }

    if (_userError != null) {
      return ErrorView(
        error: _userError!,
        onRetry: _loadCurrentUser,
      );
    }

    if (repo.conversationsLoading &&
        repo.conversations.isEmpty &&
        !repo.conversationsLoaded) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: LoadingIndicator(message: 'Загрузка переписок...'),
      );
    }

    if (repo.conversationsError != null && repo.conversations.isEmpty) {
      return ErrorView(
        error: repo.conversationsError!,
        onRetry: _refresh,
      );
    }

    if (repo.conversations.isEmpty) {
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
      itemCount: repo.conversations.length,
      itemBuilder: (context, index) {
        final info = repo.conversations[index];
        final id = info.id;

        return ConversationCard(
          info: info,
          currentUserId: _user!.id,
            onTap: () {
              final myInfo = info.userInfoById(_user!.id);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversationId: id,
                    userId: _user!.id,
                    chatName: info.getName(_user!.id),
                    token: widget.token,
                    initialMessageReadId: myInfo?.lastMessageReadId,
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
    final repo = context.watch<ChatRepository>();

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
          FabMenuItem(
            icon: Icons.bookmark,
            label: 'Избранное',
            iconColor: Colors.amber,
            onTap: _openSavedMessages,
          ),
        ],
        child: const SizedBox.shrink(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        backgroundColor: theme.colorScheme.surface,
        child: ResponsiveContainer(
          child: _buildContent(repo),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}