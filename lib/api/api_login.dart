import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kttoken.dart';
import '../models/login_model.dart';
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
      if (data.messCode == 1) {
        await LocalStoreService.setUserModel(data.oneItem!.htTaiKhoan);
      }
      return data;
    } else {
      return null;
    }
  }
  Future<Kttoken?> resetToken(Kttoken model) async {
    String linkURL = "${host}api/HeThong/RefreshToken";
    var body = jsonEncode(model.toJson());
    final response = await http.post(
      Uri.parse(linkURL),
      headers: {
        ...headerSvkt1,
        "authenticateToken": model.refreshToken ?? "" ,
      },
      body: body,
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
}