import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import '../models/xac_thuc.dart';

class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String _searchQuery = '';
  TrangThaiKiemDinh? _selectedStatus;
  LoaiKiemDinh? _selectedType;

  List<CaySamXacThuc> get _filteredVerifications {
    return MockData.mockVerification.where((verification) {
      final matchesSearch = verification.ketQuaKiemDinh
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()) ||
          verification.caySamId
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatus == null ||
          verification.trangThaiKiemDinh == _selectedStatus;

      final matchesType = _selectedType == null ||
          verification.loaiKiemDinh == _selectedType;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Section with Action Button
          Card(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 24,
                                  color: Color(0xFF16A34A),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Xác thực chất lượng',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.045,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Quản lý kiểm định và xác thực chất lượng sâm',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: MediaQuery.of(context).size.width * 0.03,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FloatingActionButton.small(
                        onPressed: () => _showCreateVerificationDialog(),
                        backgroundColor: Color(0xFF16A34A),
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.016),

          // Search and Filters
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo mã cây, kết quả...',
                      hintStyle: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.03,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.01,
                        horizontal: MediaQuery.of(context).size.width * 0.03,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.012),

                  // Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<TrangThaiKiemDinh>(
                          decoration: InputDecoration(
                            labelText: 'Trạng thái',
                            labelStyle: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.03,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              vertical: MediaQuery.of(context).size.height * 0.01,
                              horizontal: MediaQuery.of(context).size.width * 0.03,
                            ),
                          ),
                          value: _selectedStatus,
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Tất cả',style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.03,
                              ),),
                            ),
                            ...TrangThaiKiemDinh.values.map((status) =>
                                DropdownMenuItem(
                                  value: status,
                                  child: Text(status.displayName,style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.03,
                                  ),), // ✅ Fixed: .label -> .displayName
                                ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<LoaiKiemDinh>(
                          decoration: InputDecoration(
                            labelText: 'Loại kiểm định',
                            labelStyle: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.03,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              vertical: MediaQuery.of(context).size.height * 0.01,
                              horizontal: MediaQuery.of(context).size.width * 0.03,
                            ),
                          ),
                          value: _selectedType,
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Tất cả',style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.03,
                              ),),
                            ),
                            ...LoaiKiemDinh.values.map((type) =>
                                DropdownMenuItem(
                                  value: type,
                                  child: Text(type.displayName,style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.03,
                                  ),), // ✅ Fixed: .label -> .displayName
                                ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Results Count
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tìm thấy ${_filteredVerifications.length} kết quả',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: MediaQuery.of(context).size.width * 0.03,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.008),

          // Verification List
          Expanded(
            child: _filteredVerifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              itemCount: _filteredVerifications.length,
              itemBuilder: (context, index) {
                final verification = _filteredVerifications[index];
                return _buildVerificationCard(verification);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Thử điều chỉnh bộ lọc hoặc từ khóa tìm kiếm',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(CaySamXacThuc verification) {
    return Card(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.016),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.016),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với status và type
            Row(
              children: [
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: verification.getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        verification.getStatusIcon(),
                        size: 16,
                        color: verification.getStatusColor(),
                      ),
                      SizedBox(width: 4),
                      Text(
                        verification.trangThaiKiemDinh.displayName, // ✅ Fixed: .label -> .displayName
                        style: TextStyle(
                          color: verification.getStatusColor(),
                          fontSize: MediaQuery.of(context).size.width * 0.025,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.025),
                // Type Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        verification.getTypeIcon(),
                        size: MediaQuery.of(context).size.width * 0.03,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 4),
                      Text(
                        verification.loaiKiemDinh.displayName, // ✅ Fixed: .label -> .displayName
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: MediaQuery.of(context).size.width * 0.025,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy').format(
                      DateTime.parse(verification.ngayKiemDinh)),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: MediaQuery.of(context).size.width * 0.025,
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.012),

            // Verification và Plant ID
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.tag,
                        size: MediaQuery.of(context).size.width * 0.03,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ID: ${verification.xacThucId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: MediaQuery.of(context).size.width * 0.025,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.eco,
                        size: MediaQuery.of(context).size.width * 0.03,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      Text(
                        'Cây: ${verification.caySamId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize:MediaQuery.of(context).size.width * 0.025
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.008),

            // Người kiểm định và điểm
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: MediaQuery.of(context).size.width * 0.03,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          verification.nguoiKiemDinh,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: MediaQuery.of(context).size.width * 0.025,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (verification.diemChatLuong != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: MediaQuery.of(context).size.width * 0.03,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${verification.diemChatLuong!.toStringAsFixed(1)}/10',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: MediaQuery.of(context).size.width * 0.025,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.012),

            // Kết quả
            Text(
              verification.ketQuaKiemDinh,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.03,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Ghi chú nếu có
            if (verification.ghiChu != null && verification.ghiChu!.isNotEmpty) ...[
              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.012),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note,
                          size: MediaQuery.of(context).size.width * 0.03,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Text(
                          'Ghi chú:',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.025,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.004),
                    Text(
                      verification.ghiChu!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: MediaQuery.of(context).size.width * 0.025,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Tài liệu đính kèm
            if (verification.taiLieuDinhKem != null && verification.taiLieuDinhKem!.isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: MediaQuery.of(context).size.width * 0.03,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Text(
                    '${verification.taiLieuDinhKem!.length} tài liệu đính kèm',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: MediaQuery.of(context).size.width * 0.025,
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: MediaQuery.of(context).size.height * 0.012),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showVerificationDetail(verification),
                    icon: Icon(Icons.visibility, size: MediaQuery.of(context).size.width * 0.03),
                    label: Text('Chi tiết',style: TextStyle(fontSize:MediaQuery.of(context).size.width * 0.03 ),),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF16A34A),
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.006,
                        horizontal: MediaQuery.of(context).size.width * 0.01,
                      ),
                    ),

                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                if (verification.trangThaiKiemDinh != TrangThaiKiemDinh.hoanThanh) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showUpdateStatusDialog(verification),
                      icon: Icon(Icons.edit, size: MediaQuery.of(context).size.width * 0.03),
                      label: Text('Cập nhật',style: TextStyle(fontSize:MediaQuery.of(context).size.width * 0.03 ),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.006,
                          horizontal: MediaQuery.of(context).size.width * 0.01,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadCertificate(verification),
                      icon: Icon(Icons.download, size: MediaQuery.of(context).size.width * 0.03),
                      label: Text('Tải chứng chỉ',style: TextStyle(fontSize:MediaQuery.of(context).size.width * 0.03 ),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.006,
                          horizontal: MediaQuery.of(context).size.width * 0.01,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tạo yêu cầu kiểm định'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chức năng tạo yêu cầu kiểm định mới sẽ được triển khai.'),
            SizedBox(height: 16),
            Text(
              'Các bước sẽ bao gồm:\n• Chọn cây cần kiểm định\n• Chọn loại kiểm định\n• Phân công người kiểm định\n• Thiết lập lịch kiểm định',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDetail(CaySamXacThuc verification) {
    final size = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: size.height * 0.8, // 👈 Giới hạn tối đa 80% chiều cao màn hình
            maxWidth: size.width * 0.9,   // dialog chiếm 90% chiều rộng
          ),
          child: Container(
            padding: EdgeInsets.all(size.width * 0.04),
            child: SingleChildScrollView(   // 👈 Thêm cuộn để tránh overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        verification.getTypeIcon(),
                        size: size.width * 0.06,
                      ),
                      SizedBox(width: size.width * 0.02),
                      Expanded(
                        child: Text(
                          'Chi tiết kiểm định',
                          style: TextStyle(
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, size: size.width * 0.05),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.02),

                  // Thông tin cơ bản
                  _buildDetailRow('Mã kiểm định:', verification.xacThucId, size),
                  _buildDetailRow('Mã cây:', verification.caySamId, size),
                  _buildDetailRow('Loại kiểm định:', verification.loaiKiemDinh.displayName, size),
                  _buildDetailRow('Trạng thái:', verification.trangThaiKiemDinh.displayName, size),
                  _buildDetailRow('Người kiểm định:', verification.nguoiKiemDinh, size),
                  _buildDetailRow(
                    'Ngày kiểm định:',
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(verification.ngayKiemDinh)),
                    size,
                  ),

                  if (verification.diemChatLuong != null)
                    _buildDetailRow('Điểm chất lượng:', '${verification.diemChatLuong}/10', size),

                  SizedBox(height: size.height * 0.02),

                  // Kết quả
                  Text(
                    'Kết quả:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: size.width * 0.038,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Text(
                    verification.ketQuaKiemDinh,
                    style: TextStyle(fontSize: size.width * 0.036),
                  ),

                  if (verification.ghiChu != null && verification.ghiChu!.isNotEmpty) ...[
                    SizedBox(height: size.height * 0.02),
                    Text(
                      'Ghi chú:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: size.width * 0.038,
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    Text(
                      verification.ghiChu!,
                      style: TextStyle(fontSize: size.width * 0.036),
                    ),
                  ],

                  // Lịch sử
                  if (verification.lichSuKiemDinh.isNotEmpty) ...[
                    SizedBox(height: size.height * 0.02),
                    Text(
                      'Lịch sử kiểm định:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: size.width * 0.038,
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    ListView.builder(
                      shrinkWrap: true,       // 👈 Cho phép nằm trong SingleChildScrollView
                      physics: NeverScrollableScrollPhysics(), // 👈 Tắt cuộn riêng, cuộn theo cha
                      itemCount: verification.lichSuKiemDinh.length,
                      itemBuilder: (context, index) {
                        final history = verification.lichSuKiemDinh[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: size.height * 0.01),
                          child: Padding(
                            padding: EdgeInsets.all(size.width * 0.03),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm')
                                          .format(DateTime.parse(history.ngayThayDoi)),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: size.width * 0.032,
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      history.nguoiThayDoi,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: size.width * 0.032,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: size.height * 0.005),
                                Text(
                                  history.hanhDong,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: size.width * 0.034,
                                  ),
                                ),
                                if (history.ghiChu != null) ...[
                                  SizedBox(height: size.height * 0.005),
                                  Text(
                                    history.ghiChu!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: size.width * 0.032,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Responsive _buildDetailRow
  Widget _buildDetailRow(String label, String value, Size size) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.01),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: size.width * 0.036,
            ),
          ),
          SizedBox(width: size.width * 0.02),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: size.width * 0.036,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showUpdateStatusDialog(CaySamXacThuc verification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cập nhật trạng thái kiểm định cho: ${verification.caySamId}'),
            SizedBox(height: 16),
            Text(
              'Chức năng cập nhật trạng thái sẽ được triển khai với:\n• Thay đổi trạng thái\n• Cập nhật kết quả\n• Chấm điểm chất lượng\n• Ghi lại lịch sử',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sẽ cập nhật trạng thái kiểm định')),
              );
            },
            child: Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _downloadCertificate(CaySamXacThuc verification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tải chứng chỉ cho ${verification.caySamId}'),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () {
            // TODO: Open certificate view
          },
        ),
      ),
    );
  }
}