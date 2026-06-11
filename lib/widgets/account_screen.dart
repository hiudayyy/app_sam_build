import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nftsam/api/api_taikhoan.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../models/kttoken.dart';
import '../models/message_enum.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../services/phantom_service.dart';
import '../widgets/wallet_info_dialog.dart';
import 'app_info_dialog.dart';

import '/app_config.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final PhantomService _phantomService = PhantomService();
  String? _walletAddress;
  StreamSubscription? _walletSubscription;

  // Màu nền tổng thể xám nhạt hiện đại
  final Color backgroundColor = const Color(0xFFF4F7F9);

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user?.wallet?.diaChiVi != null) {
      _walletAddress = user?.wallet?.diaChiVi;
    }

    _walletSubscription = _phantomService.walletStream.listen((newAddress) async {
      if (!mounted) return;
      if (newAddress != null && newAddress != _walletAddress) {
        await API().ConectionWallet(AddressWallet: newAddress);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Kết nối ví thành công!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(_getShortAddress(newAddress), style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    _walletSubscription?.cancel();
    super.dispose();
  }

  String _getShortAddress(String address) {
    if (address.length < 10) return address;
    return "${address.substring(0, 4)}...${address.substring(address.length - 4)}";
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26),
            SizedBox(width: 12),
            Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF102A43))),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?',
          style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              authProvider.logout();
              await _phantomService.disconnectWallet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

        if (user == null) {
          return _buildGuestUI(context);
        }
        return _buildLoggedInUI(context, user, authProvider);
      },
    );
  }

  // ==========================================
  // GIAO DIỆN KHI CHƯA ĐĂNG NHẬP (GUEST)
  // ==========================================
  Widget _buildGuestUI(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fingerprint_rounded, size: 80, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 24),
              const Text('Chưa đăng nhập', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF102A43))),
              const SizedBox(height: 12),
              Text(
                'Vui lòng đăng nhập để quản lý hồ sơ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Đăng nhập ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // GIAO DIỆN KHI ĐÃ ĐĂNG NHẬP (PREMIUM)
  // ==========================================
  Widget _buildLoggedInUI(BuildContext context, UserModel user, AuthProvider authProvider) {
    String ngayKhoiTaoFormatted = 'Không rõ ngày';
    if (user.ngayKhoiTao != null && user.ngayKhoiTao.isNotEmpty) {
      try {
        final DateTime dateTime = DateTime.parse(user.ngayKhoiTao);
        ngayKhoiTaoFormatted = DateFormat('dd/MM/yyyy').format(dateTime.toLocal());
      } catch (_) {
        ngayKhoiTaoFormatted = user.ngayKhoiTao;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --- PROFILE CARD ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF43A047), width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(
                        (user.tenTaiKhoan ?? '?').trim().isNotEmpty ? user.tenTaiKhoan![0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w900, fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.tenTaiKhoan ?? "Người dùng",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.email_outlined, size: 13, color: Color(0xFF43A047)),
                          const SizedBox(width: 5),
                          Expanded(child: Text(user.email ?? "Chưa cập nhật email",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ]),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 5),
                            Text("Từ $ngayKhoiTaoFormatted",
                                style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  // Edit shortcut
                  GestureDetector(
                    onTap: () => showDialog(context: context, barrierDismissible: false, builder: (context) => UserProfileDialog(user: user)),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- NHÓM BẢO MẬT & KẾT NỐI ---
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text("BẢO MẬT & KẾT NỐI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.2)),
            ),
            _buildMenuGroup([
              _buildModernMenuItem(
                icon: _walletAddress == null ? Icons.account_balance_wallet_outlined : Icons.account_balance_wallet_rounded,
                title: 'Ví Phantom',
                subtitle: _walletAddress == null ? 'Chưa kết nối' : _getShortAddress(_walletAddress!),
                iconColor: const Color(0xFF8E24AA), // Tím Phantom
                onTap: () {
                  if (_walletAddress == null) {
                    _phantomService.connectWallet().catchError((e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Không tìm thấy ứng dụng Phantom Wallet"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
                    });
                  } else {
                    showDialog(context: context, builder: (context) => WalletInfoDialog(walletAddress: _walletAddress!, onDisconnect: () async {
                      await _phantomService.disconnectWallet();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Đã ngắt kết nối ví"), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
                    },
                    ));
                  }
                },
              ),
              _buildDivider(),
              _buildModernMenuItem(
                icon: Icons.lock_outline_rounded,
                title: 'Đổi mật khẩu',
                iconColor: const Color(0xFFF57C00), // Cam ấm
                onTap: () {
                  showDialog(context: context, builder: (context) => const ChangePasswordDialog());
                },
              ),
            ]),

            const SizedBox(height: 20),

            // --- NHÓM HỆ THỐNG ---
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text("HỆ THỐNG", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.2)),
            ),
            _buildMenuGroup([
              _buildModernMenuItem(
                icon: Icons.info_outline_rounded,
                title: 'Thông tin ứng dụng',
                iconColor: const Color(0xFF546E7A), // Blue Grey
                onTap: () {
                  showDialog(context: context, builder: (context) => const AppInfoDialog());
                },
              ),
              _buildDivider(),
              _buildModernMenuItem(
                icon: Icons.logout_rounded,
                title: 'Đăng xuất',
                iconColor: Colors.redAccent,
                hideArrow: true,
                onTap: () => _showLogoutDialog(context, authProvider),
              ),
            ]),

            const SizedBox(height: 100), // Đệm đáy an toàn
          ],
        ),
      ),
    );
  }

  // --- HÀM BỌC NHÓM MENU ---
  Widget _buildMenuGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(children: children),
        ),
      ),
    );
  }

  // --- ĐƯỜNG KẺ PHÂN CÁCH MỜ ---
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70, right: 16),
      child: Divider(height: 1, thickness: 1, color: const Color(0xFFE8F5E9)),
    );
  }

  // --- WIDGET MENU TILE HIỆN ĐẠI TỐI ƯU ---
  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    bool hideArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      highlightColor: const Color(0xFFF5F9F5),
      splashColor: iconColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: hideArrow ? Colors.redAccent : const Color(0xFF1A1A1A),
                  )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  ]
                ],
              ),
            ),
            if (!hideArrow)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF2E7D32)),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CÁC DIALOG CHỨC NĂNG (GIAO DIỆN CHUẨN)
