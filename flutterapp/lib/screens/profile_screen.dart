import 'package:flutter/material.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/screens/auth/login_screen.dart';
import 'package:flutterapp/service/image_loader_service.dart';
import 'package:flutterapp/service/secure_storage.dart';
import 'package:flutterapp/service/user.dart';
import 'package:flutterapp/widgets/common/loading_indicator.dart';
import 'package:flutterapp/widgets/common/error_view.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/constants/app_text_styles.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final JWTToken token;

  const ProfileScreen({super.key, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      final user = await getUser(widget.token);
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
      MySnackBar(
        text: 'Профиль обновлен',
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _logout() {
    SecureStorageService().deleteJWTToken();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const GradientBackground(child: LoginScreen()),
      ),
      (route) => false,
    );
  }

  Widget _buildAvatar() {
    String? avatarUrl = _user?.avatarUrl;
    return ImageLoader().loadImage(
      avatarUrl,
      120,
      const Icon(
        Icons.person,
        size: 60,
        color: Colors.white,
      )
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

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    bool isEditable = false,
    TextEditingController? controller,
    int maxLines = 1,
  }) {
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
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          if (_isEditing && isEditable && controller != null)
            TextField(
              controller: controller,
              maxLines: maxLines,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceDark.withValues(alpha: 0.5),
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
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
                color: value.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  // Список информационных карточек (без статуса isActive)
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
    if (_isLoading) {
      return const Center(
        child: LoadingIndicator(message: 'Загрузка профиля...'),
      );
    }

    if (_errorMessage != null) {
      return ErrorView(error: _errorMessage!, onRetry: _loadUserProfile);
    }

    if (_user == null) {
      return const Center(
        child: Text('Пользователь не найден'),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.paddingL),

          // Avatar Section
          _buildAvatar(),
          const SizedBox(height: AppDimensions.paddingM),

          // Username
          Text(
            '@${_user!.username}',
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXS),

          // Role Badge
          _buildRoleBadge(),
          const SizedBox(height: AppDimensions.paddingXL),

          // Info Cards — всегда вертикальный список (без сетки)
          Column(
            children: _buildInfoCards()
                .expand((widget) => [
                      widget,
                      const SizedBox(height: AppDimensions.paddingM)
                    ])
                .toList()
              ..removeLast(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingXL,
            vertical: AppDimensions.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          elevation: 0,
        ),
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
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
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Профиль'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          actions: [

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
            ),

            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Обновить',
              onPressed: _loadUserProfile,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadUserProfile,
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceDark,
          child: ResponsiveContainer(
            child: _buildContent(),
          ),
        ),
      ),
    );
  }
}