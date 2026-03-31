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
  List<UserInfo> _filteredFollowers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FollowerService().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final service = FollowerService();
    setState(() {
      if (query.isEmpty) {
        _filteredFollowers = [];
        _isSearching = false;
      } else {
        _isSearching = true;
        _filteredFollowers = service.followers
            .where((f) =>
                f.username.toLowerCase().contains(query.toLowerCase()) ||
                (f.fullName?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredFollowers = [];
      _isSearching = false;
    });
  }

  void _openUserProfile(UserInfo follower) {
    final userInfo = UserInfo(
      id: follower.id,
      username: follower.username,
      avatarUrl: follower.avatarUrl,
      fullName: follower.fullName,
      bio: follower.bio,
      lastMessageReadId: -1,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          user: userInfo,
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

  String _getFollowersCountText(int count) {
    final lastDigit = count % 10;
    final lastTwoDigits = count % 100;

    if (lastTwoDigits >= 11 && lastTwoDigits <= 19) {
      return 'подписчиков';
    }

    switch (lastDigit) {
      case 1:
        return 'подписчик';
      case 2:
      case 3:
      case 4:
        return 'подписчика';
      default:
        return 'подписчиков';
    }
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Поиск подписчиков...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _isSearching
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

  Widget _buildFollowerTile(UserInfo follower, ThemeData theme) {
    final hasAvatar = follower.avatarUrl != null && follower.avatarUrl!.isNotEmpty;
    final isCurrentUser = follower.id == widget.currentUserId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: InkWell(
          onTap: () => _openUserProfile(follower),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                // Avatar
                Hero(
                  tag: 'follower_avatar_${follower.id}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                          theme.colorScheme.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: hasAvatar
                        ? ClipOval(
                            child: ImageLoader().loadImage(
                              follower.avatarUrl,
                              56,
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
                // Info
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
                          if (isCurrentUser)
                            Container(
                              margin: const EdgeInsets.only(left: AppDimensions.paddingS),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.paddingS,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                              ),
                              child: Text(
                                'Вы',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (follower.fullName != null && follower.fullName != follower.username)
                        Text(
                          '@${follower.username}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (follower.bio != null && follower.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppDimensions.paddingXS),
                          child: Text(
                            follower.bio!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(FollowerService service, ThemeData theme) {
    final followers = _isSearching ? _filteredFollowers : service.followers;

    if (service.isLoading && service.followers.isEmpty) {
      return const Center(
        child: LoadingIndicator(message: 'Загрузка подписчиков...'),
      );
    }

    if (service.error != null && service.followers.isEmpty) {
      return ErrorView(
        error: service.error!,
        onRetry: () => service.refresh(),
      );
    }

    if (service.followers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        message: 'У вас пока нет подписчиков\n\nНайдите пользователей через поиск и подпишитесь на них',
        buttonText: 'Найти пользователей',
        onButtonPressed: () => Navigator.pop(context),
      );
    }

    if (_isSearching && _filteredFollowers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'Ничего не найдено',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => service.refresh(),
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
        itemCount: followers.length,
        itemBuilder: (context, index) {
          return _buildFollowerTile(followers[index], theme);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Consumer<FollowerService>(
            builder: (context, service, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Мои подписки'),
                  if (service.hasFollowers)
                    Text(
                      '${service.followers.length} ${_getFollowersCountText(service.followers.length)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              );
            },
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          actions: [
            Consumer<FollowerService>(
              builder: (context, service, child) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Обновить',
                  onPressed: service.isLoading ? null : () => service.refresh(),
                );
              },
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: Column(
            children: [
              _buildSearchBar(theme),
              Expanded(
                child: Consumer<FollowerService>(
                  builder: (context, service, child) {
                    return _buildContent(service, theme);
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
