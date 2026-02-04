import 'dart:async'; // Bổ sung
import 'dart:convert'; // Bổ sung
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:nftsam/api/api_caysam.dart';
import 'package:nftsam/models/vuontrong/caysam_model.dart';
import 'package:nftsam/models/vuontrong/losam_model.dart';
import 'package:nftsam/screens/plant_management_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart'; // Bổ sung
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../main.dart'; // Bổ sung (để lấy navigatorKey)
import '../models/user_model.dart';
import '../services/nfc_service.dart';
import '../services/phantom_service.dart';
import '../services/signalr_service.dart';
import '../widgets/lazyIndexedStack.dart';
import 'add_plant_screen.dart';
import 'dashboard_screen.dart';
import 'plant_detail_screen.dart';
import 'diary_form_screen.dart';
import '../data/mock_data.dart';
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
    Key? key,
    this.tabcurrent,
    this.shouldShowDialog = false,
    this.zone,
  }) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AppLinks _appLinks = AppLinks();
  final SignalRService signalRService = SignalRService();
  StreamSubscription<Uri>? _linkSubscription;

  // (1) BỔ SUNG: Biến để quản lý listener
  StreamSubscription? _signalRSubscription;

  final GlobalKey<PlantManagementViewScreenState> plantScreenKey = GlobalKey();
  NavTab _currentTab = NavTab.dashboard;
  String? _selectedPlantId;
  bool _showDiaryForm = false;
  List<String> _selectedPlantsForDiary = [];
  bool _showAddPlantForm = false;
  final PhantomService _phantomService = PhantomService();

  // (2) BỔ SUNG: Hàm sửa lỗi font
  String _fixBadUtf8(String badString) {
    try {
      // 1. Lấy chuỗi lỗi, mã hóa nó trở lại thành bytes (dưới dạng latin1)
      List<int> bytes = latin1.encode(badString);
      // 2. Lấy bytes đó, giải mã chúng (dưới dạng UTF-8)
      return utf8.decode(bytes);
    } catch (e) {
      // Nếu có lỗi, trả về chuỗi gốc
      return badString;
    }
  }

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
    // case NavTab.diary:
    //   return ProtectedRoute(
    //     requiredPermission: Permission.updateDiary,
    //     fallback: AccessDenied(feature: 'Nhật ký'),
    //     child: DiaryManagementScreen(),
    //   );
      /*case NavTab.environment:
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
        );*/
    }
  }


  void _handleAddPlantSubmit(Map<String, dynamic> plantData, List<File?> image,String? caysamid) {
    setState(() {
      _showAddPlantForm = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentTab = widget.tabcurrent == 2 ? NavTab.plants : NavTab.dashboard;
    WidgetsBinding.instance.addObserver(this);
    // NfcService.startNfcSession(context);
    //   _initDeepLinkListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
        if (mounted) {
          _setupSignalRListener(); // <-- Bây giờ mới gọi
        }
      if (widget.shouldShowDialog) {
        plantScreenKey.currentState?.Selectlo(widget.zone);
      }
    });
    // _phantomService.verifyWalletConnection().catchError((e) {
    //   print("Lỗi kết nối Phantom: $e");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Lỗi: Không tìm thấy ứng dụng Phantom Wallet")),
    //   );
    // });


    // (3) ĐÃ THAY THẾ: Gọi hàm khởi tạo SignalR

  }
  void _setupSignalRListener() async {
    try {
      await signalRService.initSignalR();

      // Gán vào biến subscription để có thể hủy ở dispose()
      _signalRSubscription = signalRService.messageStream.listen((message) {
        if (!mounted) return; // Luôn kiểm tra mounted

        String rawTitle = message['title'] ?? 'Thông báo';
        String rawBody = message['body'] ?? 'Nội dung...';

        // Áp dụng hàm sửa lỗi
        String title = _fixBadUtf8(rawTitle);
        String body = _fixBadUtf8(rawBody);
        String caySamId = message['caySamId'] ?? '';

        OverlaySupportEntry? entry;

        entry = showOverlayNotification((context) {
            return GestureDetector(
              onTap: () async {
                entry?.dismiss();
                final CaySamModel? model = await API().getCaySamById(caySamId);
                if (model != null) {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (context) => PlantDetailScreen(plant: model, onBack: () => Navigator.pop(context)),
                    ),
                  );
                }
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text(body, style: TextStyle(color: Colors.black87, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          duration: Duration(seconds: 5),
        );
      });

      // (2) NHƯNG BẠN BỊ THIẾU KHỐI 'CATCH' NÀY
    } catch (e) {
      print("Lỗi nghiêm trọng khi khởi tạo SignalR: $e");
    }
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     NfcService.startNfcSession(context);
  //   } else if (state == AppLifecycleState.paused) {
  //     NfcService.stopNfcSession();
  //   }
  // }

  // Gọi hàm này trong initState()
  Future<void> _startManualNfcScan(BuildContext context) async {
    NfcService.startNfcSession(context);
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NfcService.stopNfcSession();
    _signalRSubscription?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
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
        final double scale = MediaQuery.of(context).size.width / 375.0;

        final availableTabs = maVaiTros
            .map((v) => RoleUtils.toUserRole(v.maVaiTro)) // convert id → UserRole
            .whereType<UserRole>() // bỏ null
            .expand((role) => RoleBasedNavigation.getAvailableTabs(role))
            .toList(); // ✅ Fixed: use .role property

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
              Container(
                width: 34 * scale,
                height: 34 * scale,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1.2 * scale,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.15),
                      blurRadius: 6 * scale,
                      offset: Offset(0, 3 * scale),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      // Hiệu ứng rung nhẹ khi chạm (tăng cảm giác thao tác)
                      HapticFeedback.lightImpact();
                      _startManualNfcScan(context);
                    },
                    // Màu phản hồi khi nhấn (Ripple effect)
                    splashColor: Colors.green.withOpacity(0.2),
                    child: Icon(
                      Icons.nfc, // Icon sóng hiện đại, gọn gàng
                      color: Colors.green.shade700,
                      size: 20 * scale, // Icon cũng lớn dần theo màn hình
                    ),
                  ),
                ),
              ),

              SizedBox(width: 2),

              Padding(
                padding: EdgeInsets.only(right: 4),
                child: UserProfile(),
              ),
            ],
          ),
          //body: _getScreenForTab(_currentTab),
          body: LazyIndexedStack( // <--- Đổi thành widget này
            index: _currentTab.index,
            children: [
              // Tab 1: Dashboard (Vẫn giữ AutomaticKeepAliveClientMixin bên trong nó nhé)
              ProtectedRoute(
                requiredPermission: Permission.viewDashboard,
                fallback: AccessDenied(feature: 'Tổng quan'),
                child: DashboardScreen(plants: MockData.mockPlants),
              ),

              // Tab 2: Plants
              PlantManagementViewScreen(key: plantScreenKey),

              // Tab 3...
              // Tab 4...
            ],
          ),

          extendBody: false,

          bottomNavigationBar: availableTabs.isNotEmpty
              ? Container(
            // Không dùng margin để nó dính sát cạnh dưới
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scale)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), // Bóng rất nhẹ
                  blurRadius: 10,
                  offset: const Offset(0, -5), // Đẩy bóng lên TRÊN để tách biệt nội dung
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scale)),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _getValidTabIndex(availableTabs),
                backgroundColor: Colors.white,
                elevation: 0, // Tắt bóng mặc định

                onTap: (index) {
                  if (index >= 0 && index < availableTabs.length) {
                    // HapticFeedback.selectionClick(); // Bỏ rung nếu không thích
                    setState(() {
                      _currentTab = availableTabs[index].id;
                    });
                  }
                },

                // --- STYLE ---
                // Màu khi chọn
                selectedItemColor: Theme.of(context).primaryColor,
                // Màu khi chưa chọn (đậm hơn chút cho rõ)
                unselectedItemColor: Colors.grey.shade500,

                selectedLabelStyle: TextStyle(
                  fontSize: 12 * scale, // Chữ to hơn một chút cho rõ ràng
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),

                items: _buildBottomNavItems(availableTabs),
              ),
            ),
          )
              : null,// Hide bottom nav completely if no tabs available
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