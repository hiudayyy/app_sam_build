import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:nftsam/api/api_caysam.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../api/api.dart';
import '../models/cay_sam.dart';
import '../models/nhat_ky.dart';
import '../models/vuontrong/caysam_model.dart';
import '../widgets/fullscreenimageviewer.dart';

import '/app_config.dart';

// Class chứa thông tin hiển thị sensor
class SensorDisplayInfo {
  final String temp;
  final String humidity;
  final String soil;
  final String dew;

  // Màu sắc cảnh báo
  final Color tempColor;
  final Color humColor;
  final Color soilColor;
  final Color dewColor;

  SensorDisplayInfo({
    this.temp = "N/A",
    this.humidity = "N/A",
    this.soil = "N/A",
    this.dew = "N/A",
    this.tempColor = Colors.orange,
    this.humColor = Colors.blue,
    this.soilColor = Colors.brown,
    this.dewColor = Colors.cyan,
  });
}

class DiaryListScreen extends StatefulWidget {
  final CaySamModel plant;
  final VoidCallback onBack;

  DiaryListScreen({
    required this.plant,
    required this.onBack,
  });

  @override
  _DiaryListScreenState createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  bool showImages = true;
  late Future<List<CaySamNhatKy>> _diaryFuture;

  // Health point colors
  static const Map<int, Map<String, dynamic>> healthColors = {
    1: {
      'color': Color(0xFFE53935),
      'label': 'Rất yếu',
      'bg': Color(0xFFFFEBEE)
    },
    2: {'color': Color(0xFFFB8C00), 'label': 'Yếu', 'bg': Color(0xFFFFF3E0)},
    3: {'color': Color(0xFFFDD835), 'label': 'TB', 'bg': Color(0xFFFFFDE7)},
    4: {'color': Color(0xFF1E88E5), 'label': 'Tốt', 'bg': Color(0xFFE3F2FD)},
    5: {
      'color': Color(0xFF43A047),
      'label': 'Rất tốt',
      'bg': Color(0xFFE8F5E8)
    },
  };

  @override
  void initState() {
    super.initState();
    _diaryFuture = API().getNhatKysbyid(widget.plant.caySamId);
  }

  // --- HÀM XỬ LÝ SENSOR (Logic không đổi) ---
  SensorDisplayInfo _processSensorData(List<dynamic>? sensors) {
    if (sensors == null || sensors.isEmpty) return SensorDisplayInfo();

    double? temp, hum, soil, dew;

    for (var sensor in sensors) {
      try {
        if (sensor.jsonValue != null && sensor.jsonValue != "") {
          final Map<String, dynamic> data = jsonDecode(sensor.jsonValue);

          // 1. Độ ẩm đất (A1)
          if (data.containsKey('A1')) {
            soil = (data['A1'] as num).toDouble();
          }
          // 2. Nhiệt độ
          if (data.containsKey('Temperature')) {
            temp = (data['Temperature'] as num).toDouble();
          }
          // 3. Độ ẩm không khí
          if (data.containsKey('Humidity')) {
            hum = (data['Humidity'] as num).toDouble();
          }
          // 4. Điểm sương
          if (data.containsKey('DewPoint')) {
            dew = (data['DewPoint'] as num).toDouble();
          }
        }
      } catch (e) {
        AppConfig.printEx('Error parsing sensor JSON: $e');
      }
    }

    return SensorDisplayInfo(
      temp: temp?.toStringAsFixed(1) ?? "N/A",
      humidity: hum?.toStringAsFixed(0) ?? "N/A",
      soil: soil?.toStringAsFixed(0) ?? "N/A",
      dew: dew?.toStringAsFixed(1) ?? "N/A",
      tempColor: (temp != null && temp > 35) ? Colors.red : Colors.orange,
    );
  }

  String? getHealthTrend(int currentHealth, int? previousHealth) {
    if (previousHealth == null) return null;
    if (currentHealth > previousHealth) return 'up';
    if (currentHealth < previousHealth) return 'down';
    return 'stable';
  }

