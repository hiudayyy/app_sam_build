import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterScreen({Key? key, required this.onSwitchToLogin})
      : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- VALIDATION LOGIC GIỮ NGUYÊN ---
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập tên tài khoản';
    if (value.length < 3) return 'Tên tài khoản phải có ít nhất 3 ký tự';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Chỉ chứa chữ cái, số và dấu gạch dưới';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
      return 'Số điện thoại phải có 10-11 chữ số';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    // if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (value != _passwordController.text) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final credentials = UserModel(
          tenTaiKhoan: _usernameController.text.trim(),
          matKhau: _passwordController.text,
          email: _emailController.text.trim(),
          id: '',
          ngayKhoiTao: DateTime.now().toString(),
          trangThai: 1,
          htPhanQuyenTaiKhoans: []);

      final authProvider = context.read<AuthProvider>();
      final errorMsg = await authProvider.register(credentials);

      if (!mounted) return;

      // HIỂN THỊ DIALOG KẾT QUẢ (GIỮ NGUYÊN LOGIC CŨ NHƯNG STYLE LẠI MỘT CHÚT)
      await   showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (errorMsg == null) ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  (errorMsg == null) ? Icons.check_circle : Icons.error,
                  color: (errorMsg == null) ? Colors.green.shade600 : Colors.red.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (errorMsg == null) ? 'Thành công!' : 'Thất bại',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (errorMsg == null)
                    ? 'Tài khoản đã được tạo thành công.'
                    : errorMsg,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              if (errorMsg == null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.person, _usernameController.text),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.email, _emailController.text),
                    ],
                  ),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (errorMsg == null) {
                  widget.onSwitchToLogin();
                }
              },
              child: Text(
                (errorMsg == null) ? 'Đăng nhập ngay' : 'Đóng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: (errorMsg == null) ? const Color(0xFF15803D) : Colors.red,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kích thước màn hình
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Màu chủ đạo đồng bộ với LoginScreen
    final primaryColor = const Color(0xFF15803D);
    final secondaryColor = const Color(0xFF166534);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SizedBox(
          height: height,
          width: width,
          child: Stack(
            children: [
              // 1. HEADER (Chiều cao nhỏ hơn màn hình Login một chút để dành chỗ cho form dài)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.35, // Giảm từ 0.45 xuống 0.35
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, secondaryColor],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Họa tiết trang trí
                      Positioned(
                          top: -width * 0.2,
                          left: -width * 0.1,
                          child: _buildCircleDeco(width * 0.6)),
                      Positioned(
                          bottom: width * 0.1,
                          right: -width * 0.1,
                          child: _buildCircleDeco(width * 0.4)),

                      // Tiêu đề & Logo
                      SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/samnghigia.png', // Đảm bảo bạn có ảnh này hoặc dùng Icon
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (c, o, s) => Icon(Icons.eco, color: primaryColor, size: 40),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Đăng ký tài khoản',
                                style: TextStyle(
                                  fontSize: (width * 0.06).clamp(20.0, 26.0),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gia nhập hệ thống',
                                style: TextStyle(
                                  fontSize: (width * 0.035).clamp(12.0, 14.0),
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: height * 0.04), // Khoảng trống đẩy nội dung lên
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. FORM CONTAINER
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: height * 0.72, // Chiếm 72% chiều cao để chứa đủ 5 trường input
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.06,
                      vertical: height * 0.03,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          // Username
                          _buildResponsiveTextField(
                            context: context,
                            controller: _usernameController,
                            label: 'Tên tài khoản',
                            icon: Icons.person_outline_rounded,
                            validator: _validateUsername,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildResponsiveTextField(
                            context: context,
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            inputType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          // const SizedBox(height: 16),
                          //
                          // // Phone
                          // _buildResponsiveTextField(
                          //   context: context,
                          //   controller: _phoneController,
                          //   label: 'Số điện thoại',
                          //   icon: Icons.phone_android_rounded,
                          //   inputType: TextInputType.phone,
                          //   validator: _validatePhone,
                          // ),
                          const SizedBox(height: 16),

                          // Password
                          _buildResponsiveTextField(
                            context: context,
                            controller: _passwordController,
                            label: 'Mật khẩu',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: !_showPassword,
                            onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          _buildResponsiveTextField(
                            context: context,
                            controller: _confirmPasswordController,
                            label: 'Xác nhận mật khẩu',
                            icon: Icons.check_circle_outline_rounded,
                            isPassword: true,
                            obscureText: !_showConfirmPassword,
                            onTogglePassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            validator: _validateConfirmPassword,
                          ),
                          const SizedBox(height: 24),

                          // Register Button
                          Container(
                            height: (height * 0.065).clamp(48.0, 55.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                                  : Text(
                                'ĐĂNG KÝ',
                                style: TextStyle(
                                  fontSize: (width * 0.04).clamp(14.0, 16.0),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Switch to Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Đã có tài khoản? ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: (width * 0.035).clamp(12.0, 14.0),
                                ),
                              ),
                              GestureDetector(
                                onTap: widget.onSwitchToLogin,
                                child: Text(
                                  'Đăng nhập ngay',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: (width * 0.035).clamp(12.0, 14.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget trang trí
  Widget _buildCircleDeco(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
    );
  }

  // Widget TextField dùng chung (Responsive)
  Widget _buildResponsiveTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType inputType = TextInputType.text,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    final width = MediaQuery.of(context).size.width;

    // Tính toán size động
    final labelSize = (width * 0.035).clamp(12.0, 14.0);
    final inputTextSize = (width * 0.04).clamp(14.0, 16.0);
    final iconSize = (width * 0.055).clamp(20.0, 22.0);
    final verticalPadding = (width * 0.04).clamp(14.0, 16.0); // Padding nhỏ hơn login chút vì nhiều trường

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: inputType,
      style: TextStyle(fontSize: inputTextSize, color: Colors.grey[900]),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: labelSize),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: Icon(icon, color: Colors.grey[500], size: iconSize),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.grey[500],
            size: iconSize,
          ),
          onPressed: onTogglePassword,
        )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF15803D), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade200, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
      validator: validator,
    );
  }
}