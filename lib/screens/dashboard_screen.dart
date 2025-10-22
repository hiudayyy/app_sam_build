import 'dart:convert';

import 'package:csam_mobile/api/api_caytrong.dart';
import 'package:csam_mobile/api/api_dashboard.dart';
import 'package:csam_mobile/api/api_thongbao.dart';
import 'package:csam_mobile/screens/plant_management_view_screen.dart';
import 'package:csam_mobile/screens/plants_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../models/cay_sam.dart';
import '../models/dashboard/dashboard_model.dart';
import '../models/kttoken.dart';
import '../models/response_model.dart';
import '../models/thongbao_model.dart';
import '../models/user.dart';
import '../models/vuontrong/caysam_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/listcaysam.dart';
import '../widgets/listcayyeu.dart';
import '../widgets/listlosam.dart';
import '../widgets/notification_panel.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  final List<CaySam> plants;

  const DashboardScreen({
    Key? key,
    required this.plants,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  DashBoardtotal? numbertotal;
  DashBoardSucKhoe? numbertotalSucKhoe;
  late TabController _tabController;
  List<ThongBaoModel>? tb;
  List<LoSamModel>? _loSamCanhBaoList;
  bool _isLoadingCanhBao = true;
  Kttoken? user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
    _fetchLoSamCanhBao();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final api = API();
    final apifarm = await api.getDashBoardSam();
    final apisuckhoe = await api.getDashBoardSucKhoe();
    final thongbao = await API().listThongBao( status: 'TatCa',);
    if(thongbao?.message == "OK"){
      tb = thongbao?.items;
    }
    if (!mounted) return;
    if (apifarm?.oneItem != null) {
      setState(() {
        numbertotal = apifarm?.oneItem;
      });
    }
    if (apisuckhoe?.oneItem != null) {
      setState(() {
        numbertotalSucKhoe = apisuckhoe?.oneItem;
      });
    }
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
  }
  Future<void> _fetchLoSamCanhBao() async {
    if (!mounted) return;
    setState(() => _isLoadingCanhBao = true);
    try {
      // Gọi API của bạn (có thể thêm các tham số phân trang nếu cần)
      final result = await API().listLoSamCanhBao(top: 5); // Lấy tối đa 5 cảnh báo chẳng hạn
      if (mounted) {
        setState(() {
          _loSamCanhBaoList = result;
          _isLoadingCanhBao = false;
        });
      }
    } catch (e) {
      print("Lỗi khi tải LoSamCanhBao: $e");
      if (mounted) {
        setState(() => _isLoadingCanhBao = false);
        // Có thể hiển thị thông báo lỗi ở đây nếu muốn
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            // Tab Navigation
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard, size: 16),
                        SizedBox(width: 8),
                        Text('Tổng quan'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.notifications, size: 16),
                            if (tb != null && tb!.any((item) => !item.seen))
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 8),
                        Text('Thông báo'),
                      ],
                    ),
                  ),
                ],
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Theme.of(context).primaryColor,
                indicatorWeight: 3,
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Overview Tab
                  _buildOverviewTab(),

                  // Notifications Tab
                  NotificationPanel(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
        required Color color,
        VoidCallback? onTap,
      }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ✅ HÀM _buildOverviewTab ĐÃ ĐƯỢC THIẾT KẾ LẠI HOÀN TOÀN
  Widget _buildOverviewTab() {
    final totalPlants = widget.plants.length;
    final healthyPlants = widget.plants
        .where((p) => p.trangThai == TrangThaiCay.khoeMauh)
        .length;
    final weakPlants =
        widget.plants.where((p) => p.trangThai == TrangThaiCay.yeu).length;
    final sickPlants =
        widget.plants.where((p) => p.trangThai == TrangThaiCay.benh).length;
    final deadPlants =
        widget.plants.where((p) => p.trangThai == TrangThaiCay.chet).length;

    final healthPercentage = numbertotalSucKhoe?.HealthPercentage ?? 0;
    final healthColor = healthPercentage >= 80
        ? Colors.green
        : healthPercentage >= 60
        ? Colors.orange
        : Colors.red;

    final environmentStatus = {
      'temperature': {'value': 22, 'status': 'good', 'min': 20, 'max': 24},
      'humidity': {'value': 75, 'status': 'good', 'min': 70, 'max': 80},
      'soilMoisture': {'value': 68, 'status': 'warning', 'min': 60, 'max': 75},
    };

    return Scaffold( // Thêm Scaffold để có thể đổi màu nền
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ thống kê 2x2
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 25,
              mainAxisSpacing: 25,
              childAspectRatio: 1.3, // Điều chỉnh tỷ lệ cho bố cục dọc
              children: [
                if(user?.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) => pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin") ?? false)
                  _buildStatCard( // Widget is only added if the condition is true
                    context,
                    icon: Icons.business_rounded,
                    title: 'Tổng số vườn',
                    value: numbertotal?.totalVuonTrong.toString() ?? "0",
                    color: Colors.blue.shade700,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen(tabcurrent: 2)));
                    },
                  ),

                if (user?.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) => pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin") ?? false)
                _buildStatCard(
                  context,
                  icon: Icons.map_rounded,
                  title: 'Tổng số lô',
                  value: numbertotal?.totalLoSam.toString() ?? "0",
                  color: Colors.green.shade700,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DanhSachLoSamPage()));
                  },
                ),
                _buildStatCard(
                  context,
                  icon: Icons.eco_rounded,
                  title: 'Tổng số cây',
                  value: numbertotal?.totalCaySam.toString() ?? "0",
                  color: Colors.teal.shade600,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DanhSachCaySamPage()));
                  },
                ),
                _buildStatCard(
                  context,
                  icon: Icons.sentiment_dissatisfied_rounded,
                  title: 'Cây yếu',
                  value: numbertotal?.totalSuckhoeYeu.toString() ?? "0",
                  color: Colors.orange.shade800,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DanhSachCayYeuPage()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 22),
                        SizedBox(width: 8),
                        Text('Tổng quan sức khỏe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Tình trạng tổng thể', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                        const Spacer(),
                        Text('${healthPercentage.round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: healthColor)), // Có thể đổi chữ "Khỏe mạnh" thành "Tốt"
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: healthPercentage / 100,
                        backgroundColor: healthColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                        minHeight: 10,
                      ),
                    ),
                    const Divider(height: 32),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.7,
                      children: [
                        _buildHealthStatItem('Rất tốt', numbertotalSucKhoe?.totalRatTot ?? 0, Colors.green.shade600, Icons.sentiment_very_satisfied_rounded), // Điểm 5
                        _buildHealthStatItem('Khá tốt', numbertotalSucKhoe?.totalKhaTot ?? 0 , Colors.teal.shade500, Icons.sentiment_satisfied_rounded), // Điểm 4
                        _buildHealthStatItem('Trung bình', numbertotalSucKhoe?.totalTrungBinh ?? 0, Colors.orange.shade600, Icons.sentiment_neutral_rounded), // Điểm 3
                        _buildHealthStatItem('Yếu', numbertotalSucKhoe?.totalYeu ?? 0, Colors.deepOrange.shade500, Icons.sentiment_dissatisfied_rounded), // Điểm 2
                        _buildHealthStatItem('Rất yếu', numbertotalSucKhoe?.totalRatYeu ?? 0, Colors.red.shade700, Icons.sentiment_very_dissatisfied_rounded), // Điểm 1
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tình trạng môi trường', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Dữ liệu từ cảm biến thời gian thực', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    const Divider(height: 24),
                    _buildEnvironmentItem(
                      icon: Icons.thermostat_rounded,
                      iconColor: Colors.red,
                      label: 'Nhiệt độ',
                      value: '${environmentStatus['temperature']!['value']}°C',
                      status: environmentStatus['temperature']!['status'] as String,
                      range: '${environmentStatus['temperature']!['min']}-${environmentStatus['temperature']!['max']}°C',
                    ),
                    const SizedBox(height: 12),
                    _buildEnvironmentItem(
                      icon: Icons.water_drop_outlined,
                      iconColor: Colors.blue,
                      label: 'Độ ẩm không khí',
                      value: '${environmentStatus['humidity']!['value']}%',
                      status: environmentStatus['humidity']!['status'] as String,
                      range: '${environmentStatus['humidity']!['min']}-${environmentStatus['humidity']!['max']}%',
                    ),
                    const SizedBox(height: 12),
                    _buildEnvironmentItem(
                      icon: Icons.grass_rounded,
                      iconColor: Colors.brown,
                      label: 'Độ ẩm đất',
                      value: '${environmentStatus['soilMoisture']!['value']}%',
                      status: environmentStatus['soilMoisture']!['status'] as String,
                      range: '${environmentStatus['soilMoisture']!['min']}-${environmentStatus['soilMoisture']!['max']}%',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            if (user?.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) => pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin") ?? false)
            Card(
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (giữ nguyên)
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 22, color: Colors.orange.shade700),
                        const SizedBox(width: 10),
                        const Text(
                          'Cảnh báo cần xử lý', // Có thể đổi tiêu đề nếu muốn
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _isLoadingCanhBao
                        ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                        : (_loSamCanhBaoList == null || _loSamCanhBaoList!.isEmpty)
                        ? SizedBox()
                        : Column(
                      children: _loSamCanhBaoList!.map((loSam) {
                        return _buildAlertItem(
                          icon: Icons.eco_outlined,
                          iconColor: Colors.orange.shade600,
                          title: 'Lô: ${loSam.tenLo ?? loSam.maLo}',
                          subtitle: '${loSam.soLuongCaySams} cây cần cập nhật nhật ký',
                          caySams: loSam.caySams,
                          idzone:loSam.loSamId,
                        );
                      }).toList(),
                    ),

                    _buildAlertItem(
                      icon: Icons.water_drop_outlined,
                      iconColor: Colors.blue.shade600,
                      title: 'Độ ẩm đất vùng B thấp',
                      subtitle: 'Cần tưới nước - 1 giờ trước',
                    ),
                    _buildAlertItem(
                      icon: Icons.shield_outlined,
                      iconColor: Colors.green.shade600,
                      title: 'Xác thực chất lượng hoàn thành',
                      subtitle: '5 cây đạt chuẩn xuất khẩu - 30 phút trước',
                      isLastItem: true, // Item cuối cùng
                    ),
// ...
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHealthStatItem(String title, int count, Color color, IconData icon) {
    return Container(
      // ✨ GIẢM PADDING DỌC
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // Giảm padding dọc từ 12 xuống 10
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28), // Giữ nguyên icon
          // ✨ GIẢM KHOẢNG TRỐNG
          const SizedBox(height: 6), // Giảm từ 8 xuống 6
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1, // Đảm bảo số không xuống dòng
            overflow: TextOverflow.ellipsis,
          ),
          // ✨ GIẢM KHOẢNG TRỐNG
          const SizedBox(height: 2), // Giảm từ 4 xuống 2
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            maxLines: 1, // Đảm bảo tiêu đề không xuống dòng
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  Widget _buildEnvironmentItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String status,
    required String range,
  }) {
    final statusColor = status == 'good' ? Colors.green : (status == 'warning' ? Colors.orange : Colors.red);
    final statusText = status == 'good' ? 'Tốt' : (status == 'warning' ? 'Cảnh báo' : 'Nguy hiểm');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('Ngưỡng: $range', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ HÀM _buildAlertItem ĐÃ ĐƯỢỢC CẬP NHẬT VỚI MÀU NỀN THEO LOẠI CẢNH BÁO
  // ✅ HÀM _buildAlertItem ĐÃ ĐƯỢC CẬP NHẬT ĐỂ HIỂN THỊ VỊ TRÍ CÂY
  Widget _buildAlertItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    List<CaySamModel>? caySams, // ✨ THÊM LẠI: Tham số tùy chọn
    bool isLastItem = false,
    int? idzone,
  }) {
    // Logic xác định màu nền thẻ (giữ nguyên)
    Color cardBackgroundColor = Colors.white;
    if (iconColor == Colors.orange.shade600 || iconColor == Colors.red.shade600 || iconColor == Colors.orange.shade700) {
      cardBackgroundColor = iconColor.withOpacity(0.08);
    } else if (iconColor == Colors.green.shade600) {
      cardBackgroundColor = Colors.green.shade50.withOpacity(0.5);
    }
    String plantPositionsInfo = '';
    if (caySams != null && caySams.isNotEmpty) {
      var positionsList = caySams
          .map((cs) => cs.viTriTrongLo)
          .whereType<String>()
          .take(4)
          .toList();
      String positionsToShow = positionsList.join(', ');
      int maxLength = 30; // 👈
      if (positionsToShow.length > maxLength) {
        positionsToShow = '${positionsToShow.substring(0, maxLength)}...'; // Cắt và thêm ...
      }
      final moreCount = caySams.length > positionsList.length ? ' +${caySams.length - positionsList.length}' : '';
      plantPositionsInfo = '\nCây $positionsToShow$moreCount chưa cập nhật ký trong nhiều tháng';
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: isLastItem ? 0 : 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withOpacity(0.05),
      color: cardBackgroundColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Khai báo biến trước
          LoSamModel? losamitem;

// Chỉ thực hiện nếu có idzone
          if(idzone != null){
            // 1. Hiển thị dialog loading
            showLoadingDialog(context, message: 'Đang tải dữ liệu lô...');

            try {
              // 2. Gọi API và chờ kết quả
              losamitem = await API().getLoSamById(idzone);

              // 3. Đóng dialog loading (nếu widget vẫn còn)
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop(); // Đóng dialog
              }
              if (!mounted) return; // Thoát nếu widget bị hủy

              // 4. Thực hiện điều hướng sau khi có dữ liệu và đóng dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    tabcurrent: 2,
                    shouldShowDialog: true,
                    zone: losamitem, // Truyền dữ liệu đã lấy được
                  ),
                ),
              );

            } catch (e) {
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop(); // Đóng dialog
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi tải dữ liệu lô: $e'),
                  backgroundColor: Colors.red,
                ),
              );
              print("Lỗi khi gọi getLoSamById: $e");
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Row(
            children: [
              // Chỉ báo màu dọc (giữ nguyên)
              Container(
                width: 5,
                height: 45,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),

              // Icon (giữ nguyên)
              CircleAvatar(
                radius: 20,
                backgroundColor: iconColor.withOpacity(0.15),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Tiêu đề và Phụ đề (cập nhật subtitle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // ✨ Nối chuỗi thông tin vị trí vào subtitle
                      '$subtitle$plantPositionsInfo',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      // Tăng maxLines để đủ chỗ hiển thị vị trí
                      maxLines: plantPositionsInfo.isNotEmpty ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Icon điều hướng (giữ nguyên)
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHealthIndicator(
      BuildContext context, String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.03,
          height: MediaQuery.of(context).size.width * 0.03,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width * 0.01),
        Text(
          label,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.035,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width * 0.005),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusBadgeColor(String status) {
    switch (status) {
      case 'good':
        return Colors.green.shade600;
      case 'warning':
        return Colors.yellow.shade600;
      case 'critical':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'good':
        return Colors.green.shade100;
      case 'warning':
        return Colors.yellow.shade100;
      case 'critical':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

}
