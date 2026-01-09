import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard/dashboard_model.dart';
import '../models/kttoken.dart';
import '../models/response_model.dart';
import '../models/vuontrong/sensor_model.dart';
import '../services/auth_service.dart';
import 'api.dart';

extension APIExtension on API {
  Future<ApiResponse<DashBoardtotal>?> getDashBoardSam({bool isRetry = false}) async {
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
        "FuncsTagActive": user?.funcsTagActives.firstWhere(
              (x) => x.tenController.toLowerCase() == "dashboard",
          orElse: () => FuncTagActive(
            tenController: "",
            tenActions: "",
            funcsTagActive: "",
          ),
        ).funcsTagActive ?? "",
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return ApiResponse<DashBoardtotal>.fromJson(
          responseJson,
              (json) => DashBoardtotal.fromJson(json),
        );
      }else if (response.statusCode == 401) {
        if (!isRetry) {
          print("Gặp lỗi 401 -> Đang thử refresh token...");
          var newUser = await await AuthService.getStoredUser();
          if (newUser != null) {
            print("Refresh thành công -> Gọi lại API Dashboard lần 2.");
            return await getDashBoardSam(isRetry: true);
          } else {
            print("Refresh thất bại -> Đăng xuất.");
            return null;
          }
        } else {
          // Đã retry rồi mà vẫn 401 -> Token chết hẳn hoặc lỗi server
          print("Đã retry nhưng vẫn lỗi 401 -> Dừng.");
          return null;
        }
      }
      else {
        print("Lỗi API db: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
  Future<ApiResponse<DashBoardSucKhoe>?> getDashBoardSucKhoe({bool isRetry = false}) async {
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
        "FuncsTagActive": user?.funcsTagActives.firstWhere(
              (x) => x.tenController.toLowerCase() == "dashboard",
          orElse: () => FuncTagActive(
            tenController: "",
            tenActions: "",
            funcsTagActive: "",
          ),
        ).funcsTagActive ?? "",
      };

      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return ApiResponse<DashBoardSucKhoe>.fromJson(
          responseJson,
              (json) => DashBoardSucKhoe.fromJson(json),
        );
      }else if (response.statusCode == 401) {
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
      }
      else {
        print("Lỗi API: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
  Future<ApiResponse<SensorDeviceModel>?> getDashBoardSensor({bool isRetry = false}) async {
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
        "FuncsTagActive": user?.funcsTagActives.firstWhere(
              (x) => x.tenController.toLowerCase() == "dashboard",
          orElse: () => FuncTagActive(
            tenController: "",
            tenActions: "",
            funcsTagActive: "",
          ),
        ).funcsTagActive ?? "",
      };
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return ApiResponse<SensorDeviceModel>.fromJson(
          responseJson,
              (json) => SensorDeviceModel.fromJson(json),
        );
      }else if (response.statusCode == 401) {
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
      }
      else {
        print("Lỗi API db: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
}