import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/service/image_loader_service.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:flutterapp/screens/group_create/create_group_details_screen.dart';

class SelectParticipantsScreen extends StatefulWidget {
  final JWTToken token;
  final ChatManager manager;
  final String currentUsername;

  const SelectParticipantsScreen({
    super.key,
    required this.token,
    required this.manager,
    required this.currentUsername,
  });

  @override
  State<SelectParticipantsScreen> createState() =>
      _SelectParticipantsScreenState();
}

class _SelectParticipantsScreenState extends State<SelectParticipantsScreen> {
  final _searchController = TextEditingController();
  final List<UserInfo> _selectedUsers = [];
  List<UserInfo> _searchResults = [];

  bool _isSearching = false;
  String? _lastQuery;
  ChatListener? _listener;

  @override
  void initState() {
    super.initState();

    _listener = ChatListener(
      onSearchResult: (query, users) {
        if (!mounted) return;
        if (query != _lastQuery) return;

        setState(() {
          _searchResults = users
              .where(
                (u) => u.username != widget.currentUsername &&
                    !_selectedUsers.any((s) => s.id == u.id),
              )
              .toList();
          _isSearching = false;
        });
      },
      error: (error) {
        if (!mounted) return;
        setState(() => _isSearching = false);
        _showError('Ошибка поиска: $error');
      },
    );

    widget.manager.addListener(_listener!);
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_listener != null) {
      widget.manager.removeListener(_listener!);
    }
    super.dispose();
  }

  void _searchUsers(String query) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _lastQuery = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _lastQuery = trimmed;
    });

    widget.manager.searchUsers(trimmed);
  }

  void _toggleUserSelection(UserInfo user) {
    setState(() {
      if (_selectedUsers.any((u) => u.id == user.id)) {
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUsers.add(user);
      }

      _searchController.clear();
      _searchResults = [];
      _isSearching = false;
      _lastQuery = null;
    });
  }

  void _removeSelectedUser(UserInfo user) {
    setState(() {
      _selectedUsers.removeWhere((u) => u.id == user.id);
    });
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      MySnackBar(
        text: text,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _next() {
    if (_selectedUsers.isEmpty) {
      _showError('Добавьте хотя бы одного участника');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupDetailsScreen(
          token: widget.token,
          manager: widget.manager,
          currentUsername: widget.currentUsername,
          selectedUsers: _selectedUsers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Выбор участников'),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          titleSpacing: 12,
          toolbarHeight: 56,
        ),
        body: SafeArea(
          child: ResponsiveContainer(
            child: Column(
              children: [
                if (_selectedUsers.isNotEmpty)
                  _buildSelectedUsersSection(theme),
                _buildSearchSection(theme),
                Expanded(
                  child: _buildResultsSection(theme),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomButton(context),
      ),
    );
  }

  Widget _buildSelectedUsersSection(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedUsers.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final user = _selectedUsers[index];
            return Chip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: CircleAvatar(
                radius: 12,
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
              ),
              label: Text(user.username),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _removeSelectedUser(user),
              backgroundColor: isDark
                  ? AppColors.surfaceLight
                  : AppColors.surfaceLightThemeContainer,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск пользователей...',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
        ),
        onChanged: _searchUsers,
      ),
    );
  }

  Widget _buildResultsSection(ThemeData theme) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    if (_isSearching) {
      return const Center(child: LoadingIndicator());
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(theme, hasQuery);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _searchResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserTile(theme, user);
      },
    );
  }

  Widget _buildUserTile(ThemeData theme, UserInfo user) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: ImageLoader().loadImage(
          user.avatarUrl,
          40,
          Icon(
            Icons.person,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(user.username),
        subtitle: Text(
          user.fullName ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.add_circle,
            color: AppColors.primary,
          ),
          onPressed: () => _toggleUserSelection(user),
        ),
        onTap: () => _toggleUserSelection(user),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool hasQuery) {
    final text = hasQuery
        ? 'Ничего не найдено'
        : (_selectedUsers.isEmpty
            ? 'Найдите и добавьте участников'
            : 'Добавьте ещё участников');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        const SizedBox(height: 56),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasQuery ? Icons.search_off : Icons.group_add,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SizedBox(
          width: double.infinity,
          child: NeonButton(
            onPressed: _next,
            child: const Text('Далее'),
          ),
        ),
      ),
    );
  }
}