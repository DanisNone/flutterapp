import 'package:flutter/material.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/service/conversations.dart';
import 'package:flutterapp/service/image_loader_service.dart';
import 'package:flutterapp/service/user.dart' as user_service;
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/constants/app_text_styles.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:flutterapp/screens/chat_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  final JWTToken token;
  final ChatManager manager;
  final User currentUser;

  const SearchUsersScreen({
    super.key,
    required this.token,
    required this.manager,
    required this.currentUser,
  });

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await user_service.searchUsers(widget.token, query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ошибка поиска: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _createConversationWithUser(User otherUser) async {
    if (otherUser.id == widget.currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: 'Нельзя начать переписку с собой',
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: LoadingIndicator()),
      );

      final (conversationId, alreadyExists) = await getOrCreateDialog(
        widget.currentUser,
        otherUser.username,
        widget.token,
      );

      if (!mounted) return;
      Navigator.pop(context); // закрыть индикатор

      widget.manager.loadConversations(); // обновить список переписок

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            userId: widget.currentUser.id,
            chatName: otherUser.username,
            token: widget.token,
            manager: widget.manager,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(text: 'Ошибка создания: $e', backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Поиск пользователей'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
        body: ResponsiveContainer(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Введите имя пользователя...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceDark.withValues(alpha: 0.5),
                  ),
                  onChanged: _searchUsers,
                ),
              ),
              if (_isSearching)
                const Expanded(child: Center(child: LoadingIndicator()))
              else if (_errorMessage != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: AppTextStyles.bodyMedium),
                        ElevatedButton(
                          onPressed: () => _searchUsers(_searchController.text),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Пользователи не найдены'),
                  ),
                )
              else if (_searchResults.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Начните поиск'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: ImageLoader().loadImage(
                          user.avatarUrl,
                          40,
                          const Icon(Icons.person),
                        ),
                        title: Text(user.username),
                        subtitle: Text(user.fullName),
                        onTap: () => _createConversationWithUser(user),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}