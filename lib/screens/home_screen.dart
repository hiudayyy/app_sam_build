import 'dart:io';

import 'package:csam_mobile/models/vuontrong/losam_model.dart';
import 'package:csam_mobile/screens/plant_management_view_screen.dart';
import 'package:csam_mobile/screens/plants_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import 'add_plant_screen.dart';
import 'dashboard_screen.dart';
import 'diary_management_screen.dart';
import 'environment_management_screen.dart';
import 'investor_plant_view_screen.dart';
import 'verification_screen.dart';
import 'plant_detail_screen.dart';
import 'batch_diary_update_screen.dart';
import 'diary_form_screen.dart';
import '../data/mock_data.dart';
import '../models/cay_sam.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/role_based_navigation.dart';
import '../widgets/access_denied.dart';
import '../widgets/protected_route.dart';
import '../widgets/user_profile.dart';

class HomeScreen extends StatefulWidget {
  final int? tabcurrent;
  final bool shouldShowDialog;
  final LoSamModel? zone;

  const HomeScreen({
    Key? key, this.tabcurrent, this.shouldShowDialog = false, this.zone,
  }) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<PlantManagementViewScreenState> plantScreenKey = GlobalKey();
  NavTab _currentTab = NavTab.dashboard;
  String? _selectedPlantId;
  bool _showDiaryForm = false;
  List<String> _selectedPlantsForDiary = [];
  bool _showAddPlantForm = false;

  Widget _getScreenForTab(NavTab tab) {
    switch (tab) {
      case NavTab.dashboard:
        return ProtectedRoute(
          requiredPermission: Permission.viewDashboard,
          fallback: AccessDenied(feature: 'Tổng quan'),
          child: DashboardScreen(plants: MockData.mockPlants),
        );
      case NavTab.plants:
        return PlantManagementViewScreen(key: plantScreenKey);
      case NavTab.diary:
        return ProtectedRoute(
          requiredPermission: Permission.updateDiary,
          fallback: AccessDenied(feature: 'Nhật ký'),
          child: DiaryManagementScreen(),
        );
      case NavTab.environment:
        return ProtectedRoute(
          requiredPermission: Permission.viewEnvironment,
          fallback: AccessDenied(feature: 'Môi trường'),
          child: EnvironmentManagementScreen(),
        );
      case NavTab.verification:
        return ProtectedRoute(
          requiredPermission: Permission.verifyQuality,
          fallback: AccessDenied(feature: 'Xác thực'),
          child: VerificationScreen(),
        );
    }
  }

  void _handlePlantSelect(String plantId) {
    setState(() {
      _selectedPlantId = plantId;
    });
  }

  void _handleAddNewPlant() {
    setState(() {
      _showAddPlantForm = true;
    });
  }

  void _handleAddPlantSubmit(Map<String, dynamic> plantData,List<File?> image) {
    print('New plant added: $plantData');
    setState(() {
      _showAddPlantForm = false;
    });
    // Here would integrate with backend/Supabase to save new plant
    // Would also refresh the plants list
  }

  void _handleBatchDiaryUpdate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BatchDiaryUpdateScreen(
          onCancel: () => Navigator.of(context).pop(),
          onSubmit: (data) {
            print('Batch diary update: $data');
            Navigator.of(context).pop();
            // Here would integrate with backend to update multiple plants
          },
        ),
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    _currentTab = widget.tabcurrent == 2 ? NavTab.plants :NavTab.dashboard;
    if (widget.shouldShowDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        plantScreenKey.currentState?.Selectlo(widget.zone);
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!authProvider.isAuthenticated || authProvider.user == null) {
          return Scaffold(
            body: Center(
              child: Text('Not authenticated'),
            ),
          );
        }
        // Show add plant form overlay
        if (_showAddPlantForm) {
          return AddPlantScreen(
            onSubmit: _handleAddPlantSubmit,
            onCancel: () {
              setState(() {
                _showAddPlantForm = false;
              });
            },
          );
        }
        // Show diary form overlay
        if (_showDiaryForm) {
          return DiaryFormScreen(
            plantIds: _selectedPlantsForDiary, // ✅ Fixed parameter name
            onCancel: () {
              setState(() {
                _showDiaryForm = false;
                _selectedPlantsForDiary.clear();
              });
            },
            onSubmit: (data) {
              // Handle diary submission
              setState(() {
                _showDiaryForm = false;
                _selectedPlantsForDiary.clear();
              });
            },
          );
        }


        // Get available tabs based on user permissions
        final maVaiTros = authProvider.user?.htPhanQuyenTaiKhoans ?? [];

        final availableTabs = maVaiTros
            .map((v) => RoleUtils.toUserRole(v.maVaiTro))   // convert id → UserRole
            .whereType<UserRole>()                   // bỏ null
            .expand((role) => RoleBasedNavigation.getAvailableTabs(role))
            .toList();// ✅ Fixed: use .role property

        // If current tab is not available, switch to first available tab
        if (availableTabs.isNotEmpty &&
            !availableTabs.any((tab) => tab.id == _currentTab)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _currentTab = availableTabs.first.id;
            });
          });
        }

        return Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/samnghigia.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sâm Ngọc Linh Nghị gia',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Sâm thật, giá trị thật',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.025,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: UserProfile(),
                ),
            ],
          ),
          body: _getScreenForTab(_currentTab),

          // CRITICAL: Only show bottom navigation if user has available tabs
          // This mirrors React logic exactly
          bottomNavigationBar: availableTabs.isNotEmpty
              ? BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _getValidTabIndex(availableTabs),
                  onTap: (index) {
                    if (index >= 0 && index < availableTabs.length) {
                      setState(() {
                        _currentTab = availableTabs[index].id;
                      });
                    }
                  },
                  items: _buildBottomNavItems(availableTabs),
                  selectedItemColor: Theme.of(context).primaryColor,
                  unselectedItemColor: Colors.grey[600],
                  backgroundColor: Colors.white,
                  elevation: 8,
                )
              : null, // Hide bottom nav completely if no tabs available
        );
      },
    );
  }

  // Helper method to get valid tab index
  int _getValidTabIndex(List<TabConfig> availableTabs) {
    final index = availableTabs.indexWhere((tab) => tab.id == _currentTab);
    return index >= 0 ? index : 0;
  }

  // Helper method to build bottom navigation items - only for available tabs
  List<BottomNavigationBarItem> _buildBottomNavItems(
      List<TabConfig> availableTabs) {
    return availableTabs.map((tab) {
      return BottomNavigationBarItem(
        icon: Icon(tab.icon),
        label: tab.label,
      );
    }).toList();
  }
}
