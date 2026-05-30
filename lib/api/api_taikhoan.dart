import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/kttoken.dart';
import '../models/response_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'api.dart';

import '/app_config.dart';

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
      "FuncsTagActive": user?.funcsTagActives
              .firstWhere(
                (x) => x.tenController.toLowerCase() == "taikhoan",
                orElse: () => FuncTagActive(
                  tenController: "",
                  tenActions: "",
                  funcsTagActive: "",
                ),
              )
              .funcsTagActive ??
          "",
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
    } else if (response.statusCode == 429) {
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
      AppConfig.printEx("❌ Lỗi: ${response.statusCode} - $response");
      return null;
    }
  }

  Future<ApiResponse<Kttoken>?> deleteTaiKhoan() async {
    final url = Uri.parse("${host}api/TaiKhoan/DeleteMyTaiKhoan");
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
      "FuncsTagActive": user?.funcsTagActives
              .firstWhere(
                (x) => x.tenController.toLowerCase() == "taikhoan",
                orElse: () => FuncTagActive(
                  tenController: "",
                  tenActions: "",
                  funcsTagActive: "",
                ),
              )
              .funcsTagActive ??
          "",
    };

    // 🔹 Gửi request POST (truyền body rỗng)
    final response =
        await http.post(url, headers: headers, body: jsonEncode({}));

    if (response.statusCode == 200) {
      final jsonRes = jsonDecode(response.body);
      final data = ApiResponse<Kttoken>.fromJson(
        jsonRes,
        (json) => Kttoken.fromJson(json),
      );

      // Đã bỏ hàm resetTokenAu ở đây, vì bên giao diện sau khi gọi xóa thành công sẽ chạy hàm logout()
      return data;
    } else if (response.statusCode == 429) {
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
      AppConfig.printEx("❌ Lỗi: ${response.statusCode} - $response");
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
      "FuncsTagActive": user?.funcsTagActives
              .firstWhere(
                (x) => x.tenController.toLowerCase() == "taikhoan",
                orElse: () => FuncTagActive(
                  tenController: "",
                  tenActions: "",
                  funcsTagActive: "",
                ),
              )
              .funcsTagActive ??
          "",
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
    } else if (response.statusCode == 429) {
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
      AppConfig.printEx("❌ Lỗi: ${response.statusCode} - $response");
      return null;
    }
  }

  Future<ApiResponse<Kttoken>?> ConectionWallet(
      {String? AddressWallet, bool isRetry = false}) async {
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
        "FuncsTagActive": user?.funcsTagActives
                .firstWhere(
                  (x) => x.tenController.toLowerCase() == "hethong",
                  orElse: () => FuncTagActive(
                    tenController: "",
                    tenActions: "",
                    funcsTagActive: "",
                  ),
                )
                .funcsTagActive ??
            "",
      };

      final response = await http.post(uri, headers: headers);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);

        final data = ApiResponse<Kttoken>.fromJson(
          responseJson,
          (json) => Kttoken.fromJson(json),
        );
        return data;
      } else if (response.statusCode == 429) {
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
      } else if (response.statusCode == 401) {
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
      } else {
        AppConfig.printEx(
            "Lỗi API ConectionWallet: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      AppConfig.printEx("Exception khi gọi API: $e");
      return null;
    }
  }
}
