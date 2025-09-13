import 'package:csam_mobile/api/api_login.dart';
import 'package:flutter/material.dart';
import '../api/api.dart';
import '../models/kttoken.dart';
import '../models/login_model.dart';
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
      }else if(user.message == "Ok"){
        _usermodel = user.oneItem?.htTaiKhoan;
      }else{
        _error = user.message;
        _usermodel = null;
      }
    } catch (e) {
   // _error = e.toString();
      _error = "Lỗi không xác định!";
      print(_error);
      _usermodel = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
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
      return _error;
      notifyListeners();
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