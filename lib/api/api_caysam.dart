import 'dart:convert';
import 'dart:io';
import 'package:csam_mobile/models/nhat_ky.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kttoken.dart';
import '../models/login_model.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../models/vuontrong/caysam_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/vuontrong_model.dart';
import '../services/local_service.dart';
import 'api.dart';

extension APIExtension on API {

  Future<ApiResponse<CaySamModel>?> addCaySam({
    required Map<String, dynamic> data, // modelJson
    required List<File?> files,          // BE yêu cầu đúng 2 ảnh
  }) async {
    final url = Uri.parse("${host}api/CaySam/AddCaySam");
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    Kttoken? user;
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
    var request = http.MultipartRequest("POST", url);
    request.headers.addAll({
      ...headerSvkt1,
      "AuthenticateToken": user?.authenticateToken ?? "",
      "FuncsTagActive": user?.funcsTagActives.firstWhere(
            (x) => x.tenController.toLowerCase() == "caysam",
        orElse: () => FuncTagActive(
          tenController: "",
          tenActions: "",
          funcsTagActive: "",
        ),
      ).funcsTagActive ?? "",
    });
    print(jsonEncode(data));
    request.fields['modelJson'] = jsonEncode(data);
    for (var file in files) {
      if(file != null){
        final fileBytes = await file.readAsBytes();
        final fileName = file.path.split('/').last;
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            fileBytes,
            filename: fileName,
          ),
        );
      }else{
        print("❌ Lỗi: ảnh");
      }
    }
    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 200) {

      final jsonRes = jsonDecode(respStr);
      return ApiResponse<CaySamModel>.fromJson(
        jsonRes,
            (json) => CaySamModel.fromJson(json),
      );

    } else {
      print("❌ Lỗi: ${response.statusCode} - $respStr");
      return null;
    }
  }
  Future<ApiResponse<CaySamModel>?> editCaySam({
    required String id,                  // id cần chỉnh sửa
    required Map<String, dynamic> data,   // modelJson
    required List<File?> files,           // tối đa 2 ảnh (hoặc tùy BE)
  }) async {
    final url = Uri.parse("${host}api/CaySam/EditCaySam/${id}");
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    Kttoken? user;
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }

    var request = http.MultipartRequest("POST", url);
    request.headers.addAll({
      ...headerSvkt1,
      "AuthenticateToken": user?.authenticateToken ?? "",
      "FuncsTagActive": user?.funcsTagActives.firstWhere(
            (x) => x.tenController.toLowerCase() == "caysam",
        orElse: () => FuncTagActive(
          tenController: "",
          tenActions: "",
          funcsTagActive: "",
        ),
      ).funcsTagActive ?? "",
    });
    print(jsonEncode(data));
    // body dạng multipart/form-data
    request.fields['modelJson'] = jsonEncode(data);

    // thêm danh sách file
    for (var file in files) {
      if (file != null) {
        final fileBytes = await file.readAsBytes();
        final fileName = file.path.split('/').last;
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            fileBytes,
            filename: fileName,
          ),
        );
      } else {
        print("❌ Lỗi: ảnh null");
      }
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonRes = jsonDecode(respStr);
      return ApiResponse<CaySamModel>.fromJson(
        jsonRes,
            (json) => CaySamModel.fromJson(json),
      );
    } else {
      print("❌ Lỗi: ${response.statusCode} - $respStr");
      return null;
    }
  }
  Future<ApiResponse<CaySamNhatKy>?> addNhatKys({
    required Map<String, dynamic> data, // modelJson
    required List<File?> files,          // BE yêu cầu đúng 2 ảnh
  }) async {
    final url = Uri.parse("${host}api/CaySam/AddNhatKyByCaySamIds");
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    Kttoken? user;
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
    var request = http.MultipartRequest("POST", url);
    request.headers.addAll({
      ...headerSvkt1,
      "AuthenticateToken": user?.authenticateToken ?? "",
      "FuncsTagActive": user?.funcsTagActives.firstWhere(
            (x) => x.tenController.toLowerCase() == "caysam",
        orElse: () => FuncTagActive(
          tenController: "",
          tenActions: "",
          funcsTagActive: "",
        ),
      ).funcsTagActive ?? "",
    });
    print(jsonEncode(data));
    request.fields['modelJson'] = jsonEncode(data);
    for (var file in files) {
      if(file != null){
        final fileBytes = await file.readAsBytes();
        final fileName = file.path.split('/').last;
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            fileBytes,
            filename: fileName,
          ),
        );
      }else{
        print("❌ Lỗi: ảnh");
      }
    }
    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 200) {

      final jsonRes = jsonDecode(respStr);
      return ApiResponse<CaySamNhatKy>.fromJsonNoModel(
        jsonRes
      );

    } else {
      print("❌ Lỗi: ${response.statusCode} - $respStr");
      return null;
    }
  }


}