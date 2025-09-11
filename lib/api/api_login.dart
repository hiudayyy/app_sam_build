import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_model.dart';
import '../models/user_model.dart';
import '../services/local_service.dart';
import 'api.dart';

extension APIExtension on API {
  static const String _userKey = 'ginseng_user';
  Future<UserModel?> login(LoginModel model) async {
    String linkURL = "${host}api/Home/DangNhap";

    var body = jsonEncode(model.toJsonGet());
    final response = await http.post(
      Uri.parse(linkURL),
      headers: <String, String>{
        "accept":
        "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "accept-language": "en-US,en;q=0.9,vi;q=0.8",
        "cache-control": "max-age=0",
        "content-type": "application/json",
        "priority": "u=1, i",
        "sec-ch-ua":
        "\"Chromium\";v=\"128\", \"Not;A=Brand\";v=\"24\", \"Microsoft Edge\";v=\"128\"",
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-platform": "\"Windows\"",
        "sec-fetch-dest": "empty",
        "sec-fetch-mode": "cors",
        "sec-fetch-site": "cross-site",
        "upgrade-insecure-requests": "1",
        "referrer-policy": "strict-origin-when-cross-origin",
      },
      body: body,
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      UserModel? data = UserModel.fromJson(json);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(data.toJson()));
      if (data.messCode.index == 1) {
        await LocalStoreService.setUserModel(data);
      }
      return data;
    } else {
      print('Lỗi khi gọi API: ${response.statusCode} - $linkURL');
      return null;
    }
  }
  Future<UserModel?> resetToken(UserModel model) async {
    String linkURL = "${host}api/HeThong/RefreshToken";
    var body = jsonEncode(model.toJson());
    final response = await http.post(
      Uri.parse(linkURL),
      headers: <String, String>{
        "accept":
        "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "accept-language": "en-US,en;q=0.9,vi;q=0.8",
        "cache-control": "max-age=0",
        "content-type": "application/json",
        "priority": "u=1, i",
        "sec-ch-ua":
        "\"Chromium\";v=\"128\", \"Not;A=Brand\";v=\"24\", \"Microsoft Edge\";v=\"128\"",
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-platform": "\"Windows\"",
        "sec-fetch-dest": "empty",
        "sec-fetch-mode": "cors",
        "sec-fetch-site": "cross-site",
        "upgrade-insecure-requests": "1",
        "referrer-policy": "strict-origin-when-cross-origin",
        "authenticateToken": model.oneItem?.refreshToken ?? "",
      },
      body: body,
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      UserModel? data = UserModel.fromJson(json);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(data.toJson()));
      if (data.messCode.index == 1) {
        await LocalStoreService.setUserModel(data);
        return data;
      }
      return data;
    } else {
      print('Lỗi khi gọi API: ${response.statusCode} - $linkURL');
      return null;
    }
  }
}