import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kttoken.dart';
import '../models/response_model.dart';
import '../models/thongbao_model.dart';
import 'api.dart';

extension APIExtension on API {
  Future<ApiResponse<ThongBaoModel>?> listThongBao({
    String? status,
    int? rowCount,
    int? skip,
    int? top,
    List<String>? orderBy,
    List<String>? searchBy,
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
      } else {
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
        print('Đã cập nhật trạng thái xem cho thông báo ID: $id');
        return true;
      } else {
        print("Lỗi API seenThongBao: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      // Xử lý lỗi kết nối hoặc các exception khác
      print("Exception khi gọi API seenThongBao: $e");
      return false;
    }
  }

  Future<ApiResponse<ThongBaoModel>?> seenThongBaoAll() async {
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
      } else {
        print("Lỗi API Sennalltb: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API Seenalltb: $e");
      return null;
    }
  }

}