import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/caysamuser_model.dart';
import '../models/dashboard/dashboard_model.dart';
import '../models/kttoken.dart';
import '../models/login_model.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/sensor_model.dart';
import '../models/vuontrong/vuontrong_model.dart';
import '../services/local_service.dart';
import 'api.dart';

extension APIExtension on API {

  Future<ApiResponse<DashBoardtotal>?> getDashBoardSam() async {
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
      } else {
        print("Lỗi API db: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
  Future<ApiResponse<DashBoardSucKhoe>?> getDashBoardSucKhoe() async {
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
      } else {
        print("Lỗi API: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
  Future<ApiResponse<SensorDeviceModel>?> getDashBoardSensor() async {
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
      } else {
        print("Lỗi API db: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
}