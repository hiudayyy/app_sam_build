import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kttoken.dart';
import '../models/response_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
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
       await AuthProvider().resetTokenAu(user!);
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
    final response = await http.post(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) {

      final jsonRes = jsonDecode(response.body);
      final data = ApiResponse<Kttoken>.fromJson(
        jsonRes,
            (json) => Kttoken.fromJson(json),
      );
      await AuthProvider().resetTokenAu(user!);
      return data;
    } else {
      print("❌ Lỗi: ${response.statusCode} - $response");
      return null;
    }
  }
  Future<ApiResponse<Kttoken>?> ConectionWallet({
    String? AddressWallet,
    bool isRetry = false
  }) async {
    String linkURL = "${host}api/HeThong/ConectionWallet";
    final uri = Uri.parse(linkURL).replace(queryParameters: {
      if (AddressWallet != null) 'AddressWallet': AddressWallet,
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString("ginseng_user");
      Kttoken? user;
      if (userJson != null) {
        final Map<String, dynamic> json = jsonDecode(userJson);
        user = Kttoken.fromJson(json);
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

      final response = await http.post(uri, headers: headers);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);

        final data = ApiResponse<Kttoken>.fromJson(
          responseJson,
              (json) => Kttoken.fromJson(json),
        );
        return data;
      }else if (response.statusCode == 401) {
        if (!isRetry) {
          var newUser = await await AuthService.getStoredUser();
          if (newUser != null) {
            return await ConectionWallet(isRetry: true);
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
      else {
        print("Lỗi API ConectionWallet: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
}