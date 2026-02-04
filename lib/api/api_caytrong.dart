import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/caysamuser_model.dart';
import '../models/kttoken.dart';
import '../models/response_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/vuontrong_model.dart';
import '../services/auth_service.dart';
import 'api.dart';

extension APIExtension on API {

    Future<List<VuonTrongModel>?> listVuonTrong({
      int? status, // 1: Sử dụng, 2: Tạm ngưng, 3: Không sử dụng
      int? take,
      int? skip,bool isRetry = false
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
        }else if (response.statusCode == 401) {
          if (!isRetry) {
            var newUser = await await AuthService.getStoredUser();
            if (newUser != null) {
              return await listVuonTrong(isRetry: true);
            } else {
              return null;
            }
          } else {
            return null;
          }
        }
        else {
          print("Lỗi API vt: ${response.statusCode} - ${response.body}");
          return null;
        }
      } catch (e) {
        print("Exception khi gọi API: $e");
        return null;
      }
    }
    Future<ApiResponse<VuonTrongModel>?> addVuonTrong({
      required VuonTrongModel model,
    }) async {
      final url = Uri.parse("${host}api/VuonTrong/AddVuonTrong");

      try {
        // 🔹 Lấy thông tin user
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString("ginseng_user");
        Kttoken? user;
        if (userJson != null) {
          final Map<String, dynamic> json = jsonDecode(userJson);
          user = Kttoken.fromJson(json);
        }

        // 🔹 Header
        final headers = {
          ...headerSvkt1,
          "Content-Type": "application/json",
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

        // 🔹 Gửi request POST
        final response =
        await http.post(url, headers: headers, body: jsonEncode(model.toJson()));

        // 🔹 Xử lý kết quả
        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);
          final data = ApiResponse<VuonTrongModel>.fromJson(
            responseJson,
                (json) => VuonTrongModel.fromJson(json),
          );

          return data;
        } else {
          print("❌ Lỗi API: ${response.statusCode} - ${response.body}");
          return null;
        }
      } catch (e) {
        print("⚠️ Lỗi khi thêm vườn trồng: $e");
        return null;
      }
    }
    Future<ApiResponse<VuonTrongModel>?> editVuonTrong({
      required VuonTrongModel model,
    }) async {
      final url = Uri.parse("${host}api/VuonTrong/EditVuonTrong");

      try {
        // 🔹 Lấy thông tin user
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString("ginseng_user");
        Kttoken? user;
        if (userJson != null) {
          final Map<String, dynamic> json = jsonDecode(userJson);
          user = Kttoken.fromJson(json);
        }

        // 🔹 Header
        final headers = {
          ...headerSvkt1,
          "Content-Type": "application/json",
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

        // 🔹 Gửi request POST
        final response =
        await http.post(url, headers: headers, body: jsonEncode(model.toJson()));

        // 🔹 Xử lý kết quả
        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);

          // parse thẳng như listVuonTrong
          final data = ApiResponse<VuonTrongModel>.fromJson(
            responseJson,
                (json) => VuonTrongModel.fromJson(json),
          );

          return data;
        } else {
          print("❌ Lỗi API: ${response.statusCode} - ${response.body}");
          return null;
        }
      } catch (e) {
        print("⚠️ Lỗi khi Chỉnh sửa vườn trồng: $e");
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
        return data.items;
      } else {
        print("Lỗi API ls: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
    Future<ApiResponse<LoSamModel>?> addLoSam({
      required Map<String, dynamic> data,
      List<int>? fileBytes,
      String? fileName,
    }) async {
      final url = Uri.parse("${host}api/VuonTrong/AddLoSam");

      // 🔹 lấy token
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString("ginseng_user");
      Kttoken? user;
      if (userJson != null) {
        user = Kttoken.fromJson(jsonDecode(userJson));
      }

      // 🔹 multipart request
      var request = http.MultipartRequest("POST", url);
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
        ).funcsTagActive ?? "",
      });

      // 🔹 convert data sang JSON chuẩn
      request.fields['modelJson'] = jsonEncode(data);

      // 🔹 thêm file nếu có
      if (fileBytes != null && fileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
      }

      // 🔹 gửi request
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonRes = jsonDecode(respStr);
        return ApiResponse<LoSamModel>.fromJson(
          jsonRes,
              (json) => LoSamModel.fromJson(json),
        );
      } else {
        print("❌ Lỗi: ${response.statusCode} - $respStr");
        return null;
      }
    }
    Future<ApiResponse<LoSamModel>?> editLoSam({
      required int id,
      required Map<String, dynamic> data,
      List<int>? fileBytes,
      String? fileName,
    }) async {
      final url = Uri.parse("${host}api/VuonTrong/EditLoSam/$id");

      // 🔹 lấy token
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString("ginseng_user");
      Kttoken? user;
      if (userJson != null) {
        user = Kttoken.fromJson(jsonDecode(userJson));
      }

      // 🔹 multipart request
      var request = http.MultipartRequest("POST", url);
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
        ).funcsTagActive ?? "",
      });

      // 🔹 convert data sang JSON chuẩn
      request.fields['modelJson'] = jsonEncode(data);

      // 🔹 thêm file nếu có
      if (fileBytes != null && fileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
      }

      // 🔹 gửi request
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonRes = jsonDecode(respStr);
        return ApiResponse<LoSamModel>.fromJson(
          jsonRes,
              (json) => LoSamModel.fromJson(json),
        );
      } else {
        print("❌ Lỗi: ${response.statusCode} - $respStr");
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
        print("Lỗi API ls: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
    Future<ApiResponse<CaySamUserModel>?> getCaySamsByUser() async {
      final url = Uri.parse("${host}api/HeThong/GetCaySamsByUser");
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
                (x) => x.tenController.toLowerCase() == "hethong",
            orElse: () => FuncTagActive(
              tenController: "",
              tenActions: "",
              funcsTagActive: "",
            ),
          ).funcsTagActive ?? "",
        };

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);
          return ApiResponse<CaySamUserModel>.fromJson(
            responseJson,
                (json) => CaySamUserModel.fromJson(json),
          );
        } else {
          print("❌ Lỗi API: ${response.statusCode} - ${response.body}");
          return null;
        }
      } catch (e) {
        print("❌ Exception khi gọi API: $e");
        return null;
      }
    }
    Future<List<LoSamModel>?> listLoSamCanhBao({
      String? status,
      int? rowCount,
      int? skip,
      int? top,
      List<String>? orderBy,
      List<String>? searchBy,
    }) async {
      String linkURL = "${host}api/VuonTrong/ListLoSamCanhBao";
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
          return data.items;
        } else {
          print("Lỗi API cb: ${response.statusCode} - ${response.body}");
          return null;
        }
      } catch (e) {
        print("Exception khi gọi API: $e");
        return null;
      }
    }

}