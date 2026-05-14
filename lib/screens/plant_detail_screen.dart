import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:nftsam/api/api_caysam.dart';
import 'package:nftsam/api/api_option.dart';
import 'package:nftsam/models/vuontrong/caysam_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../api/api.dart';
import '../models/kttoken.dart';
import '../models/nhat_ky.dart';
import '../models/moi_truong.dart';
import '../models/option_model.dart';
import '../models/xac_thuc.dart';
import '../utils/app_dimensions.dart';
import '../widgets/fullscreenimageviewer.dart';
import '../widgets/internalFileViewer.dart';
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
    required this.plant,
    this.diary,
    this.environment,
    this.verification,
    required this.onBack,
  }) : super(key: key);

  @override
  State<PlantDetailScreen> createState() => _State();
}

class _State extends State<PlantDetailScreen> {
  List<OptionModel> OptionLoSamLoaiTuoi = [];
  List<OptionModel> OptionLoSamTinhTrang = [];
  List<OptionModel> OptionLoSamDiemSucKhoe = [];
  Kttoken? user;
  late CaySamModel plantwidget;
  @override
  void initState() {
    super.initState();
    _initializeData();
    _incrementViewCount(widget.plant.caySamId.toString());
  }
  Future<void> _incrementViewCount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('plant_view_counts');
    Map<String, int> viewCounts = {};
    if (jsonString != null) {
      viewCounts = Map<String, int>.from(jsonDecode(jsonString));
    }
    viewCounts[id] = (viewCounts[id] ?? 0) + 1;
    await prefs.setString('plant_view_counts', jsonEncode(viewCounts));
  }
  void showLoadingDialog(BuildContext context,
      {String message = 'Đang xử lý...'}) {
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

  Future<void> ReloadDataCaySam(String caysamId) async {
    final data = await API().getCaySamById(caysamId);
    if (!mounted) return;
    if (data != null) {
      setState(() {
        plantwidget = data;
      });
    }
  }

  List<CaySamNhatKy> getCurrentMonthDiaryEntries() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final filtered = (plantwidget.caySamNhatKys ?? [])
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
    plantwidget = widget.plant;
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

  Map<String, Map<String, dynamic>> environmentStatus = {
    'temperature': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 10, 'max': 30},
    'humidity': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 80, 'max': 95},
    'soilMoisture': {
      'value': 'N/A',
      'status': 'Chưa rõ',
      'min': 100,
      'max': 200
    },
    'dewPoint': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 15, 'max': 25},
  };

  @override
  Widget build(BuildContext context) {
    final currentMonthEntries = getCurrentMonthDiaryEntries();
    final latestEntry = getLatestDiaryEntry(currentMonthEntries);

    // Calculate monthly statistics
    final totalEntries = currentMonthEntries.length;
    final avgHealth = currentMonthEntries.isNotEmpty
        ? (currentMonthEntries.fold<double>(
                        0.0, (sum, entry) => sum + entry.diemSucKhoe) /
                    currentMonthEntries.length)
                .round() /
            10.0
        : 0.0;
    final lastUpdate = latestEntry?.ngayGhi != null
        ? (DateTime.tryParse(latestEntry!.ngayGhi!) != null
            ? DateFormat('dd/MM/yyyy')
                .format(DateTime.parse(latestEntry.ngayGhi!))
            : 'Chưa có')
        : 'Chưa có';
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          // Custom Header with back button
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              bottom: 15,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF5F8670), // Màu Xanh Rêu Khói
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5F8670).withOpacity(0.4),
                  offset: const Offset(0, 8),
                  blurRadius: 15,
                  spreadRadius: -2,
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chi tiết cây',
                        style: TextStyle(
                          fontSize: (screenWidth * 0.05).clamp(16.0, 24.0),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2,
                              size: 16, color: Color(0xFFE8F5E9)),
                          const SizedBox(width: 6),
                          Text(
                            'ID: ${plantwidget.maCaySam ?? "N/A"}',
                            style: TextStyle(
                              // ID thường nhỏ hơn title chút (3.5% chiều rộng)
                              fontSize: (screenWidth * 0.035).clamp(12.0, 16.0),
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                  SizedBox(height: AppDimensions.fontSizeExtraSmall),

                  // Monthly Diary Summary
                  _buildMonthlyDiarySummary(
                      currentMonthEntries,
                      latestEntry,
                      totalEntries,
                      avgHealth,
                      lastUpdate,
                      plantwidget,
                      context),
                  SizedBox(height: 16),
                  _buildAttachmentSection(),
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
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height / 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[300],
        ),
        child: Builder(
          builder: (context) {
            String? imageUrl = latestEntry?.hinhAnhTongQuan;
            if (imageUrl == null && plantwidget.caySamNhatKys.isNotEmpty) {
              imageUrl = plantwidget.caySamNhatKys.first?.hinhAnhTongQuan;
            }
            Widget buildPlaceholder(
                {required IconData icon, String? message}) {
              return Container(
                color: Colors.grey[200], // Màu nền nhẹ hơn
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.grey[400], size: 40),
              );
            }

            final bool isClickable =
                (imageUrl != null && imageUrl.isNotEmpty);

            Widget imageWidget;

            if (!isClickable) {
              imageWidget = buildPlaceholder(icon: Icons.spa);
            } else {
              // Trường hợp 2: Dùng CachedNetworkImage
              imageWidget = CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => buildShimmerLoading(),
                errorWidget: (context, url, error) =>
                    buildPlaceholder(icon: Icons.broken_image_outlined),
                fadeInDuration: const Duration(milliseconds: 300),
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isClickable
                      ? () {
                          _showFullScreenImage(context, imageUrl!);
                        }
                      : null,
                  splashColor: Colors.white.withOpacity(0.3),
                  child: imageWidget,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showNfcWriterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return NfcWriterModal(plant: plantwidget);
      },
    );
  }

  Widget _buildBasicInfo() {
    double screenWidth = MediaQuery.of(context).size.width;
    double scale = (screenWidth / 375.0).clamp(0.85, 1.15);

    final int latestStatusValue = plantwidget.caySamNhatKys.isNotEmpty
        ? (plantwidget.caySamNhatKys.first?.tinhTrang ?? -1)
        : -1;

    final int latestHealthScore = plantwidget.caySamNhatKys.isNotEmpty
        ? (plantwidget.caySamNhatKys.first?.diemSucKhoe ?? -1)
        : -1;

    final bool daGhiNFC = plantwidget.isNFC ?? false;
    final bool isAdmin = user?.htTaiKhoan.htPhanQuyenTaiKhoans.any(
          (pq) => pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin",
        ) ??
        false;
    String tuoiCayText = OptionLoSamLoaiTuoi.firstWhere(
      (opt) => opt.value == plantwidget.tuoiCayId.toString(),
      orElse: () => OptionModel(value: "-1", text: "Chưa rõ"),
    ).text;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 4 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (Phần 1: Title & Header giữ nguyên) ...
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8 * scale),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8 * scale),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Icon(Icons.spa_rounded,
                          color: Colors.green.shade700, size: 20 * scale),
                    ),
                    SizedBox(width: 10 * scale),
                    Text(
                      'Thông tin chung',
                      style: TextStyle(
                        fontSize: 15 * scale,
                        fontWeight: FontWeight.w800,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    if (daGhiNFC) ...[
                      SizedBox(width: 8 * scale),
                      Icon(Icons.nfc_rounded,
                          size: 16 * scale, color: Colors.blue[600]),
                    ]
                  ],
                ),
                if (isAdmin)
                  _buildTechNfcButton(
                    isRecorded: daGhiNFC,
                    onTap: () => _showNfcWriterModal(context),
                    scale: scale,
                  ),
              ],
            ),

            SizedBox(height: 16 * scale),

            // ... (Phần 2: Mã định danh giữ nguyên) ...
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12 * scale),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Container(
                      padding: EdgeInsets.all(8 * scale),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Icon(Icons.qr_code_2_rounded,
                          size: 24 * scale, color: Colors.black87)),
                  SizedBox(width: 12 * scale),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mã định danh",
                          style: TextStyle(
                              fontSize: 10 * scale,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 2 * scale),
                      Text(
                        plantwidget.maCaySam ?? 'N/A',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 12 * scale),

            // === 3. GRID INFO (VỊ TRÍ - TUỔI - TRỌNG LƯỢNG - SỨC KHỎE) ===
            Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cột 1: Vị trí
                      Expanded(
                        child: _buildDetailBox(
                          icon: Icons.location_on_rounded,
                          iconColor: Colors.redAccent,
                          label: "Vị trí lô",
                          value: plantwidget.viTriTrongLo ?? '--',
                          scale: scale,
                        ),
                      ),
                      SizedBox(width: 8 * scale),

                      // Cột 2: Tuổi
                      Expanded(
                        child: _buildDetailBox(
                          icon: Icons.history_edu_rounded,
                          iconColor: Colors.orange,
                          label: "Độ tuổi",
                          value: tuoiCayText,
                          scale: scale,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8 * scale),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cột 3: Trọng lượng
                      Expanded(
                        child: _buildDetailBox(
                          icon: Icons.monitor_weight_rounded,
                          iconColor: Colors.teal,
                          label: "Trọng lượng",
                          value: plantwidget.caySamNhatKys.isNotEmpty
                              ? "${plantwidget.caySamNhatKys.first?.trongLuong ?? "--"} g"
                              : "--",
                          scale: scale,
                        ),
                      ),
                      SizedBox(width: 8 * scale),

                      // Cột 4: Sức khỏe
                      Expanded(
                        child: _buildDetailBox(
                          icon: Icons.favorite_rounded,
                          iconColor: getSucKhoeColor(latestHealthScore),
                          label: "Sức khỏe",
                          value: getSucKhoeText(latestHealthScore),
                          scale: scale,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12 * scale),

            // ... (Phần 4: Tình trạng giữ nguyên) ...
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale, vertical: 10 * scale),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monitor_heart_rounded,
                          color: Colors.blue, size: 18 * scale),
                      SizedBox(width: 8 * scale),
                      Text("Tình trạng hiện tại",
                          style: TextStyle(
                              fontSize: 12 * scale,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  _buildBeautifulStatusChip(latestStatusValue, scale),
                ],
              ),
            ),

            // ... (Phần 5: Blockchain giữ nguyên) ...
            if (plantwidget.blockChain != null &&
                plantwidget.blockChain!.isNotEmpty) ...[
              SizedBox(height: 12 * scale),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F0FF),
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link_rounded,
                            size: 14 * scale, color: Colors.purple),
                        SizedBox(width: 6 * scale),
                        Text(
                          "Blockchain Address",
                          style: TextStyle(
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.purple.shade400),
                        ),
                      ],
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      plantwidget.blockChain!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10 * scale,
                        color: Colors.purple.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required double scale,
  }) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 12 * scale),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start, // Label vẫn giữ ở góc trái cho đẹp
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- HÀNG TIÊU ĐỀ (Icon + Label) ---
          // Giữ nguyên phần này ở bên trái
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14 * scale, color: iconColor),
              SizedBox(width: 6 * scale),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: 8 * scale),

          // --- HÀNG GIÁ TRỊ (Căn Giữa) ---
          // ✨ THAY ĐỔI TẠI ĐÂY: Dùng Center để đưa số ra giữa ô
          Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign:
                  TextAlign.center, // Đảm bảo text căn giữa nếu bị xuống dòng
            ),
          ),
        ],
      ),
    );
  }

