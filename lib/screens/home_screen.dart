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
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        return PlantsScreenNew(
          onPlantSelected: _handlePlantSelect,
        );
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

  void _handleAddPlantSubmit(Map<String, dynamic> plantData) {
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

        // Show plant detail if selected
        if (_selectedPlantId != null) {
          final plant = MockData.mockPlants.firstWhere(
            (p) => p.id == _selectedPlantId,
            orElse: () => CaySam.empty(),
          );

          // if (plant.id.isNotEmpty) {
          //   return PlantDetailScreen(
          //     plant: plant,
          //     onBack: () {
          //       setState(() {
          //         _selectedPlantId = null;
          //       });
          //     },
          //   );
          // }
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
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.eco, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sâm Ngọc Linh',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Số hóa Sâm Ngọc Linh - Quốc bảo Việt Nam',
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
              // Show batch diary button only on plants tab
              if (_currentTab == NavTab.plants && !maVaiTros.any((role) => role.maVaiTro == "nft_invester"))
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () => _handleAddNewPlant(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(8), // padding cho icon
                      minimumSize: Size(32, 32), // đảm bảo nút không quá nhỏ
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8), // bo góc nếu cần
                      ),
                    ),
                    child: Icon(Icons.add, size: 18,color: Colors.black87,),
                  ),
                )
              // Show batch diary button on diary tab
              else
                // Show UserProfile for other cases
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
