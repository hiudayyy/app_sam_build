import 'dart:convert';

import 'package:nftsam/api/api_taikhoan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../models/kttoken.dart';
import '../models/message_enum.dart';
import '../models/user_model.dart'; // Đảm bảo import đúng model của bạn
import '../providers/auth_provider.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) return const SizedBox.shrink();

        return PopupMenuButton<String>(
          offset: const Offset(0, 45), // Đẩy menu xuống một chút cho đẹp
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                showDialog(
                  context: context,
                  barrierDismissible: false, // Bắt buộc bấm đóng hoặc lưu
                  builder: (context) => UserProfileDialog(user: user),
                );
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
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Hồ sơ cá nhân'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Cài đặt'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey.shade100, // Thêm nền nhẹ cho nút
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    (user.tenTaiKhoan ?? '').trim().isNotEmpty
                        ? user.tenTaiKhoan![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Hiển thị tên ngắn gọn nếu cần
                // Text(user.tenTaiKhoan ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                // SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET DIALOG CHỈNH SỬA HỒ SƠ
// ==========================================
class UserProfileDialog extends StatefulWidget {
  final UserModel user; // Thay UserModel bằng class model thực tế của bạn nếu khác

  const UserProfileDialog({Key? key, required this.user}) : super(key: key);

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _sdtController;
  late TextEditingController _emailController;
  bool _isEditing = false; // Trạng thái có đang chỉnh sửa hay không

  @override
  void initState() {
    super.initState();
    _sdtController = TextEditingController(text: widget.user.sdt ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _sdtController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Hàm xử lý lưu thông tin (Gọi API cập nhật tại đây)
  Future<void> _handleSaveProfile() async {
    if (_formKey.currentState!.validate()) {
      final edittk = {
        "sdt": "${_sdtController.text}",
        "email": "${_emailController.text}",
      };
      final repose = await API().editmytaikhoan(data:edittk);
      if (repose?.messCode == MessCode.IsOK) {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString("ginseng_user");
        Kttoken? user;
        if (userJson != null) {
          user = Kttoken.fromJson(jsonDecode(userJson));
          Provider.of<AuthProvider>(context, listen: false).updateUserAfterEdit(user);
        }
      }
      if (repose != null && repose.message == "OK") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công! (Demo)')),
        );
      }
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format ngày tham gia
    String ngayKhoiTaoFormatted = 'Không rõ ngày';
    if (widget.user.ngayKhoiTao != null && widget.user.ngayKhoiTao!.isNotEmpty) {
      try {
        final DateTime dateTime = DateTime.parse(widget.user.ngayKhoiTao);
        ngayKhoiTaoFormatted = DateFormat('dd/MM/yyyy').format(dateTime.toLocal());
      } catch (_) {
        ngayKhoiTaoFormatted = widget.user.ngayKhoiTao;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16), // Cách lề màn hình
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500), // Giới hạn chiều rộng trên iPad/Web
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- HEADER ---
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Chỉnh sửa hồ sơ' : 'Hồ sơ cá nhân',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
                const Divider(height: 30, thickness: 1),

                // --- AVATAR LỚN ---
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        (widget.user.tenTaiKhoan ?? '?').trim().isNotEmpty
                            ? widget.user.tenTaiKhoan![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                        ),
                      ),
                    ),
                    // Nút camera để đổi avatar (Demo UI)
                    if (_isEditing)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black26)],
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.grey),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.user.tenTaiKhoan ?? "Tài khoản",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Thành viên từ: $ngayKhoiTaoFormatted",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 30),

                // --- FORM ĐIỀN THÔNG TIN ---
                _buildTextField(
                  label: 'Số điện thoại',
                  controller: _sdtController,
                  icon: Icons.phone_iphone,
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập SĐT';
                    if (value.length < 9) return 'SĐT không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  enabled: _isEditing,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      // Regex check email đơn giản
                      final bool emailValid = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
                      if (!emailValid) return 'Email không đúng định dạng';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // --- NÚT ĐỔI MẬT KHẨU ---
                if (!_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ChangePasswordDialog(),
                        );
                      },
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Đổi mật khẩu'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // --- BUTTONS ACTIONS ---
                Row(
                  children: [
                    if (_isEditing)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Reset lại dữ liệu cũ
                            _sdtController.text = widget.user.sdt ?? '';
                            _emailController.text = widget.user.email ?? '';
                            setState(() => _isEditing = false);
                          },
                          // --- SỬA STYLE NÚT HỦY Ở ĐÂY ---
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.grey.shade200, // Nền xám nhạt rõ ràng
                            foregroundColor: Colors.black87,      // Chữ đen đậm
                            elevation: 0,                         // Bỏ bóng để nó chìm hơn nút Lưu
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)
                            ),
                          ),
                          child: const Text('Hủy bỏ'),
                        ),
                      ),

                    if (_isEditing) const SizedBox(width: 16),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isEditing
                            ? _handleSaveProfile
                            : () => setState(() => _isEditing = true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          // Nút chính (Lưu/Sửa) giữ nguyên màu nổi bật
                          backgroundColor: _isEditing ? Theme.of(context).primaryColor : Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          elevation: 2, // Có bóng nhẹ để nổi bật hơn
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Lưu thay đổi' : 'Chỉnh sửa',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: Colors.black87, // Màu chữ luôn đậm
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        // Khi đang sửa thì icon màu xanh (hoặc màu chính), khi xem thì màu xám
        prefixIcon: Icon(
          icon,
          color: enabled ? Theme.of(context).primaryColor : Colors.grey.shade600,
        ),

        // --- SỬA LẠI PHẦN NÀY ---
        filled: true, // Luôn luôn có màu nền
        // Nếu đang sửa: Nền trắng. Nếu xem: Nền xám
        fillColor: enabled ? Colors.white : Colors.grey.shade100,

        // 1. Viền khi ĐANG SỬA (nhưng chưa bấm vào)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          // Tăng độ đậm của viền lên shade400 để nhìn rõ hơn
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
        ),

        // 2. Viền khi ĐANG XEM (không cho sửa)
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          // Khi xem thì viền nhạt hơn hoặc trùng màu nền
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),

        // 3. Viền khi ĐANG BẤM VÀO ĐỂ GÕ (Focus)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),

        // 4. Viền khi CÓ LỖI (Validate)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),

        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ==========================================
