import 'package:flutter/material.dart';
import '../models/user.dart';

enum NavTab { dashboard, plants/*, diary*/, environment, verification }

class TabConfig {
  final NavTab id;
  final String label;
  final IconData icon;
  final List<UserRole> roles;

  const TabConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.roles,
  });
}

class RoleBasedNavigation {
  static const List<TabConfig> tabConfigs = [
    TabConfig(
      id: NavTab.dashboard,
      label: 'Tổng quan',
      icon: Icons.dashboard_outlined,
      roles: [
        UserRole.nft_admin,
        UserRole.nft_invester,
        UserRole.nft_garden,
        UserRole.nguoiKiemDinh,
        UserRole.nft_user,
      ],
    ),
    TabConfig(
      id: NavTab.plants,
      label: 'Cây trồng',
      icon: Icons.eco_outlined,
      roles: [
        UserRole.nft_admin,
        UserRole.nft_garden,
        UserRole.nft_user,
        UserRole.nft_invester,
      ],
    ),
    /*TabConfig(
      id: NavTab.diary,
      label: 'Nhật ký',
      icon: Icons.book_outlined,
      roles: [
        UserRole.nft_admin,
        UserRole.nft_garden,
        UserRole.nguoiKiemDinh,
        UserRole.nft_user,
      ],
    ),*/
    TabConfig(
      id: NavTab.environment,
      label: 'Môi trường',
      icon: Icons.thermostat_outlined,
      roles: [
        UserRole.nft_admin,
        UserRole.nft_garden,
        UserRole.nguoiKiemDinh,
        UserRole.nft_user,
      ],
    ),
    TabConfig(
      id: NavTab.verification,
      label: 'Xác thực',
      icon: Icons.verified_outlined,
      roles: [
        UserRole.nft_admin,
        UserRole.nft_garden,
        UserRole.nguoiKiemDinh,
      ],
    ),
  ];

  static List<TabConfig> getAvailableTabs(UserRole role) {
    return tabConfigs.where((tab) => tab.roles.contains(role)).toList();
  }

  static bool isTabVisible(NavTab tab, UserRole role) {
    final config = tabConfigs.firstWhere(
          (config) => config.id == tab,
      orElse: () => throw Exception('Tab configuration not found for $tab'),
    );
    return config.roles.contains(role);
  }

  static NavTab? getFirstAvailableTab( UserRole role) {
    final availableTabs = getAvailableTabs(role);
    return availableTabs.isNotEmpty ? availableTabs.first.id : null;
  }
}

// Helper function to convert NavTab to index for BottomNavigationBar
class NavTabHelper {
  static int getTabIndex(NavTab tab, List<NavTab> availableTabs) {
    return availableTabs.indexOf(tab);
  }

  static NavTab getTabFromIndex(int index, List<NavTab> availableTabs) {
    if (index >= 0 && index < availableTabs.length) {
      return availableTabs[index];
    }
    return NavTab.dashboard;
  }

  static List<BottomNavigationBarItem> createBottomNavItems(
      List<TabConfig> availableTabs,
      ) {
    return availableTabs.map((tab) {
      return BottomNavigationBarItem(
        icon: Icon(tab.icon),
        label: tab.label,
      );
    }).toList();
  }
}