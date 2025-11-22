import 'dart:io';

import 'package:csam_mobile/api/api_login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
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


  //User? get user => _user;
  UserModel? get user => _usermodel;
  bool get isAuthenticated => _usermodel != null;
  bool get isLoading => _isLoading;
  String? get error => _error;


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


}