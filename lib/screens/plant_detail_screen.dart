import 'dart:convert';
import 'dart:io';

import 'package:csam_mobile/api/api_caysam.dart';
import 'package:csam_mobile/api/api_caytrong.dart';
import 'package:csam_mobile/api/api_option.dart';
import 'package:csam_mobile/models/vuontrong/caysam_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../models/cay_sam.dart';
import '../models/kttoken.dart';
import '../models/nhat_ky.dart';
import '../models/moi_truong.dart';
import '../models/option_model.dart';
import '../models/xac_thuc.dart';
import '../data/mock_data.dart';
import '../widgets/fullscreenimageviewer.dart';
import '../widgets/nfcWriterScreen.dart';
import 'add_plant_screen.dart';
import 'diary_list_screen.dart';
class PlantDetailScreen extends StatefulWidget {
  final CaySamModel plant;
  final CaySamNhatKy? diary;
  final CaySamMoiTruong? environment;
  final CaySamXacThuc? verification;
  final VoidCallback onBack;


  const PlantDetailScreen({
    Key? key,
    // required this.plants,
    required this.plant,
    this.diary,
    this.environment,
    this.verification,
    required this.onBack,
  }) : super(key: key);

  @override
  State<PlantDetailScreen> createState() =>
      _State();
}

