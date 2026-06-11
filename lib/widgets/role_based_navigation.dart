import 'package:flutter/material.dart';
import '../models/user.dart';

enum NavTab { dashboard,weather,invest,account, plants/*, diary*//*, environment, verification*/, }

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
      label: 'Trang chủ',
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
      roles: [
        UserRole.nft_admin,
        UserRole.nft_invester,
        UserRole.nft_garden,
        UserRole.nguoiKiemDinh,
        UserRole.nft_user,
      ],
    ),
    TabConfig(
      id: NavTab.weather,
      label: 'Thời tiết',
      icon: Icons.cloud_rounded,
      activeIcon: Icons.cloud_rounded,
      roles: [
        UserRole.nft_admin,
        UserRole.nft_garden,
        UserRole.nft_user,
        UserRole.nft_invester,
      ],
    ),
    TabConfig(
      id: NavTab.invest,
      label: 'Đầu tư',
      icon: Icons.shield_outlined,
      activeIcon: Icons.shield_outlined,
      roles: [
        UserRole.nft_admin,
        UserRole.nft_garden,
        UserRole.nft_user,
        UserRole.nft_invester,
      ],
    ),
    TabConfig(
      id: NavTab.account,
      label: 'Tài khoản',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_outline_rounded,
      roles: [
        UserRole.nft_admin,
        UserRole.nft_garden,
        UserRole.nft_user,
        UserRole.nft_invester,
      ],
    ),
    // TabConfig(
    //   id: NavTab.plants,
    //   label: 'Cây trồng',
    //   icon: Icons.spa_outlined,
    //   activeIcon: Icons.spa_outlined,
    //   roles: [
    //     UserRole.nft_admin,
    //     UserRole.nft_garden,
    //     UserRole.nft_user,
    //     UserRole.nft_invester,
    //   ],
    // ),
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
    if (userRoles.isEmpty) {
      return tabConfigs.where((tab) =>
      tab.id == NavTab.dashboard ||
          tab.id == NavTab.weather ||
          tab.id == NavTab.invest ||
          tab.id == NavTab.account).toList();
    }
    return tabConfigs.where((tab) => tab.roles.any((r) => userRoles.contains(r))).toList();
  }

  static bool isTabVisible(NavTab tab, List<UserRole> userRoles) {
    if (userRoles.isEmpty) return true;
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