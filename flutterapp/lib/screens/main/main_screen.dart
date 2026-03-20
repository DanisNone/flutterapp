import 'package:flutter/material.dart';
import 'package:flutterapp/screens/main/conversation_content.dart';
import 'package:flutterapp/screens/main/profile_content.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/model/jwttoken.dart';

class MainScreen extends StatefulWidget {
  final JWTToken token;
  const MainScreen({super.key, required this.token});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.add(ConversationsContent(token: widget.token));
    _pages.add(ProfileContent(token: widget.token));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Чаты',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }
}