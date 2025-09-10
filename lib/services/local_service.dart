import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class LocalStoreService {

  static Future<void> setFromHost(String fromHost) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fromHost', fromHost);
  }

  static Future<String> getFromHost() async {
    final prefs = await SharedPreferences.getInstance();
    String? json = prefs.getString('fromHost');
    return json ?? "";
  }

  static Future<void> setUserModel(UserModel userModel) async {
    final prefs = await SharedPreferences.getInstance();
    String userModelJson = jsonEncode(userModel.toJson());
    await prefs.setString('userModel', userModelJson);
  }

  static Future<UserModel?> getUserModel() async {
    final prefs = await SharedPreferences.getInstance();
    String? userModelJson = prefs.getString('userModel');
    if (userModelJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userModelJson);
      return UserModel.fromJson(userMap);
    }
    return null;
  }

  static Future<void> removeUserModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userModel');
  }
}