import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nftsam/api/api_login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../api/api.dart';
import '../main.dart';
import '../models/kttoken.dart';
import '../models/login_model.dart';
import '../models/message_enum.dart';
import '../models/user.dart';
import '../models/user_model.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../services/signalr_service.dart';

import '/app_config.dart';

class AuthProvider extends ChangeNotifier {
  final api = API();
  UserModel? _usermodel;
  Kttoken? _kttoken;
  bool _isLoading = true;
  String? _error;

  AuthProvider() {
    _checkStoredUser();
  }
  UserModel? get user => _usermodel;
  bool get isAuthenticated => _usermodel != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;
  final String _serverClientId =
      "525482222879-48iplli6p73kap7go2dbk4iuv56js9ep.apps.googleusercontent.com";
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      try {
        await _googleSignIn.initialize(
          serverClientId: _serverClientId,
        );
        _isGoogleSignInInitialized = true;
      } catch (e) {
        AppConfig.printEx("Lỗi cấu hình khởi tạo Google Sign-In: $e");
      }
    }
  }

  Future<void> updateUserAfterEdit(Kttoken updatedTokenData) async {
    try {
      _usermodel = updatedTokenData.htTaiKhoan;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'ginseng_user', jsonEncode(updatedTokenData.toJson()));
      notifyListeners();
    } catch (e) {
      AppConfig.printEx("Lỗi khi cập nhật local user: $e");
    }
  }

  Future<void> _checkStoredUser() async {
    try {
      _isLoading = true;
      notifyListeners();
      final storedUser = await AuthService.getStoredUser();
      _usermodel = storedUser;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _usermodel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.authenticate();

      if (googleUser == null) {
        _error = "Bạn đã hủy đăng nhập.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        _error = "Không lấy được Token từ Google.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
      String? deviceToken = await FirebaseMessaging.instance.getToken();
      final user = await api.googleLogin(
        idToken: idToken,
        deviceToken: deviceToken ?? "",
      );
      AppConfig.printEx("mess code ${user?.message}");
      if (user == null) {
        _error = "Lỗi kết nối hoặc lỗi server (Response null)";
        _usermodel = null;
        _isLoading = false;
        notifyListeners();
        return false; // Đánh dấu thất bại
      } else if (user.messCode == MessCode.IsOK) {
        // THÀNH CÔNG
        _usermodel = user.oneItem?.htTaiKhoan;
        _isLoading = false;
        notifyListeners();
        return true; // Đánh dấu thành công
      } else {
        // LỖI TỪ SERVER TRẢ VỀ (429, Sai pass, v.v.)
        _error = user.message ?? "Đăng nhập thất bại";
        _usermodel = null;
        _isLoading = false;
        notifyListeners();
        return false; // Đánh dấu thất bại
      }
    } catch (e) {
      AppConfig.printEx("Lỗi: $e");
      _error = "Sự cố kết nối hệ thống.";
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithApple() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? idToken = credential.identityToken;
      final String? authorizationCode = credential.authorizationCode;
      if (idToken == null) {
        _error = "Không lấy được Token từ Apple.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      String? deviceToken = await FirebaseMessaging.instance.getToken();

      final user = await api.appleLogin(
        identityToken: idToken,
        deviceToken: deviceToken ?? "",
        authorizationCode: authorizationCode ?? "",
      );

      if (user == null) {
        _error = "Lỗi kết nối hoặc lỗi server (Response null)";
        _usermodel = null;
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (user.messCode == MessCode.IsOK) {
        _usermodel = user.oneItem?.htTaiKhoan;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = user.message ?? "Đăng nhập thất bại";
        _usermodel = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      AppConfig.printEx("Lỗi Apple Login: $e");
      if (e.toString().contains('canceled')) {
        _error = "Bạn đã hủy đăng nhập.";
      } else {
        _error = "Sự cố kết nối hệ thống.";
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(LoginModel credentials) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Gọi API
      final user = await api.login(credentials);

      if (user == null) {
        _error = "Lỗi kết nối hoặc lỗi server (Response null)";
        _usermodel = null;
        return false; // Đánh dấu thất bại
      } else if (user.messCode == MessCode.IsOK) {
        // THÀNH CÔNG
        _usermodel = user.oneItem?.htTaiKhoan;
        return true; // Đánh dấu thành công
      } else {
        // LỖI TỪ SERVER TRẢ VỀ (429, Sai pass, v.v.)
        _error = user.message ?? "Đăng nhập thất bại";
        _usermodel = null;
        return false; // Đánh dấu thất bại
      }
    } catch (e) {
      // XỬ LÝ EXCEPTION
      if (e is SocketException) {
        _error = "Không có kết nối mạng hoặc server không phản hồi";
      } else if (e is ClientException) {
        _error = "Lỗi Client: ${e.message}";
      } else {
        _error = "Lỗi không xác định: $e";
      }
      _usermodel = null;
      return false; // Đánh dấu thất bại
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> resetTokenAu(Kttoken credentials) async {
  //   try {
  //     _isLoading = true;
  //     _error = null;
  //     notifyListeners();
  //     final user = await api.resetToken(credentials);
  //     if(user == null){
  //       _error = user?.message;
  //       _usermodel = null;
  //     }else if(user.messCode == MessCode.IsOK){
  //       _usermodel = user.oneItem?.htTaiKhoan;
  //     }else{
  //       _error = user.message;
  //       _usermodel = null;
  //     }
  //   } catch (e) {
  //     if (e is SocketException) {
  //       _error = e.message;
  //     } else if (e is ClientException) {
  //       _error = e.message;
  //     } else {
  //       _error = "Lỗi không xác định!";
  //     }
  //     _usermodel = null;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
  Future<void> resetTokenAu(Kttoken credentials) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Báo UI hiện loading ngay lập tức

    try {
      final response = await api.resetToken(credentials);

      // 1. Xử lý trường hợp Response bị null (lỗi kết nối hoặc parse lỗi)
      if (response == null) {
        _error = "Không nhận được phản hồi từ hệ thống.";
        _usermodel = null;
        return; // Dừng hàm tại đây, nhảy xuống finally
      }

      // 2. Kiểm tra MessCode
      if (response.messCode == MessCode.IsOK) {
        _usermodel = response.oneItem?.htTaiKhoan;
      } else {
        _error = response.message;
        _usermodel = null;
      }
    } catch (e) {
      // 4. Phân loại lỗi Exception
      if (e is SocketException) {
        _error = "Lỗi kết nối mạng. Vui lòng kiểm tra lại đường truyền.";
      } else if (e is ClientException) {
        _error = "Lỗi kết nối máy chủ: ${e.message}";
      } else {
        _error = "Lỗi không xác định: $e";
      }
      _usermodel = null;
    } finally {
      // 5. Luôn tắt loading
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // 1. Ép error bằng null ngay lập tức để UI không hiện lỗi cũ
    _error = null;
    try {
      const String _userKey = 'ginseng_user';
      final prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString(_userKey);

      if (userJson != null) {
        final Map<String, dynamic> json = jsonDecode(userJson);
        final user = Kttoken.fromJson(json);
        if (user.authenticateToken != "") {
          try {
            await api.Logout(user);
          } catch (apiError) {
            AppConfig.printEx("API Logout failed (Ignored): $apiError");
          }
        }
      }
    } catch (e) {
      AppConfig.printEx("Local Logout error: $e");
    } finally {
      // 2. Dọn dẹp sạch sẽ
      try {
        SignalRService().disconnect();
        await AuthService.logout();
      } catch (_) {}

      _usermodel = null;

      // 3. CHỐT CHẶN CUỐI CÙNG: ÉP ERROR VỀ NULL
      _error = null;

      notifyListeners();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) =>
            false, // false nghĩa là xóa hết các trang trước đó
      );
    }
  }

  Future<String?> register(UserModel credentials) async {
    try {
      notifyListeners();
      var item = await api.register(credentials);
      _usermodel = null;
      _error = null;
      if (item?.message != "OK") {
        return item?.message;
      } else {
        return _error = null;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return _error;
    }
  }

  bool hasRole(UserRole role) {
    return AuthService.hasRolemodel(_kttoken, role);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
