import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import 'home_dashboard.dart';

class HydroShell extends StatelessWidget {
  const HydroShell({super.key});

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeDashboard(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: const Color(0xFF8E8E93),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.drop),
            activeIcon: Icon(CupertinoIcons.drop_fill),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            activeIcon: Icon(CupertinoIcons.chart_bar_fill),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.slider_horizontal_3),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) => screens[index],
        );
      },
    );
  }
}
