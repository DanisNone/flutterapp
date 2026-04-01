import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/screens/user_profile_screen.dart';
import 'package:flutterapp/service/api.dart' as api;
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/service/follower_service.dart';
import 'package:flutterapp/service/image_loader_service.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/error_view.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:provider/provider.dart';

class SearchUsersScreen extends StatefulWidget {
  final ChatManager manager;
  final User currentUser;
  const SearchUsersScreen({
    super.key,
    required this.manager,
    required this.currentUser,
  });

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<UserInfo> _results = <UserInfo>[];
  bool _isLoading = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 240) {
        // TODO: Search is page-less from the user's perspective; keep the hook for future expansion.
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    setState(() {
      _query = value;
    });

    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = <UserInfo>[];
        _error = null;
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await api.searchUsers(query, limit: 30);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openUserProfile(UserInfo user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          user: user,
          currentUserId: widget.currentUser.id,
        ),
      ),
    );
  }

  String _initials(String username) {
    final parts = username
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _scheduleSearch,
        decoration: InputDecoration(
          hintText: 'Поиск пользователей...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.60),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _scheduleSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingM,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, bool isFollowing) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isFollowing
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Text(
        isFollowing ? 'Подписаны' : 'Не подписаны',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isFollowing
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUserTile(UserInfo user, ThemeData theme, FollowerService service) {
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    final isCurrentUser = user.id == widget.currentUser.id;
    final isFollowing = user.isFollowing ?? service.isFollowing(user.id);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: InkWell(
        onTap: () => _openUserProfile(user),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: hasAvatar
                    ? ClipOval(
                        child: ImageLoader().loadImage(
                          user.avatarUrl,
                          48,
                          Center(
                            child: Text(
                              _initials(user.username),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _initials(user.username),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.username,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(left: AppDimensions.paddingS),
                            child: _buildStatusChip(theme, true),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: AppDimensions.paddingS),
                            child: _buildStatusChip(theme, isFollowing),
                          ),
                      ],
                    ),
                    if ((user.fullName ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.fullName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, FollowerService service) {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_error != null) {
      return ErrorView(
        error: _error!,
        onRetry: () => _performSearch(_query),
      );
    }

    if (_query.trim().isEmpty) {
      return EmptyState(
        icon: Icons.search,
        message: 'Введите имя пользователя или username для поиска.',
      );
    }

    if (_results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        message: 'Ничего не найдено. Попробуйте другой запрос.',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        0,
        AppDimensions.paddingM,
        AppDimensions.paddingXL,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final user = _results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
          child: _buildUserTile(user, theme, service),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Поиск пользователей'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        body: ResponsiveContainer(
          child: Column(
            children: [
              _buildSearchBar(theme),
              Expanded(
                child: Consumer<FollowerService>(
                  builder: (context, service, child) {
                    return _buildContent(theme, service);
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
