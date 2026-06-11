import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import '../models/baiviet/baiviet_model.dart';
import '../models/kttoken.dart';
import '../models/response_model.dart';
import 'api.dart';
extension APIExtension on API {
  Future<ApiResponse<BaiVietModel>?> listBaiViet({
    int? skip,
    int? top,
    List<String>? orderBy,
    List<String>? searchBy,
  }) async {
    // THAY ĐỔI ĐƯỜNG DẪN NÀY CHO KHỚP VỚI BACKEND CỦA BẠN
    String linkURL = "${host}api/Home/ListBaiViet";

    final uri = Uri.parse(linkURL).replace(queryParameters: {
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
        user = Kttoken.fromJson(jsonDecode(userJson));
      }

      final headers = {
        ...headerSvkt1,
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);

        // Parse JSON sang ApiResponse<BaiVietModel>
        final data = ApiResponse<BaiVietModel>.fromJson(
          responseJson,
              (json) => BaiVietModel.fromJson(json),
        );
        return data;
      } else {
        AppConfig.printEx("❌ Lỗi API Bài viết: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      AppConfig.printEx("❌ Exception khi gọi API Bài viết: $e");
      return null;
    }
  }
}
