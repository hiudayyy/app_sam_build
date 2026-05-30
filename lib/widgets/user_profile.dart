import 'dart:async';
import 'dart:convert';

import 'package:nftsam/api/api_taikhoan.dart';
import 'package:flutter/material.dart';
import 'package:nftsam/widgets/wallet_info_dialog.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../models/kttoken.dart';
import '../models/message_enum.dart';
import '../models/user_model.dart'; // Đảm bảo import đúng model của bạn
import '../providers/auth_provider.dart';
import '../services/phantom_service.dart';
import 'app_info_dialog.dart';

import '/app_config.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  // 1. Khởi tạo Service
  final PhantomService _phantomService = PhantomService();

  // Biến lưu địa chỉ ví
  String? _walletAddress;

  // Quản lý subscription để tránh memory leak
  StreamSubscription? _walletSubscription;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user?.wallet?.diaChiVi != null) {
      _walletAddress = user?.wallet?.diaChiVi;
    }
    _walletSubscription =
        _phantomService.walletStream.listen((newAddress) async {
      if (!mounted) return;
      if (newAddress != null && newAddress != _walletAddress) {
        await API().ConectionWallet(AddressWallet: newAddress);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Kết nối ví thành công!",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _getShortAddress(newAddress),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600, // Màu xanh thành công
            behavior: SnackBarBehavior.floating, // Nổi lên trên cho đẹp
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      setState(() {
        _walletAddress = newAddress;
      });
    });
  }

  @override
  void dispose() {
    _walletSubscription?.cancel(); // Hủy lắng nghe khi widget bị đóng
    super.dispose();
  }

  // Hàm rút gọn địa chỉ ví: 8xzt...j12k
  String _getShortAddress(String address) {
    if (address.length < 10) return address;
    return "${address.substring(0, 4)}...${address.substring(address.length - 4)}";
  }

  // Hàm hiển thị dialog xác nhận đăng xuất
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
            onPressed: () async {
              Navigator.of(context).pop();
              authProvider.logout();
              await _phantomService.disconnectWallet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        // Nếu chưa có user (chưa login) thì ẩn widget này đi
        if (user == null) return const SizedBox.shrink();

        return PopupMenuButton<String>(
          offset: const Offset(0, 45),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

          // --- XỬ LÝ SỰ KIỆN MENU ---
          onSelected: (value) {
            switch (value) {
              case 'profile':
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => UserProfileDialog(user: user),
                );
                break;

              // --- CASE XỬ LÝ VÍ ---
              case 'connect_wallet':
                if (_walletAddress == null) {
                  // A. CHƯA KẾT NỐI -> GỌI HÀM CONNECT
                  _phantomService.connectWallet().catchError((e) {
                    AppConfig.printEx("Lỗi kết nối Phantom: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Lỗi: Không tìm thấy ứng dụng Phantom Wallet")),
                    );
                  });
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => WalletInfoDialog(
                      walletAddress: _walletAddress!,
                      onDisconnect: () async {
                        // Gọi hàm xóa dữ liệu trong Service
                        await _phantomService.disconnectWallet();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Đã ngắt kết nối ví"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  );
                }
                break;

              case 'app_info':
                showDialog(
                  context: context,
                  builder: (context) => const AppInfoDialog(),
                );
                break;

              case 'logout':
                _showLogoutDialog(context, authProvider);
                break;
            }
          },

          // --- DANH SÁCH MENU ITEM ---
          itemBuilder: (context) => [
            // 1. Hồ sơ cá nhân
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

            // 2. VÍ PHANTOM (Thay đổi giao diện động)
            PopupMenuItem(
              value: 'connect_wallet',
              child: Row(
                children: [
                  Icon(
                    _walletAddress == null
                        ? Icons
                            .account_balance_wallet_outlined // Icon Ví thường
                        : Icons.verified_user_rounded, // Icon Tick xanh/tím
                    size: 20,
                    color: _walletAddress == null
                        ? Colors.blueGrey
                        : Colors.purple,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _walletAddress == null
                          ? 'Kết nối ví Phantom'
                          : 'Ví: ${_getShortAddress(_walletAddress!)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _walletAddress == null
                            ? Colors.black87
                            : Colors.purple.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Thông tin ứng dụng
            const PopupMenuItem(
              value: 'app_info',
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Thông tin ứng dụng',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const PopupMenuDivider(),

            // 4. Đăng xuất
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

          // --- NÚT BẤM HIỂN THỊ TRÊN APPBAR ---
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey.shade100,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    (user.tenTaiKhoan ?? '').trim().isNotEmpty
                        ? user.tenTaiKhoan[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}

class UserProfileDialog extends StatefulWidget {
  final UserModel user;

  const UserProfileDialog({Key? key, required this.user}) : super(key: key);

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _sdtController;
  late TextEditingController _emailController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _sdtController = TextEditingController();
    _emailController = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _sdtController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (_formKey.currentState!.validate()) {
      final edittk = {
        "sdt": _sdtController.text,
        "email": _emailController.text,
      };
      final repose = await API().editmytaikhoan(data: edittk);
      if (repose?.messCode == MessCode.IsOK) {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString("ginseng_user");
        Kttoken? user;
        if (userJson != null) {
          user = Kttoken.fromJson(jsonDecode(userJson));
          Provider.of<AuthProvider>(context, listen: false)
              .updateUserAfterEdit(user);
        }
      }
      if (repose != null && repose.message == "OK") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công!')),
        );
      }
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _handleDeleteAccount() async {
    // SỬA ĐỔI TẠI ĐÂY: Gọi API Xóa tài khoản (Soft Delete)
    final repose = await API().deleteTaiKhoan();

    if (repose?.messCode == MessCode.IsOK) {
      if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
           content: Text('Đã xóa tài khoản thành công!'),
           backgroundColor: Colors.green,
         ),
       );

      Navigator.of(context).pop();
      Provider.of<AuthProvider>(context, listen: false).logout();
    } else {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(repose?.message ?? 'Xóa tài khoản thất bại!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmDialog() {
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final String inputText = confirmController.text.trim().toUpperCase();
          final bool isConfirmed = inputText == 'XÓA' || inputText == 'XOÁ';

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Xóa tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bạn có chắc chắn muốn xóa tài khoản này không? Mọi thông tin đăng nhập sẽ bị vô hiệu hóa và bạn không thể tự đăng nhập lại.',
                    style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vui lòng nhập chữ "XÓA" để xác nhận:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'XÓA',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: isConfirmed
                    ? () {
                  Navigator.of(ctx).pop();
                  _handleDeleteAccount();
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red.shade200,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Đồng ý xóa', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String ngayKhoiTaoFormatted = 'Không rõ ngày';
    if (widget.user.ngayKhoiTao != null &&
        widget.user.ngayKhoiTao!.isNotEmpty) {
      try {
        final DateTime dateTime = DateTime.parse(widget.user.ngayKhoiTao);
        ngayKhoiTaoFormatted =
            DateFormat('dd/MM/yyyy').format(dateTime.toLocal());
      } catch (_) {
        ngayKhoiTaoFormatted = widget.user.ngayKhoiTao;
      }
    }

    // Lấy màu chủ đạo của app
    final primaryColor = Theme.of(context).primaryColor;

    return Dialog(
      backgroundColor: Colors.white, // Đảm bảo nền trắng tinh
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Chỉnh sửa hồ sơ' : 'Hồ sơ cá nhân',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 20, color: Colors.black54),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),

                // --- AVATAR LỚN ---
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: primaryColor.withOpacity(0.08),
                        child: Text(
                          (widget.user.tenTaiKhoan ?? '?').trim().isNotEmpty
                              ? widget.user.tenTaiKhoan![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                          ),
                        ),
                      ),
                    ),
                    if (_isEditing)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- THÔNG TIN TEXT ---
                Text(
                  widget.user.tenTaiKhoan ?? "Tài khoản",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  "Thành viên từ: $ngayKhoiTaoFormatted",
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),

                // --- FORM ĐIỀN THÔNG TIN ---
                _buildTextField(
                  label: 'Email liên hệ',
                  controller: _emailController,
                  icon: Icons.email_rounded,
                  enabled: _isEditing,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final bool emailValid =
                          RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(value);
                      if (!emailValid) return 'Email không đúng định dạng';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // --- CÁC NÚT CHỨC NĂNG (Giao diện xem) ---
                if (!_isEditing) ...[
                  // Nút Đổi mật khẩu (Màu Primary sáng)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ChangePasswordDialog(),
                        );
                      },
                      icon: const Icon(Icons.lock_outline_rounded, size: 20),
                      label: const Text('Đổi mật khẩu',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nút Xóa tài khoản (Màu Đỏ sáng) - ĐÃ CẬP NHẬT
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showDeleteConfirmDialog,
                      icon: const Icon(Icons.person_remove_outlined, size: 20),
                      label: const Text('Xóa tài khoản',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nút Chỉnh sửa (Đen xám sang trọng)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Chỉnh sửa thông tin',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor:
                            const Color(0xFF2D2D2D), // Màu đen xám Dark Mode
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],

                // --- NÚT ACTION (Giao diện Sửa) ---
                if (_isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _emailController.text = widget.user.email ?? '';
                            setState(() => _isEditing = false);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Hủy bỏ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleSaveProfile,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Lưu thay đổi',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
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

  // --- HÀM BUILD TEXT FIELD GIAO DIỆN MỚI ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                color: enabled
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade400,
                size: 22),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade50,

            // Viền mặc định: Mờ nhạt hoặc không có nếu không sửa
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),

            // Viền khi focus: Đậm màu chủ đạo
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
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
        "matKhau": _oldPassController.text,
        "matKhauMoi": _newPassController.text,
      };
      final repose = await API().editmypassword(data: editmk);
      if (repose?.messCode == MessCode.IsOK) {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString("ginseng_user");
        Kttoken? user;
        if (userJson != null) {
          user = Kttoken.fromJson(jsonDecode(userJson));
          Provider.of<AuthProvider>(context, listen: false)
              .updateUserAfterEdit(user);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công!')),
        );
        Navigator.pop(context);
      } else {
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
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (val) {
                  if (val != _newPassController.text)
                    return "Mật khẩu không khớp";
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
            backgroundColor:
                Theme.of(context).primaryColor, // Màu chủ đạo của app
            foregroundColor: Colors.white, // Chữ màu trắng
            elevation: 2, // Bóng đổ cao hơn nút Hủy xíu
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Bo góc giống nút Hủy
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
      validator: validator ??
          (val) =>
              (val == null || val.isEmpty) ? "Vui lòng nhập trường này" : null,
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
