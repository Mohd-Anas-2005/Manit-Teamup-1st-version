import 'package:flutter/material.dart';

enum AppNavTab {
  discovery(
    label: 'Discovery',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore_rounded,
  ),
  teams(
    label: 'Teams',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
  ),
  requests(
    label: 'Requests',
    icon: Icons.swap_horiz_outlined,
    selectedIcon: Icons.swap_horiz_rounded,
  ),
  notifications(
    label: 'Alerts',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_rounded,
  ),
  profile(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  );

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppNavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
