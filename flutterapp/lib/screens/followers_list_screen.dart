import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/screens/user_profile_screen.dart';
import 'package:flutterapp/service/follower_service.dart';
import 'package:flutterapp/service/image_loader_service.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/empty_state.dart';
import 'package:flutterapp/widgets/common/error_view.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:provider/provider.dart';

class FollowersListScreen extends StatefulWidget {
  final int currentUserId;

  const FollowersListScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FollowerService>().loadFirstFollowersPage();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<FollowerService>().loadMoreFollowers();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _query = value;
    });
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<FollowerService>().loadFirstFollowersPage(query: _query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    setState(() {
      _query = '';
    });
    context.read<FollowerService>().loadFirstFollowersPage(query: '');
  }

  void _openUserProfile(UserInfo follower) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          user: follower,
          currentUserId: widget.currentUserId,
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Поиск по подписчикам...',
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
                  onPressed: _clearSearch,
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

  Widget _buildListTile(UserInfo follower, ThemeData theme, FollowerService service) {
    final hasAvatar = follower.avatarUrl != null && follower.avatarUrl!.isNotEmpty;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: InkWell(
        onTap: () => _openUserProfile(follower),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Hero(
                tag: 'follower_avatar_${follower.id}',
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  ),
                  child: hasAvatar
                      ? ClipOval(
                          child: ImageLoader().loadImage(
                            follower.avatarUrl,
                            52,
                            Center(
                              child: Text(
                                _initials(follower.username),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials(follower.username),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
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
                            follower.username,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if ((follower.fullName ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        follower.fullName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if ((follower.bio ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        follower.bio!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
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

  Widget _buildSentinel(ThemeData theme, FollowerService service) {
    if (service.isLoadingFollowers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingL),
        child: Center(child: LoadingIndicator()),
      );
    }
    if (service.hasMoreFollowers) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
        child: Center(
          child: Text(
            'Прокрутите вниз, чтобы загрузить ещё',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBody(ThemeData theme, FollowerService service) {
    final isInitialLoading = service.isLoadingFollowers && service.followers.isEmpty;
    final hasError = service.followersError != null && service.followers.isEmpty;

    if (isInitialLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (hasError) {
      return ErrorView(
        error: service.followersError!,
        onRetry: () => service.loadFirstFollowersPage(query: _query),
      );
    }

    if (service.followers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        message: _query.isNotEmpty
            ? 'Ничего не найдено. Попробуйте другой запрос.'
            : 'Список будет подгружаться по мере прокрутки.',
      );
    }

    return RefreshIndicator(
      onRefresh: service.refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingM,
          0,
          AppDimensions.paddingM,
          AppDimensions.paddingXL,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: service.followers.length + 1,
        itemBuilder: (context, index) {
          if (index == service.followers.length) {
            return _buildSentinel(theme, service);
          }
          final follower = service.followers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
            child: _buildListTile(follower, theme, service),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<FollowerService>(
      builder: (context, service, child) {
        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Подписчики'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: theme.colorScheme.onSurface,
              actions: [
                IconButton(
                  tooltip: 'Обновить',
                  onPressed: service.isRefreshing ? null : service.refresh,
                  icon: service.isRefreshing
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            body: ResponsiveContainer(
              child: Column(
                children: [
                  _buildSearchBar(theme),
                  if (service.followersError != null && service.followers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
                      child: ErrorView(
                        error: service.followersError!,
                        onRetry: () => service.loadFirstFollowersPage(query: _query),
                      ),
                    ),
                  Expanded(child: _buildBody(theme, service)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
