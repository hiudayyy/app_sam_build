import 'dart:convert';
import 'dart:io';

import 'package:csam_mobile/api/api_login.dart';
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

class AuthProvider extends ChangeNotifier {
  final api = API();
 // User? _user;
  UserModel? _usermodel;
  Kttoken? _kttoken;
  bool _isLoading = true;
  String? _error;

  AuthProvider() {
    _checkStoredUser();
  }
  //User? get user => _user;
  UserModel? get user => _usermodel;
  bool get isAuthenticated => _usermodel != null;
  bool get isLoading => _isLoading;
  String? get error => _error;



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
        _error = user?.message;
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

  Future<void> logout() async {
    try {
      String _userKey = 'ginseng_user';
      final prefs = await SharedPreferences.getInstance();

      // Lấy chuỗi JSON đã lưu
      String? userJson = prefs.getString(_userKey);
      if (userJson == null) return null; // chưa login lần nào

      // Parse lại thành UserModel
      final Map<String, dynamic> json = jsonDecode(userJson);
      final user = Kttoken.fromJson(json);
      if(user.authenticateToken == ""){
        _error = "Có lỗi xảy ra!";
        return null;
      }
      await api.Logout(user);
      await AuthService.logout();
      _usermodel = null;
    //  _user = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
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
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return _error;

    }
  }
  // bool hasPermission(Permission permission) {
  //   return AuthService.hasPermission(_user, permission);
  // }

  bool hasRole(UserRole role) {
    //return AuthService.hasRole(_user, role);
    return AuthService.hasRolemodel(_kttoken, role);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}