// 2. Nút NFC phong cách Tech/Chip
  Widget _buildTechNfcButton({
    required bool isRecorded,
    required VoidCallback onTap,
    required double scale,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8 * scale),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
        decoration: BoxDecoration(
          color: isRecorded ? Colors.blue.shade50 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(
            color: isRecorded ? Colors.blue.shade200 : Colors.green.shade200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRecorded ? Icons.nfc_rounded : Icons.add_link_rounded,
              size: 14 * scale,
              color: isRecorded ? Colors.blue.shade700 : Colors.green.shade700,
            ),
            SizedBox(width: 4 * scale),
            Text(
              isRecorded ? 'Ghi lại' : 'Ghi thẻ',
              style: TextStyle(
                fontSize: 11 * scale,
                fontWeight: FontWeight.bold,
                color:
                    isRecorded ? Colors.blue.shade700 : Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

// 3. Status Chip (Giữ nguyên logic đẹp từ trước)
  Widget _buildBeautifulStatusChip(int statusId, double scale) {
    String text;
    Color color;
    IconData icon;

    if (statusId == 1) {
      // Sống/Tốt
      text = "Đang phát triển";
      color = Colors.green;
      icon = Icons.check_circle_rounded;
    } else if (statusId == 2) {
      // Ngủ đông
      text = "Ngủ đông";
      color = Colors.blue;
      icon = Icons.ac_unit_rounded;
    } else if (statusId == 3) {
      // Chết
      text = "Đã chết";
      color = Colors.red;
      icon = Icons.cancel_rounded;
    } else {
      text = "Chưa cập nhật";
      color = Colors.grey;
      icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12 * scale, color: color),
          SizedBox(width: 4 * scale),
          Text(
            text,
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Hàm phụ trợ để mở dialog xem ảnh full màn hình
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true, // Bấm ra ngoài để đóng
      barrierColor: Colors.black.withOpacity(0.9), // Nền tối đi
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              // --- PHẦN THAY ĐỔI CHÍNH Ở ĐÂY ---
              InteractiveViewer(
                panEnabled: true, // Cho phép kéo
                minScale: 0.5,
                maxScale: 4.0,
                child: Container(
                  // Thêm Container màu đen để đảm bảo nền luôn tối
                  // kể cả khi ảnh đang load hoặc bị lỗi
                  color: Colors.black,
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) {
                        return Center(
                          child: CircularProgressIndicator(
                            value: downloadProgress
                                .progress, // Hiển thị tiến trình nếu muốn
                            color:
                                Colors.white, // Màu trắng cho nổi trên nền đen
                            strokeWidth: 3, // Độ dày vừa phải
                          ),
                        );
                      },

                      // 2. HIỂN THỊ KHI LỖI
                      errorWidget: (context, url, error) => const Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Căn giữa theo chiều dọc
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image,
                              color: Colors.white54, size: 60),
                          SizedBox(height: 12),
                          Text(
                            "Không thể tải ảnh",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // ------------------------------------
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 30),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyDiarySummary(
    List<CaySamNhatKy?> currentMonthEntries,
    CaySamNhatKy? latestEntry,
    int totalEntries,
    double avgHealth,
    String lastUpdate,
    CaySamModel plant,
    BuildContext context,
  ) {
    final now = DateTime.now();
    double screenWidth = MediaQuery.of(context).size.width;
    double scale = (screenWidth / 375.0).clamp(0.85, 1.15);

    // --- PARSE DỮ LIỆU MÔI TRƯỜNG AN TOÀN ---
    // Kiểm tra xem danh sách có dữ liệu không, nếu không có thì mặc định là 0
    final bool hasSensors = latestEntry?.caySamNhatKy_SensorReadings != null &&
        latestEntry!.caySamNhatKy_SensorReadings!.isNotEmpty;

    // Sử dụng giá trị từ phần tử đầu tiên nếu có, ngược lại gán bằng 0
    double temp = hasSensors
        ? (latestEntry.caySamNhatKy_SensorReadings!.first.nhietDo ?? 0.0)
        : 0.0;
    double dewPoint = hasSensors
        ? (latestEntry.caySamNhatKy_SensorReadings!.first.diemSuong ?? 0.0)
        : 0;
    double humidity = hasSensors
        ? (latestEntry.caySamNhatKy_SensorReadings!.first.doAmKK ?? 0)
        : 0;
    double soilMoisture = hasSensors
        ? (latestEntry.caySamNhatKy_SensorReadings!.first.doAmDat ?? 0)
        : 0;

    // --- LOGIC TÌNH TRẠNG CÂY ---
    String statusValue = latestEntry?.tinhTrang.toString() ?? "-1";
    final statusOption = OptionLoSamTinhTrang.firstWhere(
      (opt) => opt.value == statusValue,
      orElse: () => OptionModel(value: "-1", text: "Không rõ"),
    );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 4 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          children: [
            // === 1. HEADER (Giữ nguyên) ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8 * scale),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8 * scale),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Icon(Icons.calendar_month_rounded,
                          color: Colors.blue[700], size: 20 * scale),
                    ),
                    SizedBox(width: 10 * scale),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "THÁNG ${now.month}/${now.year}",
                          style: TextStyle(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w800,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          latestEntry != null
                              ? "Cập nhật: $lastUpdate"
                              : "--/--/----",
                          style: TextStyle(
                              fontSize: 11 * scale, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildOutlinedButton(
                  label: "Lịch sử",
                  icon: Icons.history_rounded,
                  color: Colors.blue[700]!,
                  borderColor: Colors.blue.shade200,
                  onTap: _handleDiaryListClick,
                  scale: scale,
                ),
              ],
            ),

            // === 2. NÚT ADMIN ACTION ===
            if (user?.htTaiKhoan.htPhanQuyenTaiKhoans.any(
                  (pq) =>
                      pq.maVaiTro != "nft_invester" &&
                      pq.maVaiTro == "nft_admin",
                ) ??
                false) ...[
              SizedBox(height: 16 * scale),
              Row(
                children: [
                  if (latestEntry != null) ...[
                    Expanded(
                      child: _buildTonalButton(
                        label: "Cập nhật",
                        icon: Icons.edit_rounded,
                        color: Colors.orange.shade800,
                        bgColor: Colors.orange.shade50,
                        borderColor: Colors.orange.shade200,
                        onTap: () => _handleUpdateDiaryClick(plant, context),
                        scale: scale,
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                  ],
                  Expanded(
                    child: _buildSolidButton(
                      label: "Thêm mới",
                      icon: Icons.add_rounded,
                      color: Colors.white,
                      bgColor: Colors.green.shade600,
                      borderColor: Colors.green.shade800,
                      onTap: () => _handleAddDiaryClick(plant, context),
                      scale: scale,
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 16 * scale),

            // === 3. CHỈ SỐ MÔI TRƯỜNG ===
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale, vertical: 10 * scale),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12 * scale),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_cloudy_outlined,
                          size: 16 * scale, color: Colors.blueGrey),
                      SizedBox(width: 6 * scale),
                      Text(
                        "Chỉ số môi trường",
                        style: TextStyle(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade700),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * scale),
                  GridView.count(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3.2,
                    mainAxisSpacing: 4 * scale,
                    crossAxisSpacing: 8 * scale,
                    children: [
                      _buildEnvItem(
                          Icons.thermostat_rounded,
                          "Nhiệt độ",
                          "${temp % 1 == 0 ? temp.toInt() : temp}°C",
                          Colors.orange,
                          scale),
                      _buildEnvItem(
                          Icons.water_drop_rounded,
                          "Độ ẩm khí",
                          "${humidity % 1 == 0 ? humidity.toInt() : humidity}%",
                          Colors.blue,
                          scale),
                      _buildEnvItem(
                          Icons.opacity_rounded,
                          "Điểm sương",
                          "${dewPoint % 1 == 0 ? dewPoint.toInt() : dewPoint}°C",
                          Colors.cyan,
                          scale),
                      _buildEnvItem(
                          Icons.grass_rounded,
                          "Độ ẩm đất",
                          "${soilMoisture % 1 == 0 ? soilMoisture.toInt() : soilMoisture}%",
                          Colors.brown,
                          scale),
                    ],
                  ),
                ],
              ),
            ),

            // === 4. CHỈ SỐ SINH TRƯỞNG CỦA CÂY ===
            if (latestEntry != null) ...[
              SizedBox(height: 16 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                    vertical: 16 * scale, horizontal: 4 * scale),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    _buildStatItem(
                      "Sức khỏe",
                      getSucKhoeText(latestEntry.diemSucKhoe),
                      getSucKhoeColor(latestEntry.diemSucKhoe),
                      scale,
                    ),
                    Container(
                        height: 30 * scale,
                        width: 1,
                        color: Colors.grey.shade300),
                    _buildStatItem(
                        "Số lá", "${latestEntry.soLa}", Colors.green, scale),
                    Container(
                        height: 30 * scale,
                        width: 1,
                        color: Colors.grey.shade300),
                    Expanded(
                      child: Column(
                        children: [
                          Text("Tình trạng",
                              style: TextStyle(
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey.shade600)),
                          SizedBox(height: 4 * scale),
                          _buildStatusTag(
                              statusOption.text, latestEntry.tinhTrang, scale),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // === 5. HÌNH ẢNH MỚI NHẤT ===
              SizedBox(height: 16 * scale),
              Row(
                children: [
                  Icon(Icons.image_search_rounded,
                      size: 16 * scale, color: Colors.grey[800]),
                  SizedBox(width: 6 * scale),
                  Text(
                    'Hình ảnh thực tế',
                    style: TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800]),
                  ),
                ],
              ),
              SizedBox(height: 8 * scale),
              Row(
                children: [
                  if (latestEntry.hinhAnhTongQuan != null &&
                      latestEntry.hinhAnhTongQuan!.isNotEmpty)
                    Expanded(
                        child: _buildBorderedImageWithShimmer(context,
                            latestEntry.hinhAnhTongQuan!, "Tổng quan", scale)),
                  if (latestEntry.hinhAnhTongQuan != null &&
                      latestEntry.hinhAnhChiTiet != null)
                    SizedBox(width: 10 * scale),
                  if (latestEntry.hinhAnhChiTiet != null &&
                      latestEntry.hinhAnhChiTiet!.isNotEmpty)
                    Expanded(
                        child: _buildBorderedImageWithShimmer(context,
                            latestEntry.hinhAnhChiTiet!, "Chi tiết", scale)),
                ],
              ),
            ] else ...[
              // Empty State
              SizedBox(height: 20 * scale),
              Icon(Icons.insert_chart_outlined_rounded,
                  size: 40 * scale, color: Colors.grey[300]),
              SizedBox(height: 8 * scale),
              Text("Chưa có nhật ký ghi nhận",
                  style:
                      TextStyle(color: Colors.grey[400], fontSize: 12 * scale)),
            ],
          ],
        ),
      ),
    );
  }

// --- WIDGET HỖ TRỢ HIỂN THỊ MÔI TRƯỜNG ---
  Widget _buildEnvItem(
      IconData icon, String label, String value, Color color, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4 * scale),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14 * scale, color: color),
          ),
          SizedBox(width: 8 * scale),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 9 * scale,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueGrey[900]),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color borderColor,
    required VoidCallback onTap,
    required double scale,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(10 * scale), // Bo góc mềm hơn (8 -> 10)
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 7 * scale),
          decoration: BoxDecoration(
            // 1. Nền không để trắng tinh mà pha chút màu nhẹ (5%)
            color: color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10 * scale),
            // 2. Viền dày hơn xíu để rõ nét
            border: Border.all(color: borderColor, width: 1.2),
            // 3. ĐỔ BÓNG (KEY CHANGE): Tạo chiều sâu, hết phẳng
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15), // Bóng màu xanh nhạt
                offset: Offset(0, 3), // Bóng đổ xuống dưới
                blurRadius: 6, // Độ mờ của bóng
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon có thể thêm bóng nhẹ nếu thích cầu kỳ, ở đây giữ nguyên cho sạch
              Icon(icon, size: 15 * scale, color: color),
              SizedBox(width: 5 * scale),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w700, // Chữ đậm hơn chút
                  color: color,
                  letterSpacing: 0.3, // Giãn chữ nhẹ cho sang
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// 2. Nút Tonal (Cập nhật)
  Widget _buildTonalButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback? onTap,
    required double scale,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10 * scale),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10 * scale),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16 * scale, color: color),
            SizedBox(width: 4 * scale),
            Text(label,
                style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

// 3. Nút Solid (Thêm mới)
  Widget _buildSolidButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback? onTap,
    required double scale,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10 * scale),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10 * scale),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
                color: bgColor.withOpacity(0.3),
                offset: Offset(0, 3),
                blurRadius: 5),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16 * scale, color: color),
            SizedBox(width: 4 * scale),
            Text(label,
                style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

// 4. Widget Ảnh + Shimmer
  Widget _buildBorderedImageWithShimmer(
      BuildContext context, String url, String label, double scale) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(imageUrl: url))),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10 * scale),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9 * scale),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.broken_image, color: Colors.grey[300]),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(label,
            style: TextStyle(
                fontSize: 10 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600])),
      ],
    );
  }

