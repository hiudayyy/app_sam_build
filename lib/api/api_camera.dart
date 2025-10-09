import 'dart:convert';
import 'dart:io';
import 'package:csam_mobile/models/nhat_ky.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/camera.dart';
import '../models/kttoken.dart';
import '../models/login_model.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../models/vuontrong/caysam_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/losamcamera_model.dart';
import '../models/vuontrong/vuontrong_model.dart';
import '../services/local_service.dart';
import 'api.dart';

extension APIExtension on API {

  Future<CameraStreamResponse?> startStreamCamera(LoSamCameraModel camera) async {
    final linkURL = "${host}api/Camera/StartStreamCamera";
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
              (x) => x.tenController.toLowerCase() == "camera",
          orElse: () => FuncTagActive(
            tenController: "",
            tenActions: "",
            funcsTagActive: "",
          ),
        ).funcsTagActive ?? "",
        "Content-Type": "application/json",
      };

      final body = jsonEncode({
        "id": camera.id,
        "loSamId": camera.loSamId,
        "loSamLoaiCameraId": camera.loSamLoaiCameraId,
        "rtsp": camera.rtsp,
        "url": camera.url,
        "userName": camera.userName,
        "password": camera.password,
        "trangThai": camera.trangThai,
      });

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return CameraStreamResponse.fromJson(responseJson);
      } else {
        print("❌ Lỗi API: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Exception khi gọi API: $e");
      return null;
    }
  }



}