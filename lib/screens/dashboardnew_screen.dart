import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nftsam/api/api_baiviet.dart';
import 'package:nftsam/api/api_caysam.dart';
import 'package:nftsam/api/api_dashboard.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';

// --- THƯ VIỆN BẬT CAMERA QUÉT QR ---
import 'package:mobile_scanner/mobile_scanner.dart';

import '../api/api.dart';
import '../models/baiviet/baiviet_model.dart';
import '../models/dashboard/dashboard_model.dart';
import '../services/nfc_service.dart';
import '/app_config.dart';

// --- CÁC IMPORT CẦN THIẾT CHO QUÉT QR & ĐIỀU HƯỚNG ---
import '../models/vuontrong/caysam_model.dart';
import '../screens/plant_detail_screen.dart';
import '../main.dart'; // Nơi chứa navigatorKey
import '../providers/auth_provider.dart';
import '../screens/plant_management_view_screen.dart';

// --- IMPORT MÀN HÌNH BÀI VIẾT ---
import '../screens/article_detail_screen.dart';
import '../screens/article_list_screen.dart';

String? _pendingPlantIdFromTerminated;

class DashboardGuestScreen extends StatefulWidget {
  const DashboardGuestScreen({Key? key}) : super(key: key);

  @override
  State<DashboardGuestScreen> createState() => _DashboardGuestScreenState();
}

class _DashboardGuestScreenState extends State<DashboardGuestScreen> {
  int _bottomNavIndex = 0;

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color darkGreen = const Color(0xFF1B5E20);
  final Color goldAccent = const Color(0xFFFFD54F);
  final Color backgroundLight = const Color(0xFFF5F9F5);
  DashBoardtotal? numbertotal;

  List<BaiVietModel> _articles = [];
  bool _isLoadingArticles = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
    _fetchDashboardStats();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      void checkAndNavigate() {
        if (authProvider.isAuthenticated && _pendingPlantIdFromTerminated != null) {
          AppConfig.printEx("Đã xác thực, đang điều hướng từ trạng thái tắt...");
          _navigateToPlant(_pendingPlantIdFromTerminated!);
          _pendingPlantIdFromTerminated = null;
        }
      }