class _State extends State<PlantDetailScreen> {
  List<OptionModel> OptionLoSamLoaiTuoi = [];
  List<OptionModel> OptionLoSamTinhTrang = [];
  List<OptionModel> OptionLoSamDiemSucKhoe = [];
  Kttoken? user;
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  void showLoadingDialog(BuildContext context, {String message = 'Đang xử lý...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
  // Helper function to get current month diary entries
  List<CaySamNhatKy> getCurrentMonthDiaryEntries() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final filtered = (widget.plant.caySamNhatKys ?? [])
        .where((entry) {
      if (entry == null || entry.ngayGhi == null) return false;
      final entryDate = DateTime.tryParse(entry.ngayGhi!);
      if (entryDate == null) return false;

      return entryDate.month == currentMonth &&
          entryDate.year == currentYear;
    })
        .cast<CaySamNhatKy>()
        .toList();

    return filtered;
  }


  // Helper to get latest diary entry
  CaySamNhatKy? getLatestDiaryEntry(List<CaySamNhatKy?> entries) {
    if (entries.isEmpty) return null;

    entries.sort((a, b) {
      final dateA = DateTime.tryParse(a?.ngayGhi ?? '');
      final dateB = DateTime.tryParse(b?.ngayGhi ?? '');

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // a null -> b lớn hơn
      if (dateB == null) return -1; // b null -> a lớn hơn

      return dateB.compareTo(dateA);
    });

    return entries.first;
  }

  Future<void> _initializeData() async {
    final api = API();
    final apiOptinlt = await api.OptionLoSamLoaiTuoi();
    if (apiOptinlt != null) {
      setState(() {
        OptionLoSamLoaiTuoi = apiOptinlt;
      });
    }
    final apiOptintt = await api.OptionLoSamTinhTrang();
    if (apiOptintt != null) {
      setState(() {
        OptionLoSamTinhTrang = apiOptintt;
      });
    }
    final apiOptindsk = await api.OptionLoSamDiemSucKhoe();
    if (apiOptindsk != null) {
      setState(() {
        OptionLoSamDiemSucKhoe = apiOptindsk;
      });
    }
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthEntries = getCurrentMonthDiaryEntries();
    final latestEntry = getLatestDiaryEntry(currentMonthEntries);

    // Calculate monthly statistics
    final totalEntries = currentMonthEntries.length;
    final avgHealth = currentMonthEntries.isNotEmpty
        ? (currentMonthEntries.fold<double>(0.0, (sum, entry) => sum + entry!.diemSucKhoe) / currentMonthEntries.length).round() / 10.0
        : 0.0;
    final lastUpdate = latestEntry?.ngayGhi != null
        ? (DateTime.tryParse(latestEntry!.ngayGhi!) != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(latestEntry.ngayGhi!))
        : 'Chưa có')
        : 'Chưa có';


    return Scaffold(
      body: Column(
        children: [
          // Custom Header with back button
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        /*plant.tenCay ??*/ 'Chi tiết cây',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'ID: ${widget.plant.maCaySam}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant Image
                  _buildPlantImage(latestEntry),
                  SizedBox(height: 16),

                  // Basic Information
                  _buildBasicInfo(),
                  SizedBox(height: 16),

                  // Monthly Diary Summary
                  _buildMonthlyDiarySummary(
                      currentMonthEntries,
                      latestEntry,
                      totalEntries,
                      avgHealth,
                      lastUpdate,
                      widget.plant,
                      context
                  ),
                  SizedBox(height: 16),

                  // Environment Data (if available)
                  if (widget.environment != null) ...[
                    _buildEnvironmentSection(),
                    SizedBox(height: 16),
                  ],

                  // Verification Info (if available)
                  if (widget.verification != null) ...[
                    _buildVerificationSection(),
                    SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantImage(CaySamNhatKy? latestEntry) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[300],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              latestEntry?.hinhAnhTongQuan ??
                  'https://images.unsplash.com/photo-1589110254547-202e8e05be49?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxnaW5zZW5nJTIwcGxhbnRzJTIwY3VsdGl2YXRpb258ZW58MXx8fHwxNzU3MTMwNTkzfDA&ixlib=rb-4.1.0&q=80&w=800',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.eco,
                    color: Colors.grey[600],
                    size: 64,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // HÀM _buildBasicInfo ĐÃ ĐƯỢC THIẾT KẾ LẠI HOÀN TOÀN
  Widget _buildBasicInfo() {
    final latestStatusValue = widget.plant.caySamNhatKys.isNotEmpty
        ? widget.plant.caySamNhatKys.first?.tinhTrang?.toString()
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Tiêu đề section ---
             Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.eco_outlined, color: Colors.green, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Thông tin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NfcWriterScreen()),
                      );
                    },
                    child: const Text('Ghi thông tin cây vào thẻ NFC'),
                  )
                ],
              ),
            ),
            const Divider(height: 1),

            // --- Mã cây ---
            _buildInfoRow(
              icon: Icons.qr_code_2_rounded,
              label: 'Mã cây sâm',
              content: Text(
                widget.plant.maCaySam ?? 'Chưa có',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // --- Vị trí ---
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Vị trí',
              content: Text(
                widget.plant.viTriTrongLo ?? 'Chưa có',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // --- Tuổi cây ---
            _buildInfoRow(
              icon: Icons.timelapse_rounded,
              label: 'Tuổi cây',
              content: Text(
                OptionLoSamLoaiTuoi
                    .firstWhere(
                      (opt) => opt.value == widget.plant.tuoiCayId.toString(),
                  orElse: () => OptionModel(value: "-1", text: "Chưa rõ"),
                )
                    .text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // --- Tình trạng ---
            _buildInfoRow(
              icon: Icons.monitor_heart_outlined,
              label: 'Tình trạng',
              content: _buildStatusChip(latestStatusValue),
            ),

            // --- Blockchain (nếu có) ---
            if (widget.plant.blockChain != null &&
                widget.plant.blockChain!.isNotEmpty) ...[
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(Icons.link_rounded, color: Colors.purple.shade300),
                title: const Text(
                  'Blockchain ID',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                subtitle: Text(
                  widget.plant.blockChain!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyDiarySummary(
      List<CaySamNhatKy?> currentMonthEntries,
      CaySamNhatKy? latestEntry,
      int totalEntries,
      double avgHealth,
      String lastUpdate,
      CaySamModel plant,
      BuildContext context
      ) {
    final now = DateTime.now();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Nhật ký tháng ${now.month}/${now.year}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _handleDiaryListClick,
                      icon: const Icon(
                        Icons.list_alt_rounded,
                        size: 14,
                        color: Colors.blue,
                      ),
                      label: const Text(
                        'Lịch sử nhật ký',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.shade300, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.blue.shade50.withOpacity(0.2),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(Colors.blue.shade100.withOpacity(0.3)),
                      ),
                    ),
                    SizedBox(width: 8),
                    Row(
                      children: [
                        if (user?.htTaiKhoan.htPhanQuyenTaiKhoans.any(
                              (pq) => pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin",
                        ) ??
                            false) ...[
                          if (latestEntry?.hinhAnhChiTiet != null)
                            ElevatedButton(
                              onPressed: plant != null
                                  ? () => _handleUpdateDiaryClick(plant, context)
                                  : null, // ✅ chỉ gọi khi plant khác null
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 12),
                                  SizedBox(width: 4),
                                  Text('Cập nhật', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            onPressed: plant != null
                                ? () => _handleAddDiaryClick(plant, context)
                                : null, // ✅ an toàn hơn
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 12),
                                SizedBox(width: 4),
                                Text('Thêm mới', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    )
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),

            if (latestEntry != null) ...[
              // Latest Entry Summary
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Lần cập nhật cuối',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            lastUpdate,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Điểm sức khỏe',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getHealthColor(latestEntry.diemSucKhoe),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${latestEntry.diemSucKhoe}/5',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Số lá',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${latestEntry.soLa} lá',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Monthly Average
              if (totalEntries > 1) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Điểm sức khỏe trung bình tháng: ${avgHealth.toStringAsFixed(1)}/5',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      if (latestEntry.tinhTrang == "song")
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Còn sống',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                      if (latestEntry.tinhTrang == "ngudong")
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Ngủ đông',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      if (latestEntry.tinhTrang == "chet")
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Đã chết',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[800],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Detail Image
              if (latestEntry.hinhAnhChiTiet != null) ...[
                SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ảnh nhật ký gần nhất:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    // ✅ WIDGET Row ĐÃ ĐƯỢC CẬP NHẬT HOÀN CHỈNH
                    Row(
                      children: [
                        // ===================================
                        // ẢNH TỔNG QUAN
                        // ===================================
                        if (latestEntry.hinhAnhTongQuan != null && latestEntry.hinhAnhTongQuan!.isNotEmpty)
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageViewer(
                                      imageUrl: latestEntry.hinhAnhTongQuan!, // Dùng URL làm tag duy nhất
                                    ),
                                  ),
                                );
                              },
                              child: AspectRatio(
                                aspectRatio: 8 / 5, // Giữ tỷ lệ ảnh
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    // Bọc Image bằng Hero
                                    child: Hero(
                                      tag: latestEntry.hinhAnhTongQuan!,
                                      child: Image.network(
                                        latestEntry.hinhAnhTongQuan!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.image, size: 32);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(width: 8),

                        // ===================================
                        // ẢNH CHI TIẾT
                        // ===================================
                        if (latestEntry.hinhAnhChiTiet != null && latestEntry.hinhAnhChiTiet!.isNotEmpty)
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageViewer(
                                      imageUrl: latestEntry.hinhAnhChiTiet!,
                                    ),
                                  ),
                                );
                              },
                              child: AspectRatio(
                                aspectRatio: 8 / 5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    // Bọc Image bằng Hero
                                    child: Hero(
                                      tag: latestEntry.hinhAnhChiTiet!,
                                      child: Image.network(
                                        latestEntry.hinhAnhChiTiet!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.image, size: 32);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  ],
                ),
              ],
            ] else ...[
              // No diary entries this month
              Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Chưa có nhật ký nào trong tháng này',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat, color: Colors.orange[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Môi trường gần nhất',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(widget.environment!.ngayDo)),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildEnvironmentCard(
                    icon: Icons.thermostat,
                    label: 'Nhiệt độ',
                    value: '${widget.environment!.nhietDo.round()}°C',
                    color: Colors.red,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildEnvironmentCard(
                    icon: Icons.water_drop,
                    label: 'Độ ẩm KK',
                    value: '${widget.environment!.doAmKhongKhi.round()}%',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildEnvironmentCard(
                    icon: Icons.grass,
                    label: 'Độ ẩm đất',
                    value: '${widget.environment!.doAmDat.round()}%',
                    color: Colors.brown,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildEnvironmentCard(
                    icon: Icons.water,
                    label: 'Lượng mưa',
                    value: '${widget.environment!.luongMua.toStringAsFixed(1)}mm',
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.purple[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Xác thực chất lượng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.verification!.ngayKiemDinh)),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kết quả',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  widget.verification!.ketQuaKiemDinh,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.verification!.ghiChu != null && widget.verification!.ghiChu!.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    'Ghi chú',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    widget.verification!.ghiChu!,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(TrangThaiCay? status) {
    switch (status) {
      case TrangThaiCay.khoeMauh:
        return Colors.green;
      case TrangThaiCay.yeu:
        return Colors.yellow[700] ?? Colors.yellow;
      case TrangThaiCay.benh:
        return Colors.orange;
      case TrangThaiCay.chet:
        return Colors.red;
      default:
        return Colors.green;
    }
  }


  Color _getHealthColor(int health) {
    switch (health) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700] ?? Colors.yellow;
      case 4:
        return Colors.blue;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleDiaryListClick() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryListScreen(
          plant: widget.plant,   // 👈 truyền model CaySam
          onBack: () {
            Navigator.pop(context); // quay lại khi bấm back
          },
        ),
      ),
    );
  }


  void _handleUpdateDiaryClick(CaySamModel plant, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddPlantScreen(
          onSubmit: _handleAddPlantSubmit,
          onCancel: () {
            Navigator.of(context).pop();
          },
          gridPosition: plant.viTriTrongLo,
          losamId: plant.loSamId ?? 0,
          areaId: "",
          caysam: plant,
        ),
      ),
    );
  }
  void _handleAddDiaryClick(CaySamModel plant, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddPlantScreen(
          onSubmit: _handleAddNhatKySubmit,
          onCancel: () {
            Navigator.of(context).pop();
          },
          gridPosition: plant.viTriTrongLo,
          losamId: plant.loSamId ?? 0,
          EditNhatKy: "edit",
          areaId: "",
          caysam: plant,
        ),
      ),
    );
  }
  void _handleAddPlantSubmit(
      Map<String, dynamic> plantData,
      List<File?> images,
      ) async {
    showLoadingDialog(context, message: 'Đang cập nhật nhật ký ...');

    try {
      final nhatKy = widget.plant.caySamNhatKys.isNotEmpty ? widget.plant.caySamNhatKys.first : null;

      // Biến để lưu kết quả API
      dynamic apiResponse;
      bool isEditing = false;
      bool isAddingDiary = false;

      // Quyết định hành động API sẽ được gọi
      if (nhatKy?.ngayGhi != null) {
        final ngayGhi = DateTime.tryParse(nhatKy!.ngayGhi!);
        final now = DateTime.now();

        if (ngayGhi != null && ngayGhi.year == now.year && ngayGhi.month == now.month) {
          // Trường hợp: Chỉnh sửa cây sâm
          isEditing = true;
          apiResponse = await API().editCaySam(
            id: widget.plant.caySamId,
            data: plantData,
            files: images,
          );
        } else {
          // Trường hợp: Thêm nhật ký mới (nhánh 1)
          isAddingDiary = true;
          apiResponse = await API().addNhatKy(
            data: plantData,
            files: images,
          );
        }
      } else {
        // Trường hợp: Thêm nhật ký mới (nhánh 2)
        isAddingDiary = true;
        apiResponse = await API().addNhatKy(
          data: plantData,
          files: images,
        );
      }

      // Đóng dialog loading ngay sau khi API hoàn thành
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (!mounted) return;

      // Xử lý kết quả
      if (apiResponse != null && apiResponse.message == "OK") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? '🌱 Chỉnh sửa cây thành công!'
                  : '🌱 Đã thêm nhật ký mới cho cây!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onBack.call();
        Navigator.of(context).pop(); // Đóng màn hình hiện tại
        setState(() {
          // _futureLoSam = API().getLoSamById(selectedZone!.loSamId);
        });
      } else {
        // Lỗi từ server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Thao tác không thành công: ${apiResponse?.message ?? "Lỗi không xác định"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Đóng dialog nếu có lỗi mạng
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (!mounted) return;

      // Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _handleAddNhatKySubmit(
      Map<String, dynamic> plantData,
      List<File?> images,
      ) async {
    // Hiển thị dialog loading
    showLoadingDialog(context, message: 'Đang thêm nhật ký ...');

    try {
      // Gọi API
      final apiResponse = await API().addNhatKy(
        data: plantData,
        files: images,
      );

      // Đóng dialog loading
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (!mounted) return;

      // Xử lý kết quả
      if (apiResponse != null && apiResponse.message == "OK") {
        // Thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌱 Cây đã được thêm nhật ký!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onBack.call();
        Navigator.of(context).pop();
        setState(() {
          // _futureLoSam = API().getLoSamById(selectedZone!.loSamId);
        });
      } else {
        // Lỗi từ server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thêm nhật ký không thành công: ${apiResponse?.message ?? "Lỗi không xác định"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Đóng dialog nếu có lỗi
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (!mounted) return;

      // Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // HÀM HỖ TRỢ MỚI
  Widget _buildStatusChip(String? statusValue) {
    if (statusValue == null) {
      return const SizedBox.shrink(); // Không hiển thị gì nếu không có giá trị
    }

    final statusOption = OptionLoSamTinhTrang.firstWhere(
          (opt) => opt.value == statusValue,
      orElse: () => OptionModel(value: "-1", text: "Không rõ"),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getStatusChipColor(statusOption.value).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusOption.text,
        style: TextStyle(
          color: _getStatusChipColor(statusOption.value),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Color _getStatusChipColor(String statusValue) {
    switch (statusValue) {
      case '1': // Sống
        return Colors.green.shade700;
      case '2': // Ngủ đông
        return Colors.blue.shade700;
      case '3': // Chết
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required Widget content,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600, size: 24),
      title: Text(
        label,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
      ),
      trailing: content,
      dense: true,
    );
  }
}
