import 'package:csam_mobile/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) return SizedBox.shrink();

        return PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'profile':
                _showProfileDialog(context, user);
                break;
              case 'settings':
              // Navigate to settings
                break;
              case 'logout':
                _showLogoutDialog(context, authProvider);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 18),
                  SizedBox(width: 12),
                  Text('Xem hồ sơ'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 18),
                  SizedBox(width: 12),
                  Text('Cài đặt'),
                ],
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    (user.tenTaiKhoan ?? '')
                        .trim()
                        .isNotEmpty
                        ? user.tenTaiKhoan[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileDialog(BuildContext context, UserModel user) {
    String ngayKhoiTaoFormatted = 'Không rõ ngày';

    // ➡️ XỬ LÝ CHUỖI: Thử chuyển đổi String sang DateTime
    if (user.ngayKhoiTao != null && user.ngayKhoiTao!.isNotEmpty) {
      try {
        // Giả sử chuỗi có định dạng ISO 8601 (ví dụ: "2025-11-12T15:54:57")
        final DateTime dateTime = DateTime.parse(user.ngayKhoiTao);
        ngayKhoiTaoFormatted = DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal()); // Định dạng lại
      } catch (e) {
        // Nếu không parse được, hiển thị chuỗi gốc hoặc thông báo lỗi
        ngayKhoiTaoFormatted = user.ngayKhoiTao;
        // Hoặc nếu bạn muốn hiển thị một chuỗi thân thiện khi parse lỗi:
        // ngayKhoiTaoFormatted = 'Ngày không hợp lệ';

        // print('Lỗi parse ngày: $e'); // In ra console để debug
      }
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),

        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar (Giữ nguyên)
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                (user.tenTaiKhoan ?? '?').trim().isNotEmpty
                    ? user.tenTaiKhoan![0].toUpperCase() // Dùng ! vì đã kiểm tra isNotEmpty
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Tên tài khoản và Vai trò
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.tenTaiKhoan ?? "Tài khoản ẩn danh",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // const SizedBox(height: 4),
                  // Text(
                  //   user.htPhanQuyenTaiKhoans.first.maVaiTro ?? "Chưa có vai trò",
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     color: Colors.indigo.shade600, // Nhấn mạnh Vai trò
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),

        // BODY (Nội dung chi tiết)
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),

            // 1. Số điện thoại (SDT)
            _buildInfoRow(
              'SĐT',
              user.sdt,
              icon: Icons.phone_android_outlined,
            ),
            const SizedBox(height: 12),

            // 2. Email
            _buildInfoRow(
              'Email',
              user.email,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 12),

            // 3. Ngày khởi tạo (Thay thế Container thông báo cũ)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tham gia từ: $ngayKhoiTaoFormatted',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ACTIONS
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận đăng xuất'),
        content: Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon ?? Icons.label_outline, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value ?? 'Chưa xác định',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontStyle: value == null ? FontStyle.italic : null,
            ),
          ),
        ),
      ],
    );
  }
}