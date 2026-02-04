import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/option_model.dart';
import '../models/response_model.dart';
import 'api.dart';

extension APIExtension on API {
  Future<List<OptionModel>?> OptionLoSamLoaiTuoi() async {
    String linkURL = "${host}api/Home/OptionLoSamLoaiTuoi";
    final uri = Uri.parse(linkURL);
    try {
      final response = await http.get(uri, headers: headerSvkt1);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);

        final data = ApiResponse<OptionModel>.fromJson(
          responseJson,
              (json) => OptionModel.fromJson(json),
        );

        return data.items;
      } else {
        print("Lỗi API option: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
  Future<List<OptionModel>?> OptionLoSamLoaiCamera() async {
    String linkURL = "${host}api/Home/OptionLoSamLoaiCamera";
    final uri = Uri.parse(linkURL);
    try {
      final response = await http.get(uri, headers: headerSvkt1);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);

        final data = ApiResponse<OptionModel>.fromJson(
          responseJson,
              (json) => OptionModel.fromJson(json),
        );

        return data.items;
      } else {
        print("Lỗi API option: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
  Future<List<OptionModel>?> OptionLoSamTinhTrang() async {
    String linkURL = "${host}api/Home/OptionCaySamTinhTrang";
    final uri = Uri.parse(linkURL);
    try {
      final response = await http.get(uri, headers: headerSvkt1);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);

        final data = ApiResponse<OptionModel>.fromJson(
          responseJson,
              (json) => OptionModel.fromJson(json),
        );

        return data.items;
      } else {
        print("Lỗi API option: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
  Future<List<OptionModel>?> OptionLoSamDiemSucKhoe() async {
    String linkURL = "${host}api/Home/OptionCaySamDiemSucKhoe";
    final uri = Uri.parse(linkURL);
    try {
      final response = await http.get(uri, headers: headerSvkt1);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);

        final data = ApiResponse<OptionModel>.fromJson(
          responseJson,
              (json) => OptionModel.fromJson(json),
        );

        return data.items;
      } else {
        print("Lỗi API dsk: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }

}