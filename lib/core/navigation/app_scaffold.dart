import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../features/discovery/presentation/discovery_screen.dart';
import '../../features/teams/presentation/teams_screen.dart';
import '../../features/teams/presentation/create_team_screen.dart';
import '../../features/joining_requests/presentation/joining_requests_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/notifications/services/notification_repository.dart';
import '../../features/profiles/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import 'nav_destination.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  AppNavTab _currentTab = AppNavTab.discovery;

  @override
  void initState() {
    super.initState();
    NotificationRepository.instance.refreshUnreadCount();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTab = AppNavTab.values[index];
    });
    if (_currentTab == AppNavTab.notifications) {
      NotificationRepository.instance.refreshUnreadCount();
    }
  }

  void _navigateToCreateTeam() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateTeamScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void _openOnboarding() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(
          onFinish: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentTab) {
      case AppNavTab.discovery:
        return 'Teammate & Hackathons';
      case AppNavTab.teams:
        return 'Team Workspaces';
      case AppNavTab.requests:
        return 'Collaboration Requests';
      case AppNavTab.notifications:
        return 'Campus Alerts';
      case AppNavTab.profile:
        return 'Scholar Profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Android back navigation: if not on primary tab (Discovery), switch to Discovery tab
    return PopScope(
      canPop: _currentTab == AppNavTab.discovery,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _currentTab = AppNavTab.discovery;
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.midnightNavy,
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: AppColors.textSecondary),
              tooltip: 'MANIT TeamUp Tour',
              onPressed: _openOnboarding,
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
              tooltip: 'Settings',
              onPressed: _openSettings,
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentTab.index,
          children: [
            DiscoveryScreen(onOpenCreateTeam: _navigateToCreateTeam),
            TeamsScreen(onOpenCreateTeam: _navigateToCreateTeam),
            const JoiningRequestsScreen(),
            const NotificationsScreen(),
            ProfileScreen(onOpenSettings: _openSettings),
          ],
        ),
        bottomNavigationBar: ValueListenableBuilder<int>(
          valueListenable: NotificationRepository.instance.unreadCountNotifier,
          builder: (context, unreadCount, _) {
            return NavigationBar(
              selectedIndex: _currentTab.index,
              onDestinationSelected: _onTabSelected,
              destinations: AppNavTab.values.map((tab) {
                Widget icon = Icon(tab.icon);
                Widget selectedIcon = Icon(tab.selectedIcon);

                if (tab == AppNavTab.notifications && unreadCount > 0) {
                  icon = Badge.count(
                    count: unreadCount,
                    child: icon,
                  );
                  selectedIcon = Badge.count(
                    count: unreadCount,
                    child: selectedIcon,
                  );
                }

                return NavigationDestination(
                  icon: icon,
                  selectedIcon: selectedIcon,
                  label: tab.label,
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