// ==========================================

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
          if(mounted) {
            Provider.of<AuthProvider>(context, listen: false).updateUserAfterEdit(user);
          }
        }
      }
      if (repose != null && repose.message == "OK") {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cập nhật thông tin thành công!'),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _handleDeleteAccount() async {
    final repose = await API().deleteTaiKhoan();

    if (repose?.messCode == MessCode.IsOK) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xóa tài khoản thành công!'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          final bool isConfirmed = inputText == 'YES';

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
                ),
                const SizedBox(width: 12),
                const Text('Xóa tài khoản', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF102A43))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hành động này không thể hoàn tác. Mọi dữ liệu liên quan sẽ bị vô hiệu hóa vĩnh viễn.',
                    style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nhập chữ "YES" để xác nhận:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF102A43)),
                    decoration: InputDecoration(
                      hintText: 'YES',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Hủy', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              ElevatedButton(
                onPressed: isConfirmed
                    ? () {
                  Navigator.of(ctx).pop();
                  _handleDeleteAccount();
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red.shade100,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Đồng ý xóa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Chỉnh sửa hồ sơ' : 'Hồ sơ cá nhân',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF102A43)),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 22, color: Colors.black54),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 28),
                _buildTextField(
                  label: 'Email liên hệ',
                  controller: _emailController,
                  icon: Icons.email_rounded,
                  enabled: _isEditing,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final bool emailValid = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
                      if (!emailValid) return 'Email không đúng định dạng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                if (!_isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showDeleteConfirmDialog,
                      icon: const Icon(Icons.person_remove_outlined, size: 20),
                      label: const Text('Xóa tài khoản', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Chỉnh sửa thông tin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
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
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Hủy bỏ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleSaveProfile,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
        ),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: enabled ? const Color(0xFF102A43) : Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: enabled ? const Color(0xFF2E7D32) : Colors.grey.shade400, size: 22),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade50,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}

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
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đổi mật khẩu thành công!'),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${repose?.message}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _passFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Đổi mật khẩu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF102A43))),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 22, color: Colors.black54),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text('Vui lòng nhập mật khẩu hiện tại và mật khẩu mới.', style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5)),
                const SizedBox(height: 28),
                _buildPassField(controller: _oldPassController, label: "Mật khẩu hiện tại", obscure: _obscureOld, onToggle: () => setState(() => _obscureOld = !_obscureOld)),
                const SizedBox(height: 16),
                _buildPassField(controller: _newPassController, label: "Mật khẩu mới", obscure: _obscureNew, onToggle: () => setState(() => _obscureNew = !_obscureNew)),
                const SizedBox(height: 16),
                _buildPassField(
                  controller: _confirmPassController,
                  label: "Nhập lại mật khẩu mới",
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Vui lòng nhập trường này";
                    if (val != _newPassController.text) return "Mật khẩu không khớp";
                    return null;
                  },
                ),
                const SizedBox(height: 36),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          elevation: 0, backgroundColor: Colors.grey.shade100, foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Hủy bỏ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleChangePassword,
                        style: ElevatedButton.styleFrom(
                          elevation: 0, backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildPassField({required TextEditingController controller, required String label, required bool obscure, required VoidCallback onToggle, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
        TextFormField(
          controller: controller, obscureText: obscure, validator: validator ?? (val) => (val == null || val.isEmpty) ? "Vui lòng nhập thông tin" : null,
          style: const TextStyle(color: Color(0xFF102A43), fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 22),
            suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded), color: Colors.grey.shade500, onPressed: onToggle),
            filled: true, fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}