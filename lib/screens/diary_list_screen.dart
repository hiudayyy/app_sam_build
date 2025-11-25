import 'package:nftsam/api/api_caysam.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api.dart';
import '../models/cay_sam.dart';
import '../models/nhat_ky.dart';
import '../data/mock_data.dart';
import '../models/vuontrong/caysam_model.dart';
import '../utils/app_dimensions.dart';
import '../widgets/fullscreenimageviewer.dart';

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
  bool sortNewest = true;
  bool showImages = true;

  // Health point colors - đồng bộ với React
  static const Map<int, Map<String, dynamic>> healthColors = {
    1: {'color': Colors.red, 'label': 'Rất yếu', 'bgColor': Color(0xFFFFEBEE)},
    2: {'color': Colors.orange, 'label': 'Yếu', 'bgColor': Color(0xFFFFF3E0)},
    3: {'color': Colors.amber, 'label': 'Trung bình', 'bgColor': Color(0xFFFFFDE7)},
    4: {'color': Colors.blue, 'label': 'Tốt', 'bgColor': Color(0xFFE3F2FD)},
    5: {'color': Colors.green, 'label': 'Rất tốt', 'bgColor': Color(0xFFE8F5E8)},
  };

  // Get diary entries for plant
  Future<List<CaySamNhatKy>> getPlantDiaryEntries() async {
    final entries = await API().getNhatKysbyid(widget.plant.caySamId);
    return entries;
  }

  // Get health trend between two entries
  String? getHealthTrend(int currentHealth, int? previousHealth) {
    if (previousHealth == null) return null;
    if (currentHealth > previousHealth) return 'up';
    if (currentHealth < previousHealth) return 'down';
    return 'stable';
  }

  // Format relative date
  String formatRelativeDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "";

    DateTime? date;
    try {
      date = DateTime.parse(dateString);
    } catch (_) {
      return ""; // nếu parse lỗi thì trả về rỗng
    }

    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Hôm nay';
    if (difference == 1) return 'Hôm qua';
    if (difference < 7) return '$difference ngày trước';
    if (difference < 30) return '${(difference / 7).floor()} tuần trước';
    if (difference < 365) return '${(difference / 30).floor()} tháng trước';
    return '${(difference / 365).floor()} năm trước';
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CaySamNhatKy>>(
      future: getPlantDiaryEntries(), // truyền id cây
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }

        final diaryEntries = snapshot.data ?? [];

        final totalEntries = diaryEntries.length;
        final avgHealth = diaryEntries.isNotEmpty
            ? (diaryEntries.fold<double>(
            0.0, (sum, entry) => sum + entry.diemSucKhoe) /
            diaryEntries.length)
            : 0.0;
        final healthTrend = diaryEntries.length >= 2
            ? getHealthTrend(
            diaryEntries[0].diemSucKhoe, diaryEntries[1].diemSucKhoe)
            : null;
        final dateRange = diaryEntries.isNotEmpty
            ? {
          'from': diaryEntries.last.ngayGhi != null
              ? DateFormat('dd/MM/yyyy')
              .format(DateTime.parse(diaryEntries.last.ngayGhi!))
              : '',
          'to': diaryEntries.first.ngayGhi != null
              ? DateFormat('dd/MM/yyyy')
              .format(DateTime.parse(diaryEntries.first.ngayGhi!))
              : '',
        }
            : {};
        return Scaffold(
          body: Column(
            children: [
              // Custom Header - đồng bộ với React
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
                            'Lịch sử nhật ký',
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
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => showImages = !showImages),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200), // mượt khi đổi màu
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: showImages ? Colors.blue : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300), // tuỳ chọn: viền nhẹ
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    size: 12,
                                    color: showImages ? Colors.white : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ảnh',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: showImages ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
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
                      // Statistics Summary Card
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '$totalEntries',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Tổng bản ghi',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              avgHealth.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (healthTrend != null) ...[
                                              SizedBox(width: 4),
                                              Icon(
                                                healthTrend == 'up'
                                                    ? Icons.trending_up
                                                    : healthTrend == 'down'
                                                    ? Icons.trending_down
                                                    : Icons.trending_flat,
                                                size: 16,
                                                color: healthTrend == 'up'
                                                    ? Colors.green
                                                    : healthTrend == 'down'
                                                    ? Colors.red
                                                    : Colors.grey,
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Điểm TB / 5',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              if (dateRange != null) ...[
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.only(top: 12),
                                  decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                                  ),
                                  child: Text(
                                    'Từ ${dateRange['from']} đến ${dateRange['to']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Sort Controls
                      Row(
                        children: [
                          Text(
                            'Quá trình phát triển',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Spacer(),
                          /*Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => setState(() => sortNewest = true),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: sortNewest ? Colors.blue : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Mới nhất',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: sortNewest ? Colors.white : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setState(() => sortNewest = false),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: !sortNewest ? Colors.blue : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Cũ nhất',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: !sortNewest ? Colors.white : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),*/
                        ],
                      ),
                      SizedBox(height: 16),

                      // Timeline Entries
                      if (diaryEntries.isNotEmpty) ...[
                        ...diaryEntries.asMap().entries.map((entryWithIndex) {
                          final index = entryWithIndex.key;
                          final entry = entryWithIndex.value;
                          final healthInfo = healthColors[entry.diemSucKhoe] ?? healthColors[5]!;
                          final previousEntry = index < diaryEntries.length - 1 ? diaryEntries[index + 1] : null;
                          final trend = getHealthTrend(entry.diemSucKhoe, previousEntry?.diemSucKhoe);

                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timeline dot và connector
                                Column(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: healthInfo['color'],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Container(
                                        margin: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.eco,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    if (trend != null) ...[
                                      SizedBox(height: 4),
                                      Icon(
                                        trend == 'up'
                                            ? Icons.trending_up
                                            : trend == 'down'
                                            ? Icons.trending_down
                                            : Icons.trending_flat,
                                        size: 12,
                                        color: trend == 'up'
                                            ? Colors.green
                                            : trend == 'down'
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ],
                                    // Timeline connector
                                    if (index < diaryEntries.length - 1) ...[
                                      SizedBox(height: 8),
                                      Container(
                                        width: 2,
                                        height: 40,
                                        color: Colors.grey.shade300,
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(width: 4),

                                // Entry content
                                Expanded(
                                  child: Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(AppDimensions.fontSizeExtraSmall),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header with date and health badge
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today, size: 12),
                                              SizedBox(width: 4),
                                              Text(
                                                entry.ngayGhi != null
                                                    ? DateFormat('dd/MM/yyyy').format(DateTime.parse(entry.ngayGhi!))
                                                    : '',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),

                                              SizedBox(width: 8),
                                              Text(
                                                '(${formatRelativeDate(entry.ngayGhi)})',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Spacer(),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: healthInfo['color'],
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${entry.diemSucKhoe}/5 - ${healthInfo['label']}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),

                                          // Measurements grid
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Số lá',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      '${entry.soLa} lá',
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
                                                      'Sức khỏe',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration: BoxDecoration(
                                                            color: healthInfo['color'],
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          '${entry.diemSucKhoe}/5',
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
                                            ],
                                          ),
                                          SizedBox(height: 12),

                                          // Status badges
                                          // Wrap(
                                          //   spacing: 8,
                                          //   children: [
                                          //     if (entry.tinhTrang.song)
                                          //       Container(
                                          //         padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          //         decoration: BoxDecoration(
                                          //           color: Colors.green[100],
                                          //           borderRadius: BorderRadius.circular(12),
                                          //         ),
                                          //         child: Text(
                                          //           'Còn sống',
                                          //           style: TextStyle(
                                          //             fontSize: 10,
                                          //             color: Colors.green[800],
                                          //           ),
                                          //         ),
                                          //       ),
                                          //     if (entry.tinhTrang.nguDong)
                                          //       Container(
                                          //         padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          //         decoration: BoxDecoration(
                                          //           color: Colors.blue[100],
                                          //           borderRadius: BorderRadius.circular(12),
                                          //         ),
                                          //         child: Text(
                                          //           'Ngủ đông',
                                          //           style: TextStyle(
                                          //             fontSize: 10,
                                          //             color: Colors.blue[800],
                                          //           ),
                                          //         ),
                                          //       ),
                                          //     if (entry.tinhTrang.chet)
                                          //       Container(
                                          //         padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          //         decoration: BoxDecoration(
                                          //           color: Colors.red[100],
                                          //           borderRadius: BorderRadius.circular(12),
                                          //         ),
                                          //         child: Text(
                                          //           'Đã chết',
                                          //           style: TextStyle(
                                          //             fontSize: 10,
                                          //             color: Colors.red[800],
                                          //           ),
                                          //         ),
                                          //       ),
                                          //   ],
                                          // ),

                                          // Images
                                          if (showImages && (entry.hinhAnhTongQuan != null || entry.hinhAnhChiTiet != null)) ...[
                                            SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Icon(Icons.camera_alt, size: 12, color: Colors.grey[600]),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Hình ảnh ghi nhận',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                if (entry.hinhAnhTongQuan != null) ...[
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Tổng quan',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                        SizedBox(height: 4),
                                                        GestureDetector(
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => FullScreenImageViewer(
                                                                  imageUrl: entry.hinhAnhTongQuan!,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: Container(
                                                            height: 80,
                                                            width: double.infinity,
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey[300],
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(8),
                                                              child: Image.network(
                                                                entry.hinhAnhTongQuan!,
                                                                fit: BoxFit.cover,
                                                                errorBuilder: (context, error, stackTrace) {
                                                                  return Container(
                                                                    color: Colors.grey[300],
                                                                    child: const Icon(Icons.image, size: 24),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                if (entry.hinhAnhTongQuan != null && entry.hinhAnhChiTiet != null)
                                                  SizedBox(width: 8),
                                                if (entry.hinhAnhChiTiet != null) ...[
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Chi tiết',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                        SizedBox(height: 4),
                                                        GestureDetector(
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => FullScreenImageViewer(imageUrl: entry.hinhAnhChiTiet!),
                                                              ),
                                                            );
                                                          },
                                                          child: Hero(
                                                            tag: entry.hinhAnhChiTiet!,
                                                            child: Container(
                                                              height: 80,
                                                              width: double.infinity,
                                                              decoration: BoxDecoration(
                                                                color: Colors.grey[300],
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: ClipRRect(
                                                                borderRadius: BorderRadius.circular(8),
                                                                child: Image.network(
                                                                  entry.hinhAnhChiTiet!,
                                                                  fit: BoxFit.cover,
                                                                  errorBuilder: (context, error, stackTrace) {
                                                                    return Container(
                                                                      color: Colors.grey[300],
                                                                      alignment: Alignment.center,
                                                                      child: const Icon(Icons.image, size: 24),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],

                                          // Notes
                                          if (entry.ghiChu != null && entry.ghiChu!.isNotEmpty) ...[
                                            SizedBox(height: 12),
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Ghi chú:',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    entry.ghiChu!,
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        // Summary footer for long lists
                        if (diaryEntries.length > 5) ...[
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    'Đã hiển thị ${diaryEntries.length} bản ghi nhật ký',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (dateRange != null) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      'Quá trình phát triển từ ${dateRange['from']} đến ${dateRange['to']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        // Empty state
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Chưa có nhật ký nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Bắt đầu ghi lại quá trình phát triển của cây ${widget.plant.maCaySam}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: widget.onBack,
                                  child: Text('Quay lại chi tiết cây'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}