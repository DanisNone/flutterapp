import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';
import 'package:flutterapp/constants/app_dimensions.dart';

class FabMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  FabMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });
}

class FabMenu extends StatefulWidget {
  final List<FabMenuItem> items;
  final Widget child;

  const FabMenu({
    super.key,
    required this.items,
    required this.child,
  });

  @override
  State<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<FabMenu> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      _toggle();
    }
  }

  @override
  Widget build(BuildContext context) {    
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isOpen) GestureDetector(onTap: _close),
        
        // Menu items
        ..._buildMenuItems(),
        
        // Main FAB
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: AppColors.primary,
            child: RotationTransition(
              turns: _rotateAnimation,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMenuItems() {
    final theme = Theme.of(context);

    return widget.items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final offset = (index + 1) * 70.0;

      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final value = _scaleAnimation.value;
          return Transform.translate(
            offset: Offset(0, -offset * value),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(
            right: AppDimensions.paddingM,
            bottom: AppDimensions.paddingM,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingS,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              // Mini FAB
              FloatingActionButton.small(
                heroTag: 'fab_menu_$index',
                onPressed: () {
                  _close();
                  item.onTap();
                },
                backgroundColor: item.iconColor ?? AppColors.primaryLight,
                child: Icon(item.icon, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}