// 5. Stat Item
  Widget _buildStatItem(String label, String value, Color color, double scale) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade600)),
          SizedBox(height: 4 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 8 * scale, color: color),
              SizedBox(width: 4 * scale),
              Text(value,
                  style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }

// 6. Status Tag
  Widget _buildStatusTag(String text, int statusId, double scale) {
    Color color;
    if (statusId == 1 ||
        text.toLowerCase().contains("sống") ||
        text.toLowerCase().contains("tốt")) {
      color = Colors.green;
    } else if (statusId == 2 || text.toLowerCase().contains("ngủ")) {
      color = Colors.blue;
    } else {
      color = Colors.red;
    }

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11 * scale, color: color, fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
              DateFormat('dd/MM/yyyy HH:mm')
                  .format(DateTime.parse(widget.environment!.ngayDo)),
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
                    value:
                        '${widget.environment!.luongMua.toStringAsFixed(1)}mm',
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
              DateFormat('dd/MM/yyyy')
                  .format(DateTime.parse(widget.verification!.ngayKiemDinh)),
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
                if (widget.verification!.ghiChu != null &&
                    widget.verification!.ghiChu!.isNotEmpty) ...[
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

  void _handleDiaryListClick() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryListScreen(
          plant: plantwidget, // 👈 truyền model CaySam
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

  void _handleAddPlantSubmit(Map<String, dynamic> plantData, List<File?> images,
      String? idcaysam) async {
    showLoadingDialog(context, message: 'Đang cập nhật nhật ký ...');

    try {
      final nhatKy = plantwidget.caySamNhatKys.isNotEmpty
          ? plantwidget.caySamNhatKys.first
          : null;

      // Biến để lưu kết quả API
      dynamic apiResponse;
      bool isEditing = false;
      bool isAddingDiary = false;

      // Quyết định hành động API sẽ được gọi
      if (nhatKy?.ngayGhi != null) {
        final ngayGhi = DateTime.tryParse(nhatKy!.ngayGhi!);
        final now = DateTime.now();

        if (ngayGhi != null &&
            ngayGhi.year == now.year &&
            ngayGhi.month == now.month) {
          // Trường hợp: Chỉnh sửa cây sâm
          isEditing = true;
          apiResponse = await API().editCaySam(
            id: plantwidget.caySamId,
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

      // Xử lý kết quả]
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
        if (idcaysam != null) {
          setState(() {
            ReloadDataCaySam(idcaysam);
          });
        }
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

  void _handleAddNhatKySubmit(Map<String, dynamic> plantData,
      List<File?> images, String? caysamid) async {
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
        if (caysamid != null)
          setState(() {
            ReloadDataCaySam(caysamid);
          });
      } else {
        // Lỗi từ server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Thêm nhật ký không thành công: ${apiResponse?.message ?? "Lỗi không xác định"}'),
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

  Widget buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, // Màu nền xám
      highlightColor: Colors.grey[100]!, // Màu sáng lướt qua
      child: Container(
        color: Colors.white, // Cần một container có màu để shimmer hoạt động
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildAttachmentSection() {
    final attachments = plantwidget.caySam_DinhKems ?? [];
    double screenWidth = MediaQuery.of(context).size.width;
    double scale = (screenWidth / 375.0).clamp(0.85, 1.15);
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8 * scale),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8 * scale),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Icon(Icons.folder_open_rounded,
                        color: Colors.blue[700], size: 20 * scale),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tài liệu đính kèm',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w700, // Đậm hơn chút
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // --- DANH SÁCH FILE ---
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attachments.length,
            separatorBuilder: (ctx, index) =>
                const SizedBox(height: 12), // Khoảng cách giữa các item
            itemBuilder: (context, index) {
              final item = attachments[index];

              // Xử lý dữ liệu
              final String url = item?.dinhKemFile ?? "";
              final String fileName =
                  url.isNotEmpty ? url.split('/').last : "Tài liệu không tên";

              String timeDisplay = "";
              if (item?.thoiGian != null) {
                try {
                  final date = DateTime.parse(item!.thoiGian.toString());
                  timeDisplay = DateFormat('dd/MM/yyyy • HH:mm')
                      .format(date); // Thêm dấu chấm ngăn cách
                } catch (e) {
                  timeDisplay = item?.thoiGian.toString() ?? "";
                }
              }

              // Logic Icon & Màu sắc
              IconData fileIcon = Icons.insert_drive_file_rounded;
              Color themeColor = Colors.blueGrey;
              String fileType = "FILE";

              if (fileName.toLowerCase().endsWith('.pdf')) {
                fileIcon = Icons.picture_as_pdf_rounded;
                themeColor = const Color(0xFFFF4D4D); // Đỏ nhẹ hiện đại
                fileType = "PDF";
              } else if (fileName.toLowerCase().endsWith('.jpg') ||
                  fileName.toLowerCase().endsWith('.png') ||
                  fileName.toLowerCase().endsWith('.jpeg')) {
                fileIcon = Icons.image_rounded;
                themeColor = const Color(0xFF4D96FF); // Xanh dương hiện đại
                fileType = "IMG";
              } else if (fileName.toLowerCase().endsWith('.doc') ||
                  fileName.toLowerCase().endsWith('.docx')) {
                fileIcon = Icons.description_rounded;
                themeColor = const Color(0xFF2B55CC); // Xanh Word
                fileType = "DOC";
              }

              // --- ITEM GIAO DIỆN HIỆN ĐẠI ---
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openAttachment(url),
                  borderRadius: BorderRadius.circular(16),
                  splashColor: themeColor.withOpacity(0.1),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // 1. Icon File trong hộp màu
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(fileIcon, color: themeColor, size: 24),
                              const SizedBox(height: 2),
                              Text(
                                fileType,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor,
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // 2. Thông tin file
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 12, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeDisplay,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Hàm xử lý mở file
  void _openAttachment(String url) {
    if (url.isEmpty) return;

    // Loại bỏ khoảng trắng
    final cleanUrl = url.trim();

    // Lấy tên file để hiển thị trên tiêu đề
    final String fileName = cleanUrl.split('/').last;

    // Điều hướng sang màn hình xem nội bộ
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InternalFileViewer(
          url: cleanUrl,
          fileName: fileName,
        ),
      ),
    );
  }

  Color getSucKhoeColor(int? diem) {
    switch (diem) {
      case 5:
        return Colors.green; // Rất tốt
      case 4:
        return Colors.lightGreen; // Tốt
      case 3:
        return Colors.orange; // Trung bình
      case 2:
        return Colors.deepOrange; // Yếu
      case 1:
        return Colors.red; // Rất yếu
      default:
        return Colors.grey; // Không xác định
    }
  }

  String getSucKhoeText(int? diem) {
    switch (diem) {
      case 5:
        return "Rất tốt";
      case 4:
        return "Tốt";
      case 3:
        return "Trung bình";
      case 2:
        return "Yếu";
      case 1:
        return "Rất yếu";
      default:
        return "N/A";
    }
  }
}
