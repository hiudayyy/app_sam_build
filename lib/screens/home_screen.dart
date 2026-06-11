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
import 'package:nftsam/screens/weather_screen.dart';
import 'package:overlay_support/overlay_support.dart'; // Bổ sung
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../main.dart'; // Bổ sung (để lấy navigatorKey)
import '../models/kttoken.dart';
import '../models/user_model.dart';
import '../services/nfc_service.dart';
import '../services/phantom_service.dart';
import '../services/signalr_service.dart';
import '../widgets/account_screen.dart';
import '../widgets/lazyIndexedStack.dart';
import 'add_plant_screen.dart';
import 'dashboard_screen.dart';
import 'dashboardnew_screen.dart';
import 'investment_screen.dart';
import 'login_screen.dart';
import 'plant_detail_screen.dart';
import 'diary_form_screen.dart';
import '../data/mock_data.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/role_based_navigation.dart';
import '../widgets/access_denied.dart';
import '../widgets/protected_route.dart';
import '../widgets/user_profile.dart';

import '/app_config.dart';

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
  late bool isGuest = false;
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

  // Widget _getScreenForTab(NavTab tab) {
  //   switch (tab) {
  //     case NavTab.dashboard:
  //       return ProtectedRoute(
  //         requiredPermission: Permission.viewDashboard,
  //         fallback: AccessDenied(feature: 'Tổng quan'),
  //         child: DashboardScreen(plants: MockData.mockPlants),
  //       );
  //     case NavTab.plants:
  //       return PlantManagementViewScreen(key: plantScreenKey);
  //     // case NavTab.diary:
  //     //   return ProtectedRoute(
  //     //     requiredPermission: Permission.updateDiary,
  //     //     fallback: AccessDenied(feature: 'Nhật ký'),
  //     //     child: DiaryManagementScreen(),
  //     //   );
  //     /*case NavTab.environment:
  //       return ProtectedRoute(
  //         requiredPermission: Permission.viewEnvironment,
  //         fallback: AccessDenied(feature: 'Môi trường'),
  //         child: EnvironmentManagementScreen(),
  //       );
  //     case NavTab.verification:
  //       return ProtectedRoute(
  //         requiredPermission: Permission.verifyQuality,
  //         fallback: AccessDenied(feature: 'Xác thực'),
  //         child: VerificationScreen(),
  //       );*/
  //   }
  // }

  void _handleAddPlantSubmit(
      Map<String, dynamic> plantData, List<File?> image, String? caysamid) {
    setState(() {
      _showAddPlantForm = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _Guest();
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
    //   AppConfig.printEx("Lỗi kết nối Phantom: $e");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Lỗi: Không tìm thấy ứng dụng Phantom Wallet")),
    //   );
    // });

    // (3) ĐÃ THAY THẾ: Gọi hàm khởi tạo SignalR
  }
  Future<void> _Guest() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    isGuest = userJson == null;
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

        entry = showOverlayNotification(
          (context) {
            return GestureDetector(
              onTap: () async {
                entry?.dismiss();
                final CaySamModel? model = await API().getCaySamById(caySamId);
                if (model != null) {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (context) => PlantDetailScreen(
                          plant: model, onBack: () => Navigator.pop(context)),
                    ),
                  );
                }
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
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
                            Text(title,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text(body,
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 14)),
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
      AppConfig.printEx("Lỗi nghiêm trọng khi khởi tạo SignalR: $e");
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

        // if (!authProvider.isAuthenticated || authProvider.user == null) {
        //   return Scaffold(
        //     body: Center(
        //       child: Text('Not authenticated'),
        //     ),
        //   );
        // }
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

// Bước 1: Gom tất cả các quyền của User thành 1 danh sách List<UserRole>
        final List<UserRole> userRoles = maVaiTros
            .map((v) =>
                RoleUtils.toUserRole(v.maVaiTro)) // convert id → UserRole
            .whereType<UserRole>() // bỏ null
            .toList();

// Bước 2: Ném thẳng nguyên cái danh sách đó vào hàm.
// Hàm sẽ tự động quét và nhặt ra các tab không bao giờ trùng lặp!
        final availableTabs = RoleBasedNavigation.getAvailableTabs(userRoles);

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
            // actions: [
            //   Container(
            //     width: 34 * scale,
            //     height: 34 * scale,
            //     decoration: BoxDecoration(
            //       color: Colors.white,
            //       shape: BoxShape.circle,
            //       border: Border.all(
            //         color: Colors.green.shade200,
            //         width: 1.2 * scale,
            //       ),
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.green.withOpacity(0.15),
            //           blurRadius: 6 * scale,
            //           offset: Offset(0, 3 * scale),
            //         ),
            //       ],
            //     ),
            //     child: Material(
            //       color: Colors.transparent,
            //       child: InkWell(
            //         customBorder: const CircleBorder(),
            //         onTap: () {
            //           // Hiệu ứng rung nhẹ khi chạm (tăng cảm giác thao tác)
            //           HapticFeedback.lightImpact();
            //           _startManualNfcScan(context);
            //         },
            //         // Màu phản hồi khi nhấn (Ripple effect)
            //         splashColor: Colors.green.withOpacity(0.2),
            //         child: Icon(
            //           Icons.nfc, // Icon sóng hiện đại, gọn gàng
            //           color: Colors.green.shade700,
            //           size: 20 * scale, // Icon cũng lớn dần theo màn hình
            //         ),
            //       ),
            //     ),
            //   ),
            //   SizedBox(width: 2),
            //   Padding(
            //     padding: EdgeInsets.only(right: 4),
            //     child: UserProfile(),
            //   ),
            // ],
          ),
          //body: _getScreenForTab(_currentTab),
          body: LazyIndexedStack(
            // <--- Đổi thành widget này
            index: _currentTab.index,
            children: [
              // Tab 1: Dashboard (Vẫn giữ AutomaticKeepAliveClientMixin bên trong nó nhé)
              // ProtectedRoute(
              //   requiredPermission: Permission.viewDashboard,
              //   fallback: AccessDenied(feature: 'Tổng quan'),
              //   child: DashboardScreen(plants: MockData.mockPlants),
              // ),
              // ProtectedRoute(
              //   requiredPermission: Permission.viewDashboard,
              //   fallback: AccessDenied(feature: 'Tổng quan'),
              //   child: DashboardGuestScreen(),
              // ),
              const DashboardGuestScreen(),
              // Tab 2: Plants
              const WeatherScreen(),

              // Tab 2: Đầu tư (Có thể bọc bằng ProtectedRoute bên trong nếu cần)
              isGuest
                  ? _buildRequireLoginScreen()
                  : const InvestmentScreen(),

              // Tab 3: Tài khoản
              const AccountScreen(),
              //PlantManagementViewScreen(key: plantScreenKey),


              // Tab 3...
              // Tab 4...
            ],
          ),

          extendBody: true,

          bottomNavigationBar: availableTabs.isNotEmpty
              ? SizedBox(
            height: 95 * scale, // Chiều cao tổng (bao gồm cả nút quét nổi)
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 1. THANH NỀN BOTTOM BAR
                Container(
                  height: 70 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20), // Xanh lá đậm (đổi thành 0xFF8B1D1D nếu bạn muốn màu đỏ rực như ảnh)
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. Render phân nửa số tab nằm bên Trái
                      for (int i = 0; i < (availableTabs.length / 2).ceil(); i++)
                        _buildCustomNavItem(i, availableTabs, scale, isGuest),

                      // 2. Khoảng trống ở giữa cho nút Quét nổi lên
                      SizedBox(width: 70 * scale),

                      // 3. Render phân nửa số tab còn lại nằm bên Phải
                      for (int i = (availableTabs.length / 2).ceil(); i < availableTabs.length; i++)
                        _buildCustomNavItem(i, availableTabs, scale, isGuest),
                    ],
                  ),
                ),

                // 2. NÚT NỔI Ở GIỮA (QUÉT TRUY XUẤT)
                Positioned(
                  top: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // TODO: Viết logic mở Camera Quét Truy Xuất ở đây
                        },
                        child: Container(
                          height: 62 * scale,
                          width: 62 * scale,
                          decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20), // Trùng màu nền
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFFFD54F), // Viền Vàng Gold
                                  width: 3.5 * scale),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                          ),
                          child: Center(
                            child: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: const Color(0xFFFFD54F),
                                size: 28 * scale
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      Text(
                        'Quét truy xuất',
                        style: TextStyle(
                          color: const Color(0xFFFFD54F),
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              : null, // Hide bottom nav completely if no tabs available
        );
      },
    );
  }
  Widget _buildRequireLoginScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded, size: 64, color: Colors.orange.shade700),
              ),
              const SizedBox(height: 24),
              const Text(
                'Yêu cầu đăng nhập',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn cần đăng nhập tài khoản để sử dụng tính năng Đầu tư và Giao dịch tài sản.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32), // Nền xanh lá
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đăng nhập ngay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Helper method to get valid tab index
  int _getValidTabIndex(List<TabConfig> availableTabs) {
    final index = availableTabs.indexWhere((tab) => tab.id == _currentTab);
    return index >= 0 ? index : 0;
  }
  // Cập nhật hàm: Thêm tham số bool isGuest
  Widget _buildCustomNavItem(int index, List<TabConfig> tabs, double scale, bool isGuest) {
    if (index >= tabs.length) {
      return SizedBox(width: 65 * scale);
    }

    final tab = tabs[index];
    final int currentIndex = _getValidTabIndex(tabs);
    final bool isSelected = currentIndex == index;

    final Color goldAccent = const Color(0xFFFFD54F);
    final Color unselectedColor = Colors.white60;
    final Color color = isSelected ? goldAccent : unselectedColor;

    return GestureDetector(
      onTap: () {
        // Trả lại sự kiện chuyển tab bình thường cho tất cả mọi người
        setState(() {
          _currentTab = tab.id;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65 * scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, color: color, size: 24 * scale),
            SizedBox(height: 4 * scale),
            Text(
              tab.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11 * scale,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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
