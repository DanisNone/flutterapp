import 'package:flutter/material.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/screens/auth/login_screen.dart';
import 'package:flutterapp/screens/followers_list_screen.dart';
import 'package:flutterapp/service/api.dart' show getMe;
import 'package:flutterapp/service/chat_repository.dart';
import 'package:flutterapp/service/follower_service.dart';
import 'package:flutterapp/service/image_loader_service.dart';
import 'package:flutterapp/service/jwttoken_manager.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/error_view.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:flutterapp/widgets/common/theme_toggle_button.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> with AutomaticKeepAliveClientMixin<ProfileContent> {
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isEditing = false;
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await getMe();
      if (!mounted) return;
      setState(() {
        _user = user;
        _bioController.text = user.bio ?? '';
        _fullNameController.text = user.fullName;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ошибка загрузки профиля: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      MySnackBar(text: 'Профиль обновлен', backgroundColor: AppColors.success),
    );
  }

  void _logout() {
    JWTTokenManager().deleteJWTToken();
    context.read<FollowerService>().clear();
    context.read<ChatRepository>().clear();
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const GradientBackground(child: LoginScreen()),
      ),
      (route) => false,
    );
  }

  void _openFollowersList() {
    if (_user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FollowersListScreen(currentUserId: _user!.id),
        ),
      );
    }
  }

  Widget _buildAvatar() {
    String? avatarUrl = _user?.avatarUrl;
    return ImageLoader().loadImage(
      avatarUrl,
      120,
      const Icon(Icons.person, size: 60, color: Colors.white),
    );
  }

  Widget _buildRoleBadge() {
    final isAdmin = _user?.role == UserRole.admin;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAdmin
              ? [AppColors.warning, Colors.orange.shade400]
              : [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isAdmin ? 'Администратор' : 'Пользователь',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowersButton(ThemeData theme) {
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: InkWell(
        onTap: _openFollowersList,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
          child: Row(
            children: [
              Icon(
                Icons.people_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Подписчики',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Открыть список и поиск',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    bool isEditable = false,
    TextEditingController? controller,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return MyContainer(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      borderRadius: 16,
      opacity: 0.06,
      border: Border.all(
        color: AppColors.borderGlow.withValues(alpha: 0.5),
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          if (_isEditing && isEditable && controller != null)
            TextField(
              controller: controller,
              maxLines: maxLines,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(AppDimensions.paddingM),
              ),
            )
          else
            Text(
              value.isEmpty ? 'Не указано' : value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: value.isEmpty
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoCards() {
    final dateFormat = DateFormat('dd.MM.yyyy');
    return [
      _buildInfoCard(
        title: 'Полное имя',
        value: _user!.fullName,
        icon: Icons.badge_outlined,
        isEditable: true,
        controller: _fullNameController,
      ),
      _buildInfoCard(
        title: 'О себе',
        value: _user!.bio ?? '',
        icon: Icons.info_outline,
        isEditable: true,
        controller: _bioController,
        maxLines: 3,
      ),
      _buildInfoCard(
        title: 'Дата регистрации',
        value: dateFormat.format(_user!.createdAt),
        icon: Icons.calendar_today,
      ),
      _buildInfoCard(
        title: 'Email',
        value: _user!.email,
        icon: Icons.email_outlined,
      ),
    ];
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Center(
        child: LoadingIndicator(message: 'Загрузка профиля...'),
      );
    }
    if (_errorMessage != null) {
      return ErrorView(error: _errorMessage!, onRetry: _loadUserProfile);
    }
    if (_user == null) {
      return Center(child: Text('Пользователь не найден', style: theme.textTheme.bodyLarge));
    }
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.paddingL),
          _buildAvatar(),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            '@${_user!.username}',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          _buildRoleBadge(),
          const SizedBox(height: AppDimensions.paddingL),
          _buildFollowersButton(theme),
          const SizedBox(height: AppDimensions.paddingXL),
          Column(
            children: _buildInfoCards()
                .expand(
                  (widget) => [
                    widget,
                    const SizedBox(height: AppDimensions.paddingM),
                  ],
                )
                .toList()
              ..removeLast(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Профиль'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurface,
          actions: [
            const ThemeToggleButton(),
            if (!_isLoading && _user != null)
              if (_isEditing) ...[
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Сохранить',
                  onPressed: _saveProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Отмена',
                  onPressed: () => setState(() => _isEditing = false),
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Редактировать',
                  onPressed: () => setState(() => _isEditing = true),
                ),
              ],
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Выйти',
              onPressed: _logout,
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadUserProfile,
          color: AppColors.primary,
          backgroundColor: theme.colorScheme.surface,
          child: ResponsiveContainer(child: _buildContent()),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}