  String formatRelativeDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "";
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      if (difference == 0) return 'Hôm nay';
      if (difference == 1) return 'Hôm qua';
      if (difference < 7) return '$difference ngày trước';
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scale = (screenWidth / 375.0).clamp(0.85, 1.15);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Column(
        children: [
          // === HEADER ===
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10 * scale,
              left: 16 * scale,
              right: 16 * scale,
              bottom: 20 * scale,
            ),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24 * scale),
                  bottomRight: Radius.circular(24 * scale),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: Colors.white, size: 24 * scale),
                      onPressed: widget.onBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Text(
                        'Nhật ký sinh trưởng',
                        style: TextStyle(
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => showImages = !showImages),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10 * scale, vertical: 6 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                                showImages
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white,
                                size: 14 * scale),
                            SizedBox(width: 4 * scale),
                            Text(
                              showImages ? 'Ẩn ảnh' : 'Hiện ảnh',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 16 * scale),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8 * scale),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: Icon(Icons.qr_code,
                          color: Colors.white, size: 20 * scale),
                    ),
                    SizedBox(width: 12 * scale),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.plant.maCaySam ?? "N/A",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w800)),
                        const Text("Mã định danh",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),

          // === BODY CONTENT ===
          Expanded(
            child: FutureBuilder<List<CaySamNhatKy>>(
              future: _diaryFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text("Lỗi tải dữ liệu"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final diaryEntries = snapshot.data ?? [];

                final totalEntries = diaryEntries.length;
                final avgHealth = diaryEntries.isNotEmpty
                    ? (diaryEntries.fold<double>(
                            0.0, (sum, entry) => sum + entry.diemSucKhoe) /
                        totalEntries)
                    : 0.0;
                final healthTrend = diaryEntries.length >= 2
                    ? getHealthTrend(diaryEntries[0].diemSucKhoe,
                        diaryEntries[1].diemSucKhoe)
                    : null;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      16 * scale, 20 * scale, 16 * scale, 30 * scale),
                  child: Column(
                    children: [
                      // --- SUMMARY CARD ---
                      Container(
                        margin: EdgeInsets.only(bottom: 24 * scale),
                        padding: EdgeInsets.all(16 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16 * scale),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 15,
                                offset: const Offset(0, 5))
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildSummaryItem(Icons.folder_copy_outlined,
                                "$totalEntries", "Bản ghi", Colors.blue, scale),
                            Container(
                                width: 1,
                                height: 40 * scale,
                                color: Colors.grey.shade200),
                            _buildSummaryItem(
                                Icons.star_rounded,
                                avgHealth.toStringAsFixed(1),
                                "Điểm TB",
                                Colors.orange,
                                scale),
                            Container(
                                width: 1,
                                height: 40 * scale,
                                color: Colors.grey.shade200),
                            _buildSummaryItem(
                                healthTrend == 'up'
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                healthTrend == 'up'
                                    ? "Tốt lên"
                                    : (healthTrend == 'down' ? "Giảm" : "--"),
                                "Xu hướng",
                                healthTrend == 'up'
                                    ? Colors.green
                                    : Colors.grey,
                                scale),
                          ],
                        ),
                      ),

                      // --- TIMELINE LIST ---
                      if (diaryEntries.isEmpty)
                        _buildEmptyState(scale)
                      else
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: diaryEntries.length,
                          itemBuilder: (context, index) {
                            final entry = diaryEntries[index];
                            final healthInfo =
                                healthColors[entry.diemSucKhoe] ??
                                    healthColors[5]!;
                            final bool isLast =
                                index == diaryEntries.length - 1;

                            // --- [FIX AN TOÀN] Lấy sensor đầu tiên ---
                            final sensorList =
                                entry.caySamNhatKy_SensorReadings;
                            final firstSensor =
                                (sensorList != null && sensorList.isNotEmpty)
                                    ? sensorList.first
                                    : null;

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Cột Ngày Tháng
                                  Column(
                                    children: [
                                      Container(
                                        width: 50 * scale,
                                        margin:
                                            EdgeInsets.only(bottom: 4 * scale),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              entry.ngayGhi != null
                                                  ? DateFormat('dd').format(
                                                      DateTime.parse(
                                                          entry.ngayGhi!))
                                                  : '',
                                              style: TextStyle(
                                                  fontSize: 18 * scale,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87),
                                            ),
                                            Text(
                                              entry.ngayGhi != null
                                                  ? "Thg ${DateFormat('MM').format(DateTime.parse(entry.ngayGhi!))}"
                                                  : '',
                                              style: TextStyle(
                                                  fontSize: 11 * scale,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // 2. Cột Timeline
                                  SizedBox(
                                    width: 30 * scale,
                                    child: Column(
                                      children: [
                                        Container(
                                          margin:
                                              EdgeInsets.only(top: 4 * scale),
                                          width: 12 * scale,
                                          height: 12 * scale,
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: healthInfo['color']
                                                      as Color,
                                                  width: 2.5),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                    color: (healthInfo['color']
                                                            as Color)
                                                        .withOpacity(0.3),
                                                    blurRadius: 4)
                                              ]),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              color: Colors.grey.shade300,
                                            ),
                                          )
                                      ],
                                    ),
                                  ),

                                  // 3. Nội dung Card
                                  Expanded(
                                    child: Container(
                                      margin:
                                          EdgeInsets.only(bottom: 20 * scale),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12 * scale),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.04),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3))
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12 * scale),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            children: [
                                              // Strip màu
                                              Container(
                                                width: 5 * scale,
                                                color: healthInfo['color'],
                                              ),
                                              // Content
                                              Expanded(
                                                child: Padding(
                                                  padding: EdgeInsets.all(
                                                      12 * scale),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Header card
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            formatRelativeDate(
                                                                entry.ngayGhi),
                                                            style: TextStyle(
                                                                fontSize:
                                                                    11 * scale,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                color: Colors
                                                                    .grey[500]),
                                                          ),
                                                          Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        8 *
                                                                            scale,
                                                                    vertical: 2 *
                                                                        scale),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: (healthInfo[
                                                                          'color']
                                                                      as Color)
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                            ),
                                                            child: Text(
                                                              "${healthInfo['label']}",
                                                              style: TextStyle(
                                                                  fontSize: 10 *
                                                                      scale,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: healthInfo[
                                                                      'color']),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                      SizedBox(
                                                          height: 8 * scale),

                                                      // Stats (Sức khỏe / Số lá)
                                                      Row(
                                                        children: [
                                                          Icon(Icons.eco,
                                                              size: 14 * scale,
                                                              color:
                                                                  Colors.green),
                                                          SizedBox(
                                                              width: 4 * scale),
                                                          Text(
                                                              "${entry.soLa} lá",
                                                              style: TextStyle(
                                                                  fontSize: 13 *
                                                                      scale,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600)),
                                                          SizedBox(
                                                              width:
                                                                  16 * scale),
                                                          Icon(Icons.favorite,
                                                              size: 14 * scale,
                                                              color: Colors
                                                                  .redAccent),
                                                          SizedBox(
                                                              width: 4 * scale),
                                                          Text(
                                                              "${entry.diemSucKhoe}/5 điểm",
                                                              style: TextStyle(
                                                                  fontSize: 13 *
                                                                      scale,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600)),
                                                        ],
                                                      ),

                                                      // --- [MỚI - ĐÃ SỬA LỖI] PHẦN HIỂN THỊ SENSOR ---
                                                      if (firstSensor != null &&
                                                          ((firstSensor
                                                                          .nhietDo ??
                                                                      0) !=
                                                                  0 ||
                                                              (firstSensor.doAmKK ??
                                                                      0) !=
                                                                  0 ||
                                                              (firstSensor.doAmDat ??
                                                                      0) !=
                                                                  0))
                                                        _buildSensorInfo(
                                                            firstSensor, scale),

                                                      SizedBox(
                                                          height: 8 * scale),
                                                      Divider(
                                                          height: 1,
                                                          color: Colors
                                                              .grey.shade200),
                                                      SizedBox(
                                                          height: 8 * scale),

                                                      // Ghi chú
                                                      if (entry.ghiChu !=
                                                              null &&
                                                          entry.ghiChu!
                                                              .isNotEmpty)
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              EdgeInsets.all(
                                                                  8 * scale),
                                                          margin:
                                                              EdgeInsets.only(
                                                                  bottom: 12 *
                                                                      scale),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.grey[50],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(6 *
                                                                        scale),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text("Ghi chú:",
                                                                  style: TextStyle(
                                                                      fontSize: 11 *
                                                                          scale,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                              .grey[
                                                                          700])),
                                                              SizedBox(
                                                                  height: 2 *
                                                                      scale),
                                                              Text(
                                                                entry.ghiChu!,
                                                                style: TextStyle(
                                                                    fontSize: 12 *
                                                                        scale,
                                                                    color: Colors
                                                                        .black87),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                      // HÌNH ẢNH
                                                      if (showImages &&
                                                          (entry.hinhAnhTongQuan !=
                                                                  null ||
                                                              entry.hinhAnhChiTiet !=
                                                                  null)) ...[
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            if (entry
                                                                    .hinhAnhTongQuan !=
                                                                null)
                                                              _buildThumbImage(
                                                                  context,
                                                                  entry
                                                                      .hinhAnhTongQuan!,
                                                                  "Hình ảnh tổng quan",
                                                                  scale),
                                                            if (entry.hinhAnhTongQuan !=
                                                                    null &&
                                                                entry.hinhAnhChiTiet !=
                                                                    null)
                                                              SizedBox(
                                                                  width: 8 *
                                                                      scale),
                                                            if (entry
                                                                    .hinhAnhChiTiet !=
                                                                null)
                                                              _buildThumbImage(
                                                                  context,
                                                                  entry
                                                                      .hinhAnhChiTiet!,
                                                                  "Hình ảnh chi tiết",
                                                                  scale),
                                                          ],
                                                        )
                                                      ]
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET CON: HIỂN THỊ THÔNG SỐ SENSOR ---
  Widget _buildSensorInfo(caySamNhatKy_SensorReading? info, double scale) {
    if (info == null) return SizedBox();

    // Helper function để lấy giá trị text an toàn
    String getValue(dynamic val, String unit) {
      if (val == null) return "0$unit";
      // Ép sang num rồi sang double để an toàn cho cả int và double
      return "${(val as num).toDouble().toStringAsFixed(1)}$unit"; // Lấy 1 số thập phân
      // Nếu muốn số nguyên thì dùng: return "${(val as num).round()}$unit";
    }

    return Container(
      margin: EdgeInsets.only(top: 8 * scale, bottom: 4 * scale),
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniSensorItem(Icons.thermostat_rounded,
              getValue(info.nhietDo, "°C"), Colors.orange, scale),
          _buildMiniSensorItem(Icons.water_drop_rounded,
              getValue(info.doAmKK, "%"), Colors.blue, scale),
          _buildMiniSensorItem(Icons.grass_rounded, getValue(info.doAmDat, "%"),
              Colors.brown, scale),
          _buildMiniSensorItem(Icons.opacity_rounded,
              getValue(info.diemSuong, "°C"), Colors.cyan, scale),
        ],
      ),
    );
  }

  Widget _buildMiniSensorItem(
      IconData icon, String value, Color color, double scale) {
    return Column(
      children: [
        Icon(icon, size: 16 * scale, color: color),
        SizedBox(height: 2 * scale),
        Text(value,
            style: TextStyle(
                fontSize: 10 * scale,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade700))
      ],
    );
  }
  // -----------------------------------------------------------

  Widget _buildSummaryItem(
      IconData icon, String value, String label, Color color, double scale) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22 * scale),
          SizedBox(height: 4 * scale),
          Text(value,
              style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          Text(label,
              style: TextStyle(
                  fontSize: 10 * scale,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildThumbImage(
      BuildContext context, String url, String label, double scale) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 2 * scale, bottom: 6 * scale),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11 * scale,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(imageUrl: url))),
            child: Hero(
              tag: url,
              child: Container(
                height: 140 * scale,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8 * scale),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8 * scale),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double scale) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 40 * scale),
          Icon(Icons.notes_rounded,
              size: 60 * scale, color: Colors.grey.shade300),
          SizedBox(height: 10 * scale),
          Text("Chưa có nhật ký nào",
              style: TextStyle(color: Colors.grey, fontSize: 14 * scale)),
        ],
      ),
    );
  }
}
