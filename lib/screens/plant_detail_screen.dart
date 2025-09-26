import 'dart:io';

import 'package:csam_mobile/api/api_caysam.dart';
import 'package:csam_mobile/api/api_caytrong.dart';
import 'package:csam_mobile/api/api_option.dart';
import 'package:csam_mobile/models/vuontrong/caysam_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api.dart';
import '../models/cay_sam.dart';
import '../models/nhat_ky.dart';
import '../models/moi_truong.dart';
import '../models/option_model.dart';
import '../models/xac_thuc.dart';
import '../data/mock_data.dart';
import 'add_plant_screen.dart';
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
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Helper function to get current month diary entries
  List<CaySamNhatKy?> getCurrentMonthDiaryEntries() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final filtered = (widget.plant.caySamNhatKys ?? [])
        .where((entry) {
      final entryDate = DateTime.parse(entry!.ngayGhi);
      return entryDate.month == currentMonth &&
          entryDate.year == currentYear;
    })
        .toList();
    return filtered;
  }

  // Helper to get latest diary entry
  CaySamNhatKy? getLatestDiaryEntry(List<CaySamNhatKy?> entries) {
    if (entries.isEmpty) return null;
    entries.sort((a, b) => DateTime.parse(b!.ngayGhi).compareTo(DateTime.parse(a!.ngayGhi)));
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
    final lastUpdate = latestEntry != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(latestEntry.ngayGhi))
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
                          fontSize: 16,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(TrangThaiCay.khoeMauh),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        _getStatusLabel(TrangThaiCay.khoeMauh),
                        style: TextStyle(fontSize: 12),
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

  Widget _buildBasicInfo() {

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: Colors.green[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Thông tin cơ bản',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã cây sâm',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        widget.plant.maCaySam ??'Chưa xác định',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tình trạng',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        widget.plant.caySamNhatKys.isNotEmpty
                            ? OptionLoSamTinhTrang
                            .firstWhere(
                              (opt) =>
                          opt.value ==
                              widget.plant.caySamNhatKys.first?.tinhTrang?.toString(),
                          orElse: () => OptionModel(value: "-1", text: "Chưa xác định"),
                        )
                            .text
                            : "Chưa xác định",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),



                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vị trí',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12),
                          SizedBox(width: 2),
                          Text(
                            widget.plant.viTriTrongLo ?? 'Chưa xác định',
                            style: TextStyle(
                              fontSize: 14,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tuổi cây',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        OptionLoSamLoaiTuoi
                            .firstWhere(
                              (opt) => opt.value == widget.plant.tuoiCayId.toString(),
                          orElse: () => OptionModel(value: "-1", text: "Chưa xác định"),
                        )
                            .text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (widget.plant.blockChain != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blockchain ID',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      widget.plant.blockChain!,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                Text(
                  '$totalEntries bản ghi trong tháng',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _handleDiaryListClick(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list, size: 12),
                          SizedBox(width: 4),
                          Text('List nhật ký', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleUpdateDiaryClick(plant,context),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 12),
                          SizedBox(width: 4),
                          Text('Cập nhật', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
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

              // Current Status
              SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tình trạng hiện tại:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
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
                    Row(
                      children: [
                        Container(
                          height: 120,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              latestEntry.hinhAnhTongQuan,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image, size: 32),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 5,),
                        Container(
                          height: 120,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              latestEntry.hinhAnhChiTiet,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image, size: 32),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
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
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _handleUpdateDiaryClick(plant, context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 4),
                            Text('Cập nhật nhật ký'),
                          ],
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

  String _getStatusLabel(TrangThaiCay? status) {
    switch (status) {
      case TrangThaiCay.khoeMauh:
        return 'Khỏe mạnh';
      case TrangThaiCay.yeu:
        return 'Yếu';
      case TrangThaiCay.benh:
        return 'Bệnh';
      case TrangThaiCay.chet:
        return 'Chết';
      default:
        return 'Khỏe mạnh';
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
    // TODO: Navigate to diary list view or open modal
    print('Show diary list for plant: ${widget.plant.caySamId}');
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
  void _handleAddPlantSubmit(
      Map<String, dynamic> plantData,
      List<File?> images,
      ) async {
    try {
      // 🔹 Gọi API
      final apiResponse = await API().editCaySam(
        id:widget.plant.caySamId,
        data: plantData,
        files: images,
      );

      if (apiResponse != null && apiResponse.message == "OK") {
        // ✅ Thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🌱 Cây mới đã được thêm vào vị trí ${plantData['gridPosition']}!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
        setState(() {
          // _futureLoSam = API().getLoSamById(selectedZone!.loSamId);
        }); // refresh UI nếu cần
      } else {
        // ❌ Lỗi từ server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể thêm cây sâm.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ❌ Lỗi mạng hoặc exception khác
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}
//
// class PlantDetailScreen1 extends StatelessWidget {
//   final CaySamModel plant;
//   final CaySamNhatKy? diary;
//   final CaySamMoiTruong? environment;
//   final CaySamXacThuc? verification;
//   final VoidCallback onBack;
//
//   PlantDetailScreen({
//     required this.plant,
//     this.diary,
//     this.environment,
//     this.verification,
//     required this.onBack,
//   });
//
//   // Helper function to get current month diary entries
//   List<CaySamNhatKy?> getCurrentMonthDiaryEntries() {
//     final now = DateTime.now();
//     final currentMonth = now.month;
//     final currentYear = now.year;
//
//     final filtered = (plant.caySamNhatKys ?? [])
//         .where((entry) {
//       final entryDate = DateTime.parse(entry!.ngayGhi);
//       return entryDate.month == currentMonth &&
//           entryDate.year == currentYear;
//     })
//         .toList();
//     return filtered;
//   }
//
//   // Helper to get latest diary entry
//   CaySamNhatKy? getLatestDiaryEntry(List<CaySamNhatKy?> entries) {
//     if (entries.isEmpty) return null;
//     entries.sort((a, b) => DateTime.parse(b!.ngayGhi).compareTo(DateTime.parse(a!.ngayGhi)));
//     return entries.first;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentMonthEntries = getCurrentMonthDiaryEntries();
//     final latestEntry = getLatestDiaryEntry(currentMonthEntries);
//
//     // Calculate monthly statistics
//     final totalEntries = currentMonthEntries.length;
//     final avgHealth = currentMonthEntries.isNotEmpty
//         ? (currentMonthEntries.fold<double>(0.0, (sum, entry) => sum + entry!.diemSucKhoe) / currentMonthEntries.length).round() / 10.0
//         : 0.0;
//     final lastUpdate = latestEntry != null
//         ? DateFormat('dd/MM/yyyy').format(DateTime.parse(latestEntry.ngayGhi))
//         : 'Chưa có';
//
//     return Scaffold(
//       body: Column(
//         children: [
//           // Custom Header with back button
//           Container(
//             padding: EdgeInsets.only(
//               top: MediaQuery.of(context).padding.top + 8,
//               left: 16,
//               right: 16,
//               bottom: 8,
//             ),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border(
//                 bottom: BorderSide(color: Colors.grey.shade300, width: 1),
//               ),
//             ),
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: Icon(Icons.arrow_back),
//                   onPressed: onBack,
//                   padding: EdgeInsets.zero,
//                   constraints: BoxConstraints(),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         /*plant.tenCay ??*/ 'Chi tiết cây',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         'ID: ${plant.maCaySam}',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: 8,
//                         height: 8,
//                         decoration: BoxDecoration(
//                           color: _getStatusColor(TrangThaiCay.khoeMauh),
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                       SizedBox(width: 4),
//                       Text(
//                         _getStatusLabel(TrangThaiCay.khoeMauh),
//                         style: TextStyle(fontSize: 12),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Scrollable Content
//           Expanded(
//             child: SingleChildScrollView(
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Plant Image
//                   _buildPlantImage(latestEntry),
//                   SizedBox(height: 16),
//
//                   // Basic Information
//                   _buildBasicInfo(),
//                   SizedBox(height: 16),
//
//                   // Monthly Diary Summary
//                   _buildMonthlyDiarySummary(
//                     currentMonthEntries,
//                     latestEntry,
//                     totalEntries,
//                     avgHealth,
//                     lastUpdate,
//                       plant,
//                       context
//                   ),
//                   SizedBox(height: 16),
//
//                   // Environment Data (if available)
//                   if (environment != null) ...[
//                     _buildEnvironmentSection(),
//                     SizedBox(height: 16),
//                   ],
//
//                   // Verification Info (if available)
//                   if (verification != null) ...[
//                     _buildVerificationSection(),
//                     SizedBox(height: 16),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPlantImage(CaySamNhatKy? latestEntry) {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Container(
//           width: double.infinity,
//           height: 200,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             color: Colors.grey[300],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: Image.network(
//               latestEntry?.hinhAnhTongQuan ??
//                   'https://images.unsplash.com/photo-1589110254547-202e8e05be49?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxnaW5zZW5nJTIwcGxhbnRzJTIwY3VsdGl2YXRpb258ZW58MXx8fHwxNzU3MTMwNTkzfDA&ixlib=rb-4.1.0&q=80&w=800',
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) {
//                 return Container(
//                   color: Colors.grey[300],
//                   child: Icon(
//                     Icons.eco,
//                     color: Colors.grey[600],
//                     size: 64,
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBasicInfo() {
//
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.eco, color: Colors.green[600], size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Thông tin cơ bản',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Loại cây',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       SizedBox(height: 2),
//                       Text(
//                          'Chưa xác định',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Ngày trồng',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       SizedBox(height: 2),
//                       Text(
//                          'Chưa có',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Vị trí',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       SizedBox(height: 2),
//                       Row(
//                         children: [
//                           Icon(Icons.location_on, size: 12),
//                           SizedBox(width: 2),
//                           Text(
//                             plant.viTriTrongLo ?? 'Chưa xác định',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Tuổi cây',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       SizedBox(height: 2),
//                       Text(
//                         plant.tuoiCayId.toString() ?? 'Chưa có',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//
//             if (plant.blockChain != null) ...[
//               SizedBox(height: 16),
//               Container(
//                 padding: EdgeInsets.only(top: 16),
//                 decoration: BoxDecoration(
//                   border: Border(top: BorderSide(color: Colors.grey.shade300)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Blockchain ID',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     SizedBox(height: 2),
//                     Text(
//                       plant.blockChain!,
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontFamily: 'monospace',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMonthlyDiarySummary(
//       List<CaySamNhatKy?> currentMonthEntries,
//       CaySamNhatKy? latestEntry,
//       int totalEntries,
//       double avgHealth,
//       String lastUpdate,
//       CaySamModel plant,
//       BuildContext context
//       ) {
//     final now = DateTime.now();
//
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Nhật ký tháng ${now.month}/${now.year}',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 8),
//
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   '$totalEntries bản ghi trong tháng',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     OutlinedButton(
//                       onPressed: () => _handleDiaryListClick(),
//                       style: OutlinedButton.styleFrom(
//                         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                         minimumSize: Size(0, 0),
//                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.list, size: 12),
//                           SizedBox(width: 4),
//                           Text('List nhật ký', style: TextStyle(fontSize: 12)),
//                         ],
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     ElevatedButton(
//                       onPressed: () => _handleUpdateDiaryClick(plant,context),
//                       style: ElevatedButton.styleFrom(
//                         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                         minimumSize: Size(0, 0),
//                         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.add, size: 12),
//                           SizedBox(width: 4),
//                           Text('Cập nhật', style: TextStyle(fontSize: 12)),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//
//             if (latestEntry != null) ...[
//               // Latest Entry Summary
//               Container(
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         children: [
//                           Text(
//                             'Lần cập nhật cuối',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                           SizedBox(height: 2),
//                           Text(
//                             lastUpdate,
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: Column(
//                         children: [
//                           Text(
//                             'Điểm sức khỏe',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                           SizedBox(height: 2),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Container(
//                                 width: 8,
//                                 height: 8,
//                                 decoration: BoxDecoration(
//                                   color: _getHealthColor(latestEntry.diemSucKhoe),
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                               SizedBox(width: 4),
//                               Text(
//                                 '${latestEntry.diemSucKhoe}/5',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: Column(
//                         children: [
//                           Text(
//                             'Số lá',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                           SizedBox(height: 2),
//                           Text(
//                             '${latestEntry.soLa} lá',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Monthly Average
//               if (totalEntries > 1) ...[
//                 SizedBox(height: 12),
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     'Điểm sức khỏe trung bình tháng: ${avgHealth.toStringAsFixed(1)}/5',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.blue[900],
//                     ),
//                   ),
//                 ),
//               ],
//
//               // Current Status
//               SizedBox(height: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Tình trạng hiện tại:',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Wrap(
//                     spacing: 8,
//                     children: [
//                       if (latestEntry.tinhTrang == "song")
//                         Container(
//                           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.green[100],
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             'Còn sống',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.green[800],
//                             ),
//                           ),
//                         ),
//                       if (latestEntry.tinhTrang == "ngudong")
//                         Container(
//                           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.blue[100],
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             'Ngủ đông',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.blue[800],
//                             ),
//                           ),
//                         ),
//                       if (latestEntry.tinhTrang == "chet")
//                         Container(
//                           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.red[100],
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             'Đã chết',
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: Colors.red[800],
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//
//               // Detail Image
//               if (latestEntry.hinhAnhChiTiet != null) ...[
//                 SizedBox(height: 12),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Ảnh chi tiết gần nhất:',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     Container(
//                       height: 120,
//                       width: 200,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.network(
//                           latestEntry.hinhAnhChiTiet!,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return Container(
//                               color: Colors.grey[300],
//                               child: Icon(Icons.image, size: 32),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ] else ...[
//               // No diary entries this month
//               Container(
//                 padding: EdgeInsets.all(24),
//                 child: Column(
//                   children: [
//                     Icon(
//                       Icons.calendar_today,
//                       size: 48,
//                       color: Colors.grey[400],
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Chưa có nhật ký nào trong tháng này',
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 14,
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: () => _handleUpdateDiaryClick(plant, context),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.add, size: 16),
//                           SizedBox(width: 4),
//                           Text('Thêm nhật ký đầu tiên'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEnvironmentSection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.thermostat, color: Colors.orange[600], size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Môi trường gần nhất',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 4),
//             Text(
//               DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(environment!.ngayDo)),
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//               ),
//             ),
//             SizedBox(height: 16),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildEnvironmentCard(
//                     icon: Icons.thermostat,
//                     label: 'Nhiệt độ',
//                     value: '${environment!.nhietDo.round()}°C',
//                     color: Colors.red,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: _buildEnvironmentCard(
//                     icon: Icons.water_drop,
//                     label: 'Độ ẩm KK',
//                     value: '${environment!.doAmKhongKhi.round()}%',
//                     color: Colors.blue,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildEnvironmentCard(
//                     icon: Icons.grass,
//                     label: 'Độ ẩm đất',
//                     value: '${environment!.doAmDat.round()}%',
//                     color: Colors.brown,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: _buildEnvironmentCard(
//                     icon: Icons.water,
//                     label: 'Lượng mưa',
//                     value: '${environment!.luongMua.toStringAsFixed(1)}mm',
//                     color: Colors.cyan,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildVerificationSection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.verified, color: Colors.purple[600], size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Xác thực chất lượng',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 4),
//             Text(
//               DateFormat('dd/MM/yyyy').format(DateTime.parse(verification!.ngayKiemDinh)),
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//               ),
//             ),
//             SizedBox(height: 16),
//
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Kết quả',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 SizedBox(height: 2),
//                 Text(
//                   verification!.ketQuaKiemDinh,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 if (verification!.ghiChu != null && verification!.ghiChu!.isNotEmpty) ...[
//                   SizedBox(height: 8),
//                   Text(
//                     'Ghi chú',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   SizedBox(height: 2),
//                   Text(
//                     verification!.ghiChu!,
//                     style: TextStyle(fontSize: 12),
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEnvironmentCard({
//     required IconData icon,
//     required String label,
//     required String value,
//     required Color color,
//   }) {
//     return Container(
//       padding: EdgeInsets.all(8),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: color),
//           SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Helper methods
//   Color _getStatusColor(TrangThaiCay? status) {
//     switch (status) {
//       case TrangThaiCay.khoeMauh:
//         return Colors.green;
//       case TrangThaiCay.yeu:
//         return Colors.yellow[700] ?? Colors.yellow;
//       case TrangThaiCay.benh:
//         return Colors.orange;
//       case TrangThaiCay.chet:
//         return Colors.red;
//       default:
//         return Colors.green;
//     }
//   }
//
//   String _getStatusLabel(TrangThaiCay? status) {
//     switch (status) {
//       case TrangThaiCay.khoeMauh:
//         return 'Khỏe mạnh';
//       case TrangThaiCay.yeu:
//         return 'Yếu';
//       case TrangThaiCay.benh:
//         return 'Bệnh';
//       case TrangThaiCay.chet:
//         return 'Chết';
//       default:
//         return 'Khỏe mạnh';
//     }
//   }
//
//   Color _getHealthColor(int health) {
//     switch (health) {
//       case 1:
//         return Colors.red;
//       case 2:
//         return Colors.orange;
//       case 3:
//         return Colors.yellow[700] ?? Colors.yellow;
//       case 4:
//         return Colors.blue;
//       case 5:
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   void _handleDiaryListClick() {
//     // TODO: Navigate to diary list view or open modal
//     print('Show diary list for plant: ${plant.caySamId}');
//   }
//
//   void _handleUpdateDiaryClick(CaySamModel plant, BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => AddPlantScreen(
//           onSubmit: _handleAddPlantSubmit,
//           onCancel: () {
//             Navigator.of(context).pop();
//           },
//           gridPosition: plant.viTriTrongLo,
//           losamId: plant.loSamId ?? 0,
//           areaId: "",
//           caysam: plant,
//         ),
//       ),
//     );
//   }
//   void _handleAddPlantSubmit(
//       Map<String, dynamic> plantData,
//       List<File?> images,
//       ) async {
//     try {
//       // 🔹 Gọi API
//       final apiResponse = await API().editCaySam(
//         id:plant.caySamId,
//         data: plantData,
//         files: images,
//       );
//
//       if (apiResponse != null && apiResponse.message == "OK") {
//         // ✅ Thành công
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               '🌱 Cây mới đã được thêm vào vị trí ${plantData['gridPosition']}!',
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//
//         Navigator.of(context).pop();
//         setState(() {
//           _futureLoSam = API().getLoSamById(selectedZone!.loSamId);
//         }); // refresh UI nếu cần
//       } else {
//         // ❌ Lỗi từ server
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Không thể thêm cây sâm.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       // ❌ Lỗi mạng hoặc exception khác
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Lỗi kết nối: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }