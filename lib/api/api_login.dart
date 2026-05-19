import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
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
    }else if(response.statusCode == 429){
      Map<String, dynamic> errorJson = jsonDecode(response.body);
      return ApiResponse<Kttoken>(
        messCode: MessCode.Unknown,
        typeRp: "TooManyRequests",
        message: errorJson['Message'] ?? "Thao tác quá nhanh, vui lòng thử lại.",
        messageGoiY: "Vui lòng chờ giây lát",
        oneItem: null,
      );
    }
    else {
      return null;
    }
  }
  Future<ApiResponse<Kttoken>?> resetToken(Kttoken model) async {
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
      "AuthenticateToken": user?.refreshToken ?? "",
    };
    final response = await http.get(
      Uri.parse(linkURL),
      headers: headers,
    );
    print(response.statusCode);
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
    }else if (response.statusCode == 429) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Colors.orange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Thao tác quá nhanh",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),
                  Text(
                    "Bạn thao tác quá nhanh. Vui lòng thử lại sau 30 giây.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Đã hiểu",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return null;
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
    }else if (response.statusCode == 429) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Colors.orange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Thao tác quá nhanh",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),
                  Text(
                    "Bạn thao tác quá nhanh. Vui lòng thử lại sau 30 giây.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Đã hiểu",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return null;
    } else {
      return null;
    }
  }
  Future<Kttoken?> Logout(Kttoken model) async {
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
    }else if (response.statusCode == 429) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Colors.orange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Thao tác quá nhanh",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),
                  Text(
                    "Bạn thao tác quá nhanh. Vui lòng thử lại sau 30 giây.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Đã hiểu",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return null;
    } else {
      return null;
    }
  }
  Future<ApiResponse<Kttoken>?> googleLogin({required String idToken, required String deviceToken}) async {
    final url = Uri.parse('${host}api/Home/GoogleLogin');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "idToken": idToken,
          "deviceToken": deviceToken,
        }),
      );
      print(response.statusCode);


      if (response.statusCode == 200) {
        // Parse dữ liệu trả về
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
      }
      else if(response.statusCode == 429){
        Map<String, dynamic> errorJson = jsonDecode(response.body);
        return ApiResponse<Kttoken>(
          messCode: MessCode.Unknown,
          typeRp: "TooManyRequests",
          message: errorJson['Message'] ?? "Thao tác quá nhanh, vui lòng thử lại.",
          messageGoiY: "Vui lòng chờ giây lát",
          oneItem: null,
        );
      }
      else {
        print("Backend từ chối đăng nhập: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Lỗi gọi API server C#: $e");
      return null;
    }
  }
  // THÊM HÀM NÀY VÀO FILE api.dart
  Future<dynamic> appleLogin({
    required String identityToken,
    required String deviceToken,
    required String authorizationCode,
  }) async {
    try {
      final url = Uri.parse('${host}api/Home/AppleLogin');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json-patch+json",
          "accept": "*/*",
        },
        body: jsonEncode({
          "identityToken": identityToken,
          "deviceToken": deviceToken,
          "authorizationCode": authorizationCode,
        }),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("Apple Login Response: $data");
        return UserModel.fromJson(data); // <- Chỗ này bạn sửa lại tên Model cho khớp với code cũ của bạn nhé
      } else {
        print("Lỗi HTTP: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Lỗi gọi API Apple Login: $e");
      return null;
    }
  }

  // Hàm hỗ trợ kiểm tra xem đã login chưa (giống isLoggedIn() của JS)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt") != null;
  }

  // Hàm hỗ trợ logout (giống logout() của JS)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt");
  }
}