// WIDGET DIALOG ĐỔI MẬT KHẨU
// ==========================================
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({Key? key}) : super(key: key);

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _passFormKey = GlobalKey<FormState>();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _handleChangePassword() async {
    if (_passFormKey.currentState!.validate()) {
      final editmk = {
        "matKhau": "${_oldPassController.text}",
        "matKhauMoi": "${_newPassController.text}",
      };
      final repose = await API().editmypassword(data:editmk);
      if (repose?.messCode == MessCode.IsOK) {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString("ginseng_user");
        Kttoken? user;
        if (userJson != null) {
          user = Kttoken.fromJson(jsonDecode(userJson));
          Provider.of<AuthProvider>(context, listen: false).updateUserAfterEdit(user);
        }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đổi mật khẩu thành công!')),
          );
        Navigator.pop(context);
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('${repose?.message}hh!')),
        );
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Đổi mật khẩu"),
      content: SingleChildScrollView(
        child: Form(
          key: _passFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPassField(
                controller: _oldPassController,
                label: "Mật khẩu hiện tại",
                obscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
              ),
              const SizedBox(height: 16),
              _buildPassField(
                controller: _newPassController,
                label: "Mật khẩu mới",
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 16),
              _buildPassField(
                controller: _confirmPassController,
                label: "Nhập lại mật khẩu mới",
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (val) {
                  if (val != _newPassController.text) return "Mật khẩu không khớp";
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        // 1. Nút HỦY (Nền trắng, viền xám)
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            side: BorderSide(color: Colors.grey.shade300, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            // Padding này quyết định độ cao của nút
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: _handleChangePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor, // Màu chủ đạo của app
            foregroundColor: Colors.white,                   // Chữ màu trắng
            elevation: 2,                                    // Bóng đổ cao hơn nút Hủy xíu
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),        // Bo góc giống nút Hủy
            ),
            // Padding PHẢI GIỐNG nút Hủy để 2 nút cao bằng nhau
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text("Xác nhận"),
        ),
      ],
    );
  }

  Widget _buildPassField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator ?? (val) => (val == null || val.isEmpty) ? "Vui lòng nhập trường này" : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }
}