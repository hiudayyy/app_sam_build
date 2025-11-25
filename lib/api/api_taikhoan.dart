import 'dart:convert';
import 'dart:io';
import 'package:nftsam/api/api_login.dart';
import 'package:nftsam/models/nhat_ky.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kttoken.dart';
import '../models/login_model.dart';
import '../models/message_enum.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../models/vuontrong/caysam_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/vuontrong_model.dart';
import '../services/local_service.dart';
import 'api.dart';

extension APIExtension on API {
  Future<ApiResponse<Kttoken>?> editmytaikhoan({
    required Map<String, dynamic> data, // modelJson
  }) async {
    final url = Uri.parse("${host}api/TaiKhoan/EditMyTaiKhoan");
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    Kttoken? user;
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
    final headers = {
      ...headerSvkt1,
      "Content-Type": "application/json",
      "AuthenticateToken": user?.authenticateToken ?? "",
      "FuncsTagActive": user?.funcsTagActives.firstWhere(
            (x) => x.tenController.toLowerCase() == "taikhoan",
        orElse: () => FuncTagActive(
          tenController: "",
          tenActions: "",
          funcsTagActive: "",
        ),
      ).funcsTagActive ?? "",
    };

    // 🔹 Gửi request POST
    final response =
    await http.post(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) {

      final jsonRes = jsonDecode(response.body);
      final data = ApiResponse<Kttoken>.fromJson(
        jsonRes,
            (json) => Kttoken.fromJson(json),
      );
      final tokd = await API().resetToken(user!);
      print(tokd);
      return data;
    } else {
      print("❌ Lỗi: ${response.statusCode} - $response");
      return null;
    }
  }
  Future<ApiResponse<Kttoken>?> editmypassword({
    required Map<String, dynamic> data, // modelJson
  }) async {
    final url = Uri.parse("${host}api/TaiKhoan/EditMyPassword");
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    Kttoken? user;
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
    final headers = {
      ...headerSvkt1,
      "Content-Type": "application/json",
      "AuthenticateToken": user?.authenticateToken ?? "",
      "FuncsTagActive": user?.funcsTagActives.firstWhere(
            (x) => x.tenController.toLowerCase() == "taikhoan",
        orElse: () => FuncTagActive(
          tenController: "",
          tenActions: "",
          funcsTagActive: "",
        ),
      ).funcsTagActive ?? "",
    };

    // 🔹 Gửi request POST
    final response =
    await http.post(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) {

      final jsonRes = jsonDecode(response.body);
      final data = ApiResponse<Kttoken>.fromJson(
        jsonRes,
            (json) => Kttoken.fromJson(json),
      );
      final tokd = await API().resetToken(user!);
      print(tokd);
      return data;
    } else {
      print("❌ Lỗi: ${response.statusCode} - $response");
      return null;
    }
  }
}