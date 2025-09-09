import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cay_sam.dart';
import '../models/nhat_ky.dart';
import '../models/moi_truong.dart';
import '../models/xac_thuc.dart';

class PlantDetailScreen extends StatelessWidget {
  final CaySam plant;
  final CaySamNhatKy? diary;
  final CaySamMoiTruong? environment;
  final CaySamXacThuc? verification;
  final VoidCallback onBack;

  PlantDetailScreen({
    required this.plant,
    this.diary,
    this.environment,
    this.verification,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plant.tenCay ?? 'Chi tiết cây'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Edit plant info
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Image and Basic Info
            _buildPlantHeader(),
            SizedBox(height: 24),

            // Plant Details
            _buildPlantDetails(),
            SizedBox(height: 24),

            // Diary Information
            if (diary != null) ...[
              _buildDiarySection(),
              SizedBox(height: 24),
            ],

            // Environment Data
            if (environment != null) ...[
              _buildEnvironmentSection(),
              SizedBox(height: 24),
            ],

            // Verification Status
            if (verification != null) ...[
              _buildVerificationSection(),
              SizedBox(height: 24),
            ],

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantHeader() {
    final status = plant.trangThai ?? TrangThaiCay.khoeMauh;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Plant Image
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://images.unsplash.com/photo-1589110254547-202e8e05be49?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxnaW5zZW5nJTIwcGxhbnRzJTIwY3VsdGl2YXRpb258ZW58MXx8fHwxNzU3MTMwNTkzfDA&ixlib=rb-4.1.0&q=80&w=400',
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
            SizedBox(height: 16),

            // Plant Name and Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.tenCay ?? 'Không có tên',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ID: ${plant.id}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status.icon,
                        size: 16,
                        color: status.color,
                      ),
                      SizedBox(width: 4),
                      Text(
                        status.displayName,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantDetails() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin cây',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),

            _buildDetailRow(
              icon: Icons.eco,
              label: 'Loại cây',
              value: plant.loaiCay ?? 'Không xác định',
            ),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Ngày trồng',
              value: plant.ngayTrong != null
                  ? DateFormat('dd/MM/yyyy').format(plant.ngayTrong!) // ✅ Fixed: plant.ngayTrong is already DateTime
                  : 'Chưa xác định',
            ),
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'Vị trí',
              value: plant.viTri ?? 'Chưa xác định',
            ),
            if (plant.blockChain != null)
              _buildDetailRow(
                icon: Icons.link,
                label: 'Blockchain ID',
                value: plant.blockChain!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiarySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.book, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Nhật ký gần nhất',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Ngày ghi',
              value: DateFormat('dd/MM/yyyy').format(DateTime.parse(diary!.ngayGhi)), // ✅ This is correct - ngayGhi is String in model
            ),
            _buildDetailRow(
              icon: Icons.eco,
              label: 'Số lá',
              value: '${diary!.soLa} lá',
            ),
            _buildDetailRow(
              icon: Icons.favorite,
              label: 'Điểm sức khỏe',
              value: '${diary!.diemSucKhoe}/5',
            ),

            // Health indicators
            SizedBox(height: 12),
            Text(
              'Tình trạng:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (diary!.tinhTrang.song)
                  Chip(
                    label: Text('Sống'),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    labelStyle: TextStyle(color: Colors.green),
                  ),
                if (diary!.tinhTrang.nguDong)
                  Chip(
                    label: Text('Ngủ đông'),
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    labelStyle: TextStyle(color: Colors.orange),
                  ),
                if (diary!.tinhTrang.chet)
                  Chip(
                    label: Text('Chết'),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    labelStyle: TextStyle(color: Colors.red),
                  ),
              ],
            ),

            // Images if available
            if (diary!.anhTongQuan != null) ...[
              SizedBox(height: 16),
              Text(
                'Hình ảnh:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    diary!.anhTongQuan!,
                    fit: BoxFit.cover,
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
                Icon(Icons.thermostat, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Dữ liệu môi trường',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildEnvironmentCard(
                    icon: Icons.thermostat,
                    label: 'Nhiệt độ',
                    value: '${environment!.nhietDo.round()}°C',
                    color: Colors.red,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildEnvironmentCard(
                    icon: Icons.water_drop,
                    label: 'Độ ẩm KK',
                    value: '${environment!.doAmKhongKhi.round()}%',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEnvironmentCard(
                    icon: Icons.grass,
                    label: 'Độ ẩm đất',
                    value: '${environment!.doAmDat.round()}%',
                    color: Colors.brown,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildEnvironmentCard(
                    icon: Icons.water,
                    label: 'Lượng mưa',
                    value: '${environment!.luongMua.toStringAsFixed(1)}mm',
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),

            if (environment!.ghiChu != null && environment!.ghiChu!.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
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
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      environment!.ghiChu!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
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

  Widget _buildVerificationSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Xác thực chất lượng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Đã xác thực',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Text(
                        DateFormat('dd/MM/yyyy').format(
                            DateTime.parse(verification!.ngayKiemDinh)), // ✅ This is correct - ngayKiemDinh is String in model
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    verification!.ketQuaKiemDinh,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (verification!.ghiChu != null && verification!.ghiChu!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      verification!.ghiChu!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Update diary
                },
                icon: Icon(Icons.edit),
                label: Text('Cập nhật nhật ký'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // View history
                },
                icon: Icon(Icons.history),
                label: Text('Lịch sử'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Take photo
                },
                icon: Icon(Icons.camera_alt),
                label: Text('Chụp ảnh'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
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

  Widget _buildEnvironmentCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}