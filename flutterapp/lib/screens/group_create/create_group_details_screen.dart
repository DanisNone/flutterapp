import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/service/conversation_service.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/widgets/common/my_snack_bar.dart';
import 'package:flutterapp/widgets/common/responsive_container.dart';

class CreateGroupDetailsScreen extends StatefulWidget {
  final ChatManager manager;
  final String currentUsername;
  final List<UserInfo> selectedUsers;

  const CreateGroupDetailsScreen({
    super.key,
    required this.manager,
    required this.currentUsername,
    required this.selectedUsers,
  });

  @override
  State<CreateGroupDetailsScreen> createState() =>
      _CreateGroupDetailsScreenState();
}

class _CreateGroupDetailsScreenState extends State<CreateGroupDetailsScreen> {
  final _nameController = TextEditingController();
  bool _isCreating = false;

  String? _selectedAvatarUrl;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    ScaffoldMessenger.of(context).showSnackBar(
      MySnackBar(
        text: 'Выбор аватарки пока в разработке',
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showError('Введите название группы');
      return;
    }

    setState(() => _isCreating = true);

    try {
      await ConversationService.createConversation(
        name: name,
        usernames: widget.selectedUsers.map((u) => u.username).toList(),
      );

      if (!mounted) return;

      widget.manager.loadConversations();

      ScaffoldMessenger.of(context).showSnackBar(
        MySnackBar(
          text: 'Группа "$name" создана',
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context); // close details
      Navigator.pop(context); // close selection
    } catch (e) {
      if (!mounted) return;
      _showError('Ошибка создания: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      MySnackBar(
        text: text,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final bottomInset = MediaQuery.of(context).viewInsets.bottom;

  return GradientBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Детали группы'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        titleSpacing: 12,
        toolbarHeight: 56,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAvatarSection(theme),
                _buildNameSection(theme),
                _buildParticipantsPreview(theme),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context),
    ),
  );
}
  Widget _buildAvatarSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Center(
        child: GestureDetector(
          onTap: _pickAvatar,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: _selectedAvatarUrl != null
                ? NetworkImage(_selectedAvatarUrl!)
                : null,
            child: _selectedAvatarUrl == null
                ? Icon(
                    Icons.camera_alt,
                    size: 32,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildNameSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: MyContainer(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        borderRadius: AppDimensions.radiusL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Название группы',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Введите название...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsPreview(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: MyContainer(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        borderRadius: AppDimensions.radiusL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Участники (${widget.selectedUsers.length})',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selectedUsers.map((user) {
                return Chip(
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
                );
              }).toList(),
            ),
          ],
        ),
      ),
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
            onPressed: _isCreating ? null : _createGroup,
            isLoading: _isCreating,
            child: const Text('Создать группу'),
          ),
        ),
      ),
    );
  }
}