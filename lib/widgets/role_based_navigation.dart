import 'package:flutter/material.dart';
import '../models/user.dart';

enum NavTab { dashboard, plants/*, diary*//*, environment, verification*/ }

class TabConfig {
  final NavTab id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final List<UserRole> roles;

  const TabConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.roles,
  });
}

class RoleBasedNavigation {
  static const List<TabConfig> tabConfigs = [
    TabConfig(
      id: NavTab.dashboard,
      label: 'Tổng quan',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_outlined,
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
      icon: Icons.spa_outlined,
      activeIcon: Icons.spa_outlined,
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
/* TabConfig(
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
    ),*/
  ];

  static List<TabConfig> getAvailableTabs(List<UserRole> userRoles) {
    return tabConfigs.where((tab) => tab.roles.any((r) => userRoles.contains(r))).toList();
  }

  static bool isTabVisible(NavTab tab, List<UserRole> userRoles) {
    final config = tabConfigs.firstWhere(
          (config) => config.id == tab,
      orElse: () => throw Exception('Tab configuration not found for $tab'),
    );
    return config.roles.any((r) => userRoles.contains(r));
  }

  static NavTab? getFirstAvailableTab(List<UserRole> userRoles) {
    final availableTabs = getAvailableTabs(userRoles);
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
        activeIcon: Icon(tab.activeIcon), // Đã bổ sung thêm activeIcon để hiển thị đồng bộ
        label: tab.label,
      );
    }).toList();
  }
}