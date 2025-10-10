import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kttoken.dart';
import '../models/login_model.dart';
import '../models/message_enum.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../services/local_service.dart';
import 'api.dart';

extension APIExtension on API {
  static const String _userKey = 'ginseng_user';
  Future<ApiResponse<Kttoken>?> login(LoginModel model) async {
    String linkURL = "${host}api/Home/DangNhap";
    var body = jsonEncode(model.toJsonGet());
    final response = await http.post(
      Uri.parse(linkURL),
      headers: headerSvkt1,
      body: body,
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      final data = ApiResponse<Kttoken>.fromJson(
        responseJson,
            (json) => Kttoken.fromJson(json),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(data.oneItem?.toJson()));
      if (data.messCode == MessCode.IsOK) {
        await LocalStoreService.setUserModel(data.oneItem!.htTaiKhoan);
      }
      return data;
    } else {
      return null;
    }
  }
  Future<Kttoken?> resetToken(Kttoken model) async {
    // Tạo URL với query parameters nếu cần
    String linkURL = "${host}api/HeThong/RefreshToken";
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    Kttoken? user;
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
    final headers = {
      ...headerSvkt1,
      "AuthenticateToken": user?.authenticateToken ?? "",
      "FuncsTagActive": user?.funcsTagActives.firstWhere(
            (x) => x.tenController.toLowerCase() == "hethong",
        orElse: () => FuncTagActive(
          tenController: "",
          tenActions: "",
          funcsTagActive: "",
        ),
      ).funcsTagActive ?? "",
    };
    final response = await http.get(
      Uri.parse(linkURL),
      headers: headers,
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      Kttoken? data = Kttoken.fromJson(json);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(data.toJson()));
      if (data.messCode == 1) {
        await LocalStoreService.setUserModel(data.htTaiKhoan);
        return data;
      }
      return data;
    } else {
      return null;
    }
  }
  Future<ApiResponse<UserModel>?> register(UserModel model) async {
    String linkURL = "${host}api/Home/DangKy";

    var body = jsonEncode(model.toJsondk());
    final response = await http.post(
      Uri.parse(linkURL),
      headers: headerSvkt1,
      body: body,
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      final data = ApiResponse<UserModel>.fromJson(
        responseJson,
            (json) => UserModel.fromJson(json),
      );
      return data;
    } else {
      return null;
    }
  }
  Future<Kttoken?> Logout(Kttoken model) async {
    // Tạo URL với query parameters nếu cần
    String linkURL = "${host}api/HeThong/DangXuat";
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    Kttoken? user;
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
    final headers = {
      ...headerSvkt1,
      "AuthenticateToken": user?.authenticateToken ?? "",
      "FuncsTagActive": user?.funcsTagActives.firstWhere(
            (x) => x.tenController.toLowerCase() == "hethong",
        orElse: () => FuncTagActive(
          tenController: "",
          tenActions: "",
          funcsTagActive: "",
        ),
      ).funcsTagActive ?? "",
    };
    final response = await http.get(
      Uri.parse(linkURL),
      headers: headers,
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      Kttoken? data = Kttoken.fromJson(json);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(data.toJson()));
      if (data.messCode == 1) {
        await LocalStoreService.setUserModel(data.htTaiKhoan);
        return data;
      }
      return data;
    } else {
      return null;
    }
  }
}