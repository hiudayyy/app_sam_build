import 'dart:io';

import 'package:nftsam/screens/register_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../models/login_model.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final api = API();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _showRegister = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // 1. Gán token mặc định
      String? token = "";

      // 2. Bọc try-catch và đặt timeout 3 giây để tránh bị treo app
      try {
        token = await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 3));
      } catch (e) {
        // Nếu lỗi (do iOS chặn Sideloadly), tự động bỏ qua để chạy tiếp
        token = "dummy_token_for_test";
      }

      var model = LoginModel(
        uname: _usernameController.text,
        pass: _passwordController.text,
        deviceToken: token ?? "",
      );

      final authProvider = context.read<AuthProvider>();
      bool isSuccess = await authProvider.login(model);

      if (isSuccess) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  void _handleGoogleLogin() async {
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    bool isSuccess = await authProvider.loginWithGoogle();

    if (isSuccess) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _handleAppleLogin() async {
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    bool isSuccess = await authProvider.loginWithApple();

    if (isSuccess) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showRegister) {
      return RegisterScreen(
        onSwitchToLogin: () => setState(() => _showRegister = false),
      );
    }

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

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
              // 1. HEADER MÀU XANH
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.45,
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
                      Positioned(
                        top: -width * 0.1,
                        right: -width * 0.1,
                        child: _buildCircleDeco(width * 0.5),
                      ),
                      Positioned(
                        top: height * 0.12,
                        left: -width * 0.05,
                        child: _buildCircleDeco(width * 0.3),
                      ),
                      SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(width * 0.03),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    )
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/samnghigia.png',
                                  width: width * 0.12,
                                  height: width * 0.12,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.eco, size: width * 0.12, color: primaryColor),
                                ),
                              ),
                              SizedBox(height: height * 0.02),
                              Text(
                                'Sâm Ngọc Linh Nghị Gia',
                                style: TextStyle(
                                  fontSize: (width * 0.06).clamp(18.0, 24.0),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Sâm thật, giá trị thật',
                                style: TextStyle(
                                  fontSize: (width * 0.035).clamp(12.0, 15.0),
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: height * 0.08),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. FORM CONTAINER MÀU TRẮNG
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: height * 0.68,
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
                      vertical: height * 0.025,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: (width * 0.07).clamp(22.0, 28.0),
                              fontWeight: FontWeight.w800,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Vui lòng đăng nhập để tiếp tục',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: (width * 0.038).clamp(13.0, 16.0),
                            ),
                          ),
                          SizedBox(height: height * 0.02),

                          // Error Message
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              if (authProvider.error != null) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[100]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          authProvider.error!,
                                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          // Username Input
                          _buildResponsiveTextField(
                            context: context,
                            controller: _usernameController,
                            label: 'Tên đăng nhập',
                            icon: Icons.person_outline_rounded,
                            validator: (val) => val!.isEmpty ? 'Vui lòng nhập tài khoản' : null,
                          ),
                          SizedBox(height: height * 0.02),

                          // Password Input
                          _buildResponsiveTextField(
                            context: context,
                            controller: _passwordController,
                            label: 'Mật khẩu',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (val) => val!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                          ),

                          SizedBox(height: height * 0.025),

                          // Login Button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return Container(
                                height: (height * 0.065).clamp(45.0, 55.0),
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
                                  onPressed: authProvider.isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)
                                  )
                                      : Text(
                                    'ĐĂNG NHẬP',
                                    style: TextStyle(
                                      fontSize: (width * 0.04).clamp(14.0, 16.0),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: height * 0.025),

                          // Dải phân cách
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Hoặc đăng nhập với',
                                  style: TextStyle(color: Colors.grey[500], fontSize: (width * 0.035).clamp(12.0, 14.0)),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                            ],
                          ),

                          SizedBox(height: height * 0.025),

                          // Cụm nút đăng nhập Social
                          Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return Column(
                                  children: [
                                    if (Platform.isIOS)
                                      Container(
                                        height: (height * 0.065).clamp(45.0, 55.0),
                                        child: ElevatedButton(
                                          onPressed: authProvider.isLoading ? null : _handleAppleLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.apple, size: 28, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Đăng nhập bằng Apple',
                                                style: TextStyle(
                                                  fontSize: (width * 0.04).clamp(14.0, 16.0),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 16),

                                    // Nút Google Sign In
                                    Container(
                                      height: (height * 0.065).clamp(45.0, 55.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: authProvider.isLoading ? null : _handleGoogleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.grey[800],
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/images/google_logo.png',
                                              height: 24,
                                              width: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Đăng nhập bằng Google',
                                              style: TextStyle(
                                                fontSize: (width * 0.04).clamp(14.0, 16.0),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                          ),

                          SizedBox(height: height * 0.03),

                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Chưa có tài khoản? ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: (width * 0.035).clamp(12.0, 14.0),
                                ),
                              ),
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  return GestureDetector(
                                    onTap: authProvider.isLoading
                                        ? null
                                        : () => setState(() => _showRegister = true),
                                    child: Text(
                                      'Đăng ký ngay',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: (width * 0.035).clamp(12.0, 14.0),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. NÚT QUAY LẠI TRANG HOME
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // Nền mờ mờ sang trọng
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.home, color: Colors.white, size: 20),
                    onPressed: () {
                      // Thay vì pop(), điều hướng thẳng về màn hình HomeScreen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildResponsiveTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    final width = MediaQuery.of(context).size.width;

    final labelSize = (width * 0.035).clamp(12.0, 14.0);
    final inputTextSize = (width * 0.04).clamp(14.0, 16.0);
    final iconSize = (width * 0.055).clamp(20.0, 24.0);
    final verticalPadding = (width * 0.04).clamp(14.0, 18.0);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
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
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade200, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
      validator: validator,
    );
  }
}