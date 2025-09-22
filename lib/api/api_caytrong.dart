import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kttoken.dart';
import '../models/login_model.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/vuontrong_model.dart';
import '../services/local_service.dart';
import 'api.dart';

extension APIExtension on API {

  Future<List<VuonTrongModel>?> listVuonTrong({
    int? status, // 1: Sử dụng, 2: Tạm ngưng, 3: Không sử dụng
    int? take,
    int? skip,
  }) async {
    String linkURL = "${host}api/VuonTrong/ListVuonTrong";
    final uri = Uri.parse(linkURL).replace(queryParameters: {
      if (status != null) 'Status': status.toString(),
      if (take != null) 'take': take.toString(),
      if (skip != null) 'skip': skip.toString(),
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
               (x) => x.tenController.toLowerCase() == "vuontrong",
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
        Map<String, dynamic> responseJson = jsonDecode(response.body);

        final data = ApiResponse<VuonTrongModel>.fromJson(
          responseJson,
              (json) => VuonTrongModel.fromJson(json),
        );
        print(data.items?.first.tenVuon);
        return data.items;
      } else {
        print("Lỗi API: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
  Future<List<LoSamModel>?> listLoSam({
    String? status,
    int? rowCount,
    int? skip,
    int? top,
    List<String>? orderBy,
    List<String>? searchBy,
  }) async {
    String linkURL = "${host}api/VuonTrong/ListLoSam";
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
              (x) => x.tenController.toLowerCase() == "vuontrong",
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

        final data = ApiResponse<LoSamModel>.fromJson(
          responseJson,
              (json) => LoSamModel.fromJson(json),
        );
        print(data.items?.first.tenLo);
        return data.items;
      } else {
        print("Lỗi API: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
  Future<ApiResponse<LoSamModel>?> addLoSam(
      LoSamModel loSam, {
        List<int>? fileBytes,
        String? fileName,
      }) async {
    String url = "${host}api/VuonTrong/AddLoSam";

    final bodyJson = {
      "LoSam": {
        "MaLo": loSam.maLo,
        "TenLo": loSam.tenLo,
        "SoHang": loSam.soHang,
        "SoCot": loSam.soCot,
        "DienTich": loSam.dienTich,
        "GhiChu": loSam.ghiChu,
        "Loai": loSam.loai,
        "TrangThai": loSam.trangThai,
        "VuonTrong_ID": loSam.vuonTrongId,
        "Ngay": loSam.ngay?.toIso8601String(),
      },
      "LoSamChiTiets":
      loSam.loSamChiTiets?.map((e) => e.toJson()).toList() ?? [],
      "LoSamCameras":
      loSam.loSamCameras?.map((e) => e.toJson()).toList() ?? [],
    };

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    Kttoken? user;
    if (userJson != null) {
      final Map<String, dynamic> json = jsonDecode(userJson);
      user = Kttoken.fromJson(json);
    }

    var request = http.MultipartRequest("POST", Uri.parse(url));

    request.headers.addAll({
      ...headerSvkt1,
      "AuthenticateToken": user?.authenticateToken ?? "",
      "FuncsTagActive": user?.funcsTagActives.firstWhere(
            (x) => x.tenController.toLowerCase() == "vuontrong",
        orElse: () => FuncTagActive(
          tenController: "",
          tenActions: "",
          funcsTagActive: "",
        ),
      ).funcsTagActive ??
          "",
    });

    request.fields['modelJson'] = jsonEncode(bodyJson);

    if (fileBytes != null && fileName != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonRes = jsonDecode(respStr);
      return ApiResponse<LoSamModel>.fromJson(
        jsonRes,
            (json) => LoSamModel.fromJson(json),
      );
    } else {
      print("Lỗi: ${response.statusCode} - $respStr");
      return null;
    }
  }

  Future<LoSamModel?> getLoSamById(int id) async {
    String linkURL = "${host}api/VuonTrong/GetLoSam/$id";
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
              (x) => x.tenController.toLowerCase() == "vuontrong",
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
        final data = ApiResponse<LoSamModel>.fromJson(
          responseJson,
              (json) => LoSamModel.fromJson(json),
        );
        return data.oneItem;
      } else {
        print("Lỗi API: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }

}