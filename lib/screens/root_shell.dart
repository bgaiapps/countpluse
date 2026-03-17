import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'summary_screen.dart';
import 'settings_screen.dart';
import '../services/navigation_service.dart';
import '../theme/app_theme.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final List<Widget> _pages = const [
    HomeScreen(),
    SummaryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: navIndexNotifier,
      builder: (context, idx, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: _pages[idx],
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.backgroundDark,
              border: Border(
                top: BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: idx,
              onTap: (i) => navIndexNotifier.value = i,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.touch_app),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Summary',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
              selectedItemColor: AppColors.textPrimary,
              unselectedItemColor: AppColors.textPrimary,
              backgroundColor: AppColors.backgroundDark,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: 15,
              unselectedFontSize: 15,
            ),
          ),
        );
      },
    );
  }
}
