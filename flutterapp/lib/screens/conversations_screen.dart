import 'package:flutter/material.dart';
import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/screens/auth/login_screen.dart';
import 'package:flutterapp/screens/chat_screen.dart';
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/service/conversations.dart';
import 'package:flutterapp/service/secure_storage.dart';
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
import 'package:flutterapp/constants/app_text_styles.dart';
import 'package:flutterapp/theme/app_theme.dart';

class ConversationsScreen extends StatefulWidget {
  final JWTToken token;

  const ConversationsScreen({super.key, required this.token});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
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

  void _lastMessageUpdate(Message message, bool isNew) {
    if (!isNew || _conversations == null) return;

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

  void _openCreateConversationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 24,
        opacity: 0.08,
        border: Border.all(color: AppColors.borderGlow, width: 1.5),
        child: CreateConversationSheet(onCreate: _createConversation),
      ),
    );
  }

  Future<void> _createConversation(int otherUserId) async {
    if (_user == null) return;

    Navigator.pop(context);

    try {
      final (conversationId, alreadyExists, otherUsername) = await getOrCreateDialog(
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
          backgroundColor: alreadyExists
              ? AppColors.warning
              : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await _refresh();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            userId: _user!.id,
            chatName: otherUsername,
            token: widget.token,
            manager: manager,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildUserInfo() {
    if (_user == null) return const SizedBox();

    return GlassContainer(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      borderRadius: 16,
      opacity: 0.06,
      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
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
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  _user!.username,
                  style: AppTextStyles.bodyLarge.copyWith(
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
        Text('Мои переписки', style: AppTextStyles.headline3),
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
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
        onButtonPressed: _openCreateConversationSheet,
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
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Мои переписки'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Обновить',
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                SecureStorageService().deleteJWTToken();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const GradientBackground(child: LoginScreen()),
                  ),
                  (route) => false,
                );
              },
              tooltip: 'Выход',
            ),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _openCreateConversationSheet,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceDark,
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
      ),
    );
  }
}
