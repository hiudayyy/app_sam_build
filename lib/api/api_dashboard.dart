import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/dashboard/dashboard_model.dart';
import '../models/kttoken.dart';
import '../models/response_model.dart';
import '../models/vuontrong/sensor_model.dart';
import '../services/auth_service.dart';
import 'api.dart';

import '/app_config.dart';

extension APIExtension on API {
  Future<ApiResponse<DashBoardtotal>?> getDashBoardSam(
      {bool isRetry = false}) async {
    final uri = Uri.parse("${host}api/DashBoard/DashBoardSam");
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString("ginseng_user");
      Kttoken? user;
      if (userJson != null) {
        user = Kttoken.fromJson(jsonDecode(userJson));
      }
      final headers = {
        ...headerSvkt1,
        "AuthenticateToken": user?.authenticateToken ?? "",
        "FuncsTagActive": user?.funcsTagActives
                .firstWhere(
                  (x) => x.tenController.toLowerCase() == "dashboard",
                  orElse: () => FuncTagActive(
                    tenController: "",
                    tenActions: "",
                    funcsTagActive: "",
                  ),
                )
                .funcsTagActive ??
            "",
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return ApiResponse<DashBoardtotal>.fromJson(
          responseJson,
          (json) => DashBoardtotal.fromJson(json),
        );
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
          AppConfig.printEx("Gặp lỗi 401 -> Đang thử refresh token...");
          var newUser = await await AuthService.getStoredUser();
          if (newUser != null) {
            AppConfig.printEx(
                "Refresh thành công -> Gọi lại API Dashboard lần 2.");
            return await getDashBoardSam(isRetry: true);
          } else {
            AppConfig.printEx("Refresh thất bại -> Đăng xuất.");
            return null;
          }
        } else {
          // Đã retry rồi mà vẫn 401 -> Token chết hẳn hoặc lỗi server
          AppConfig.printEx("Đã retry nhưng vẫn lỗi 401 -> Dừng.");
          return null;
        }
      } else {
        AppConfig.printEx(
            "Lỗi API db: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      AppConfig.printEx("Exception khi gọi API: $e");
      return null;
    }
  }

  Future<ApiResponse<DashBoardSucKhoe>?> getDashBoardSucKhoe(
      {bool isRetry = false}) async {
    final uri = Uri.parse("${host}api/DashBoard/DashBoardSucKhoe");
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString("ginseng_user");
      Kttoken? user;
      if (userJson != null) {
        user = Kttoken.fromJson(jsonDecode(userJson));
      }
      final headers = {
        ...headerSvkt1,
        "AuthenticateToken": user?.authenticateToken ?? "",
        "FuncsTagActive": user?.funcsTagActives
                .firstWhere(
                  (x) => x.tenController.toLowerCase() == "dashboard",
                  orElse: () => FuncTagActive(
                    tenController: "",
                    tenActions: "",
                    funcsTagActive: "",
                  ),
                )
                .funcsTagActive ??
            "",
      };

      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return ApiResponse<DashBoardSucKhoe>.fromJson(
          responseJson,
          (json) => DashBoardSucKhoe.fromJson(json),
        );
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
            return await getDashBoardSucKhoe(isRetry: true);
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        AppConfig.printEx("Lỗi API: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      AppConfig.printEx("Exception khi gọi API: $e");
      return null;
    }
  }

  Future<ApiResponse<SensorDeviceModel>?> getDashBoardSensor(
      {bool isRetry = false}) async {
    final uri = Uri.parse("${host}api/DashBoard/DashBoardSensor");

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString("ginseng_user");
      Kttoken? user;
      if (userJson != null) {
        user = Kttoken.fromJson(jsonDecode(userJson));
      }
      final headers = {
        ...headerSvkt1,
        "AuthenticateToken": user?.authenticateToken ?? "",
        "FuncsTagActive": user?.funcsTagActives
                .firstWhere(
                  (x) => x.tenController.toLowerCase() == "dashboard",
                  orElse: () => FuncTagActive(
                    tenController: "",
                    tenActions: "",
                    funcsTagActive: "",
                  ),
                )
                .funcsTagActive ??
            "",
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return ApiResponse<SensorDeviceModel>.fromJson(
          responseJson,
          (json) => SensorDeviceModel.fromJson(json),
        );
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
            return await getDashBoardSensor(isRetry: true);
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        AppConfig.printEx(
            "Lỗi API db: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      AppConfig.printEx("Exception khi gọi API: $e");
      return null;
    }
  }
  Future<ApiResponse<DashBoardtotal>?> getDashBoardSamnew(
      {bool isRetry = false}) async {
    final uri = Uri.parse("${host}api/Home/DashBoardSam");
    try {
      final headers = {
        ...headerSvkt1
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return ApiResponse<DashBoardtotal>.fromJson(
          responseJson,
              (json) => DashBoardtotal.fromJson(json),
        );
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
          AppConfig.printEx("Gặp lỗi 401 -> Đang thử refresh token...");
          var newUser = await await AuthService.getStoredUser();
          if (newUser != null) {
            AppConfig.printEx(
                "Refresh thành công -> Gọi lại API Dashboard lần 2.");
            return await getDashBoardSam(isRetry: true);
          } else {
            AppConfig.printEx("Refresh thất bại -> Đăng xuất.");
            return null;
          }
        } else {
          // Đã retry rồi mà vẫn 401 -> Token chết hẳn hoặc lỗi server
          AppConfig.printEx("Đã retry nhưng vẫn lỗi 401 -> Dừng.");
          return null;
        }
      } else {
        AppConfig.printEx(
            "Lỗi API db: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      AppConfig.printEx("Exception khi gọi API: $e");
      return null;
    }
  }
}