      authProvider.addListener(checkAndNavigate);
      checkAndNavigate();
    });
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final res = await API().getDashBoardSamnew();
      if (mounted) setState(() => numbertotal = res?.oneItem);
    } catch (e) {
      AppConfig.printEx("Lỗi Stats: $e");
    }
  }

  Future<void> _fetchArticles() async {
    try {
      final response = await API().listBaiViet(top: 6);
      if (response != null && response.items != null && mounted) {
        setState(() {
          _articles = response.items!;
          _isLoadingArticles = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingArticles = false);
      }
    } catch (e) {
      AppConfig.printEx("Lỗi tải bài viết: $e");
      if (mounted) setState(() => _isLoadingArticles = false);
    }
  }

  // ==========================================
  // CÁC HÀM XỬ LÝ QUÉT & ĐIỀU HƯỚNG
  // ==========================================

  Future<void> _navigateToPlant(String plantId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      final CaySamModel? model = await API().getCaySamById(plantId);

      if (Navigator.canPop(context)) Navigator.pop(context); // Tắt loading

      // Lệnh đẩy sang màn hình chi tiết, tự động che Bottom Navigation
      if (model != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDetailScreen(plant: model, onBack: () => Navigator.pop(context)),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text("Lỗi", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
              body: Center(child: Text("Không tìm thấy cây với ID: $plantId", style: const TextStyle(fontSize: 16))),
            ),
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      AppConfig.printEx("Lỗi _navigateToPlant: $e");
    }
  }

  void _startManualNfcScan(BuildContext context) {
    HapticFeedback.lightImpact();
    NfcService.startNfcSession(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Đang khởi động máy quét NFC...'), behavior: SnackBarBehavior.floating, backgroundColor: primaryGreen),
    );
  }

  Future<void> _startQrScan(BuildContext context) async {
    HapticFeedback.lightImpact();

    // Bật camera quét QR, tự động đè toàn màn hình
    final String? scannedData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrCameraScreen()),
    );

    if (scannedData != null && scannedData.isNotEmpty) {
      String plantId = scannedData;
      if (scannedData.contains('/')) {
        plantId = scannedData.split('/').last;
      }
      await _navigateToPlant(plantId);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy quét QR')),
        );
      }
    }
  }

  // ==========================================
  // GIAO DIỆN CHÍNH
  // ==========================================

  Widget _buildBody() {
    switch (_bottomNavIndex) {
      case 4:
        return WillPopScope(
          onWillPop: () async {
            setState(() => _bottomNavIndex = 0);
            return false;
          },
          child: PlantManagementViewScreen(
            onBack: () => setState(() => _bottomNavIndex = 0),
          ),
        );
      default:
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildBanner(),
                const SizedBox(height: 16),
                _buildQuickActions(),
                const SizedBox(height: 8),
                _buildStatistics(),
                const SizedBox(height: 32),
                _buildFeaturedItems(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      extendBody: true,
      body: _buildBody(),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildBanner() {
    if (_isLoadingArticles) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100,
        child: Container(height: 180, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
      );
    }
    if (_articles.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity, height: 200,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 200, viewportFraction: 1.0, autoPlay: true, autoPlayInterval: const Duration(seconds: 4),
                onPageChanged: (index, reason) => setState(() => _currentIndex = index),
              ),
              items: _articles.take(5).map((article) {
                final String title = article.tieuDe ?? '';
                final String desc = article.moTaNgan ?? '';
                final String imageUrl = article.hinhAnh ?? '';

                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => ArticleDetailScreen(
                              article: article,
                              relatedArticles: _articles,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: imageUrl, fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: darkGreen),
                            errorWidget: (context, url, error) => Container(color: darkGreen),
                          ),
                          Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [darkGreen.withOpacity(0.95), primaryGreen.withOpacity(0.5), Colors.transparent], begin: Alignment.centerLeft, end: Alignment.centerRight))),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, height: 1.3, letterSpacing: 0.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            Positioned(
              bottom: 12, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _articles.take(5).toList().asMap().entries.map((entry) {
                  return AnimatedContainer(duration: const Duration(milliseconds: 300), width: _currentIndex == entry.key ? 20.0 : 6.0, height: 6.0, margin: const EdgeInsets.symmetric(horizontal: 4.0), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white.withOpacity(_currentIndex == entry.key ? 1.0 : 0.4)));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActionItem(Icons.qr_code_scanner_rounded, 'Quét QR',
            onTap: () => _startQrScan(context)),
        _buildActionItem(Icons.nfc, 'Quét NFC',
            onTap: () => _startManualNfcScan(context)),
        _buildActionItem('assets/images/icon2xp.png', 'Cây sâm\ncủa tôi',
            onTap: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (auth.isAuthenticated) {
                setState(() => _bottomNavIndex = 4);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Vui lòng đăng nhập để sử dụng chức năng này.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.orange.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            }),
        _buildActionItem(Icons.feed_rounded, 'Bài viết',
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const ArticleListScreen()));
            }),
      ],
    );
  }

  Widget _buildActionItem(dynamic iconOrPath, String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCEEDC), width: 1),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.07),
                    blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Center(
                child: iconOrPath is String
                    ? Image.asset(iconOrPath, width: 26, height: 26,
                    color: const Color(0xFF2E7D32))
                    : Icon(iconOrPath as IconData,
                    color: const Color(0xFF2E7D32), size: 26),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                    color: Color(0xFF333333), height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 3, height: 14,
                decoration: BoxDecoration(color: primaryGreen,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Thống kê nổi bật',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A))),
          ]),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(children: [
              _buildStatCol(Icons.business_rounded,
                  numbertotal?.totalVuonTrong.toString() ?? '—', 'Tổng vườn'),
              _buildStatSep(),
              _buildStatCol(Icons.map_rounded,
                  numbertotal?.totalLoSam.toString() ?? '—', 'Tổng lô'),
              _buildStatSep(),
              _buildStatCol('assets/images/icon2xp.png',
                  numbertotal?.totalCaySam.toString() ?? '—', 'Tổng cây'),
              _buildStatSep(),
              _buildStatCol(Icons.people_alt_rounded,
                  numbertotal?.totalNhaDauTu.toString() ?? '—', 'Nhà đầu tư'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSep() => Container(
      width: 1, color: const Color(0xFFE8F5E9),
      margin: const EdgeInsets.symmetric(vertical: 4));

  Widget _buildStatCol(dynamic iconOrPath, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: iconOrPath is String
                  ? Image.asset(iconOrPath, width: 18, height: 18,
                  color: primaryGreen)
                  : Icon(iconOrPath as IconData, color: primaryGreen, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.black54,
                  height: 1.3)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w900,
              color: Color(0xFF1B5E20))),
        ],
      ),
    );
  }

  Widget _buildFeaturedItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(width: 3, height: 15,
                  decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Bài viết nổi bật',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
            ]),
            GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const ArticleListScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Xem tất cả',
                    style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _isLoadingArticles
              ? ListView.builder(
            scrollDirection: Axis.horizontal, physics: const NeverScrollableScrollPhysics(), itemCount: 3,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(width: 140, margin: const EdgeInsets.only(right: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))));
            },
          )
              : (_articles.length > 1
              ? ListView.builder(
            scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: _articles.length - 1,
            itemBuilder: (context, index) => _buildItemCard(_articles[index + 1]),
          )
              : const Center(child: Text('Chưa có bài viết nào.'))),
        ),
      ],
    );
  }

  Widget _buildItemCard(BaiVietModel article) {
    final String title = article.tieuDe ?? 'Không có tiêu đề';
    final String imageUrl = article.hinhAnh ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(
              article: article,
              relatedArticles: _articles,
            ),
          ),
        );
      },
      child: Container(
        width: 160, margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F5E9), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(children: [
                CachedNetworkImage(
                  imageUrl: imageUrl, height: 100, width: double.infinity, fit: BoxFit.cover,
                  placeholder: (context, url) => Container(height: 100, color: const Color(0xFFE8F5E9)),
                  errorWidget: (context, url, error) => Container(height: 100, color: const Color(0xFFE8F5E9),
                      child: Center(child: Icon(Icons.eco_rounded, color: Colors.green.shade300, size: 32))),
                ),
                Positioned.fill(child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0x441B5E20)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                )),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A), height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.arrow_forward_rounded, size: 11, color: primaryGreen),
                      const SizedBox(width: 4),
                      Text('Đọc ngay', style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.w700)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      height: 95, color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(color: darkGreen, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_rounded, 'Trang chủ', 0),
                _buildNavItem(Icons.cloud_rounded, 'Thời tiết', 1),
                const SizedBox(width: 70),
                _buildNavItem(Icons.shield_outlined, 'Đầu tư', 2),
                _buildNavItem(Icons.person_outline_rounded, 'Tài khoản', 3),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _startQrScan(context),
                  child: Container(
                    height: 62, width: 62,
                    decoration: BoxDecoration(
                        color: darkGreen, shape: BoxShape.circle, border: Border.all(color: goldAccent, width: 3.5),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    ),
                    child: Center(child: Icon(Icons.qr_code_scanner_rounded, color: goldAccent, size: 28)),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Quét truy xuất', style: TextStyle(color: goldAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (_bottomNavIndex == 4)
            Positioned(
              bottom: 0,
              child: Container(
                height: 70,
                width: MediaQuery.of(context).size.width,
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width * 0.5 - 35),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _bottomNavIndex == index;
    final color = isSelected ? goldAccent : Colors.white60;

    return GestureDetector(
      onTap: () => setState(() => _bottomNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH BẬT CAMERA QUÉT QR
// ==========================================
class QrCameraScreen extends StatefulWidget {
  const QrCameraScreen({Key? key}) : super(key: key);

  @override
  State<QrCameraScreen> createState() => _QrCameraScreenState();
}

class _QrCameraScreenState extends State<QrCameraScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Di chuyển camera đến mã QR', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (!_isScanned) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  _isScanned = true;
                  final String code = barcodes.first.rawValue!;
                  Navigator.pop(context, code);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          )
        ],
      ),
    );
  }
}