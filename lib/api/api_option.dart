import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
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
      }else if (response.statusCode == 429) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Thao tác quá nhanh",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),
                    Text(
                      "Bạn thao tác quá nhanh. Vui lòng thử lại sau 30 giây.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Đã hiểu",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return null;
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
      }else if (response.statusCode == 429) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Thao tác quá nhanh",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),
                    Text(
                      "Bạn thao tác quá nhanh. Vui lòng thử lại sau 30 giây.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Đã hiểu",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return null;
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
      }else if (response.statusCode == 429) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Thao tác quá nhanh",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),
                    Text(
                      "Bạn thao tác quá nhanh. Vui lòng thử lại sau 30 giây.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Đã hiểu",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return null;
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
      }else if (response.statusCode == 429) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Thao tác quá nhanh",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),
                    Text(
                      "Bạn thao tác quá nhanh. Vui lòng thử lại sau 30 giây.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Đã hiểu",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return null;
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