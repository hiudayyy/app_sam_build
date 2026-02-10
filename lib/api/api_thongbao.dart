import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/kttoken.dart';
import '../models/response_model.dart';
import '../models/thongbao_model.dart';
import '../services/auth_service.dart';
import 'api.dart';

extension APIExtension on API {
  Future<ApiResponse<ThongBaoModel>?> listThongBao({
    String? status,
    int? rowCount,
    int? skip,
    int? top,
    List<String>? orderBy,
    List<String>? searchBy,
    bool isRetry = false
  }) async {
    String linkURL = "${host}api/ThongBao/ListThongBao";

    final uri = Uri.parse(linkURL).replace(queryParameters: {
      if (status != null) 'Status': status,
      if (rowCount != null) 'rowCount': rowCount.toString(),
      if (skip != null) 'Skip': skip.toString(),
      if (top != null) 'Top': top.toString(),
      if (orderBy != null && orderBy.isNotEmpty) 'OrderBy': orderBy,
      if (searchBy != null && searchBy.isNotEmpty) 'SearchBy': searchBy,
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
              (x) => x.tenController.toLowerCase() == "thongbao",
          orElse: () => FuncTagActive(
            tenController: "",
            tenActions: "",
            funcsTagActive: "",
          ),
        ).funcsTagActive ?? "",
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);
        final data = ApiResponse<ThongBaoModel>.fromJson(
          responseJson,
              (json) => ThongBaoModel.fromJson(json),
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
      }else if (response.statusCode == 401) {
        if (!isRetry) {
          var newUser = await await AuthService.getStoredUser();
          if (newUser != null) {
            return await listThongBao(isRetry: true);
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
      else {
        print("Lỗi API listThongBao: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API listThongBao: $e");
      return null;
    }
  }
  Future<bool> seenThongBao(int id) async {
    // ✅ Xây dựng URL với ID được truyền vào đường dẫn
    String linkURL = "${host}api/ThongBao/SeenThongBao/$id";
    final uri = Uri.parse(linkURL);

    try {
      // Giữ nguyên logic lấy thông tin user và token
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
              (x) => x.tenController.toLowerCase() == "thongbao",
          orElse: () => FuncTagActive(
            tenController: "",
            tenActions: "",
            funcsTagActive: "",
          ),
        ).funcsTagActive ?? "",
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return true;
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
        return false;
      }
      else {
        print("Lỗi API seenThongBao: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      // Xử lý lỗi kết nối hoặc các exception khác
      print("Exception khi gọi API seenThongBao: $e");
      return false;
    }
  }

  Future<ApiResponse<ThongBaoModel>?> seenThongBaoAll({bool isRetry = false}) async {
    String linkURL = "${host}api/ThongBao/SeenThongBaoAll";

    final uri = Uri.parse(linkURL);
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
              (x) => x.tenController.toLowerCase() == "thongbao",
          orElse: () => FuncTagActive(
            tenController: "",
            tenActions: "",
            funcsTagActive: "",
          ),
        ).funcsTagActive ?? "",
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);
        final data = ApiResponse<ThongBaoModel>.fromJson(
          responseJson,
              (json) => ThongBaoModel.fromJson(json),
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
      }else if (response.statusCode == 401) {
        if (!isRetry) {
          var newUser = await await AuthService.getStoredUser();
          if (newUser != null) {
            return await seenThongBaoAll(isRetry: true);
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
      else {
        print("Lỗi API Sennalltb: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API Seenalltb: $e");
      return null;
    }
  }
}