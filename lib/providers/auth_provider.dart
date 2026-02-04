import 'dart:convert';
import 'dart:io';

import 'package:nftsam/api/api_login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../models/kttoken.dart';
import '../models/login_model.dart';
import '../models/message_enum.dart';
import '../models/user.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/signalr_service.dart';

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



  Future<void> updateUserAfterEdit(Kttoken updatedTokenData) async {
    try {
      _usermodel = updatedTokenData.htTaiKhoan;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ginseng_user', jsonEncode(updatedTokenData.toJson()));
      notifyListeners();
    } catch (e) {
      print("Lỗi khi cập nhật local user: $e");
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

  Future<void> login(LoginModel credentials) async {
      try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      final user = await api.login(credentials);
      if(user == null){
        _error = "Lỗi API";
        _usermodel = null;
      }else if(user.messCode == MessCode.IsOK){
        _usermodel = user.oneItem?.htTaiKhoan;
      }else{
        _error = user.message;
        _usermodel = null;
      }
    } catch (e) {
        if (e is SocketException) {
          _error = e.message; // "Connection refused"
        } else if (e is ClientException) {
          _error = e.message;
        } else {
          _error = "Lỗi không xác định!";
        }
      _usermodel = null;
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
    _error = null;
    try {
      const String _userKey = 'ginseng_user';
      final prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString(_userKey);
      if (userJson == null) {
        return;
      }
      final Map<String, dynamic> json = jsonDecode(userJson);
      final user = Kttoken.fromJson(json);
      if (user.authenticateToken == "") {
        return;
      }
      await api.Logout(user);
    } catch (e) {
      _error = e.toString();
    } finally {
      SignalRService().disconnect();
      await AuthService.logout();
      _usermodel = null;
      notifyListeners();
    }
  }

  Future<String?> register(UserModel credentials) async {
    try {
      notifyListeners();
      var item = await api.register(credentials);
      _usermodel = null;
      _error = null;
      if(item?.message != "OK"){
        return item?.message;
      }else{
        return _error = "Có lỗi xảy ra!";
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