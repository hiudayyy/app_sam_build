import 'dart:convert';
import 'dart:io';
import 'package:nftsam/models/nhat_ky.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kttoken.dart';
import '../models/login_model.dart';
import '../models/message_enum.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../models/vuontrong/caysam_model.dart';
import '../models/vuontrong/caysamdinhkem_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/vuontrong_model.dart';
import '../services/auth_service.dart';
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
  Future<List<CaySamNhatKy>> getNhatKysbyid(String id,{bool isRetry = false}) async {
    String linkURL = "${host}api/CaySam/GetNhatKyByCaySamId/$id";
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
              (x) => x.tenController.toLowerCase() == "caysam",
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
        final data = ApiResponse<CaySamNhatKy>.fromJson(
          responseJson,
              (json) => CaySamNhatKy.fromJson(json),
        );
        return data.items ?? []; // ✅ trả về list
      }else if (response.statusCode == 401) {
        if (!isRetry) {
          var newUser = await await AuthService.getStoredUser();
          if (newUser != null) {
            return await getNhatKysbyid(id,isRetry: true);
          } else {
            return [];
          }
        } else {
          return [];
        }
      }
      else {
        print("Lỗi API nk: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return [];
    }
  }

  Future<ApiResponse<CaySamModel>?> addNhatKy({
    required Map<String, dynamic> data, // modelJson
    required List<File?> files,          // BE yêu cầu đúng 2 ảnh
  }) async {
    final url = Uri.parse("${host}api/CaySam/AddNhatKyByCaySamId");
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
  Future<ApiResponse<String>?> updateLoSamChiTietByLoSamId({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse(
      "${host}api/VuonTrong/UpdateLoSamChiTietByLoSamId/$id"
          "?modelJson=${Uri.encodeComponent(jsonEncode(data))}",
    );

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
            (x) => x.tenController.toLowerCase() == "vuontrong",
        orElse: () => FuncTagActive(
          tenController: "",
          tenActions: "",
          funcsTagActive: "",
        ),
      ).funcsTagActive ?? "",
    };

    try {
      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        // API trả về JSON => parse thẳng về ApiResponse
        final respJson = jsonDecode(response.body);

        return ApiResponse<String>.fromJson(
          respJson,
              (json) => json.toString(), // vì API trả về text/plain hoặc string
        );
      } else {
        print("❌ Lỗi: ${response.statusCode} - ${response.body}");
        final respJson = jsonDecode(response.body);
        return ApiResponse<String>.fromJson(
          respJson,
              (json) => json.toString(),
        );
      }
    } catch (e) {
      print("❌ Exception: $e");
      return null;
    }
  }
  Future<ApiResponse<CaySamModel>?> ListCaySamRatYeu() async {
    final url = Uri.parse("${host}api/CaySam/ListCaySamRatYeu");

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
              (x) => x.tenController.toLowerCase() == "caysam",
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

        final data = ApiResponse<CaySamModel>.fromJson(
          responseJson,
              (json) => CaySamModel.fromJson(json),
        );

        print("✅ Tổng số cây yếu: ${data.items?.length ?? 0}");
        return data;
      } else {
        print("❌ Lỗi API: ${response.statusCode} - ${response.body}");
        return ApiResponse<CaySamModel>(
          messCode: MessCode.Unknown,
          typeRp: "error",
          message: "Lỗi khi gọi API",
          messageGoiY: response.body,
          items: [],
        );
      }
    } catch (e) {
      print("❌ Exception khi gọi API: $e");
      return ApiResponse<CaySamModel>(
        messCode: MessCode.Unknown,
        typeRp: "error",
        message: "Lỗi exception: $e",
        messageGoiY: "",
        items: [],
      );
    }
  }
  Future<ApiResponse<CaySamModel>?> listCaySam({
    String? status,
    int? rowCount,
    int? skip,
    int? top,
    List<String>? orderBy,
    List<String>? searchBy,
    bool isRetry = false
  }) async {
    String linkURL = "${host}api/CaySam/ListCaySam";
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
              (x) => x.tenController.toLowerCase() == "caysam",
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

        final data = ApiResponse<CaySamModel>.fromJson(
          responseJson,
              (json) => CaySamModel.fromJson(json),
        );
        return data;
      }else if (response.statusCode == 401) {
        if (!isRetry) {
          var newUser = await await AuthService.getStoredUser();
          if (newUser != null) {
            return await listCaySam(isRetry: true);
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
      else {
        print("Lỗi API cs: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception khi gọi API: $e");
      return null;
    }
  }
  Future<CaySamModel?> getCaySamById(String? id,{bool isRetry = false}) async {
    // ✅ THAY ĐỔI: Cập nhật endpoint API với ID được truyền vào
    String linkURL = "${host}api/CaySam/GetCaySamById/$id";
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

      // Giữ nguyên cấu trúc header, controller vẫn là "caysam"
      final headers = {
        ...headerSvkt1,
        "AuthenticateToken": user?.authenticateToken ?? "",
        "FuncsTagActive": user?.funcsTagActives
            .firstWhere(
              (x) => x.tenController.toLowerCase() == "caysam",
          orElse: () =>
              FuncTagActive(
                tenController: "",
                tenActions: "",
                funcsTagActive: "",
              ),
        )
            .funcsTagActive ?? "",
      };

      // Giữ nguyên logic gọi API
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {

        Map<String, dynamic> responseJson = jsonDecode(response.body);
        final data = ApiResponse<CaySamModel>.fromJson(
          responseJson,
              (json) => CaySamModel.fromJson(json),
        );
        if(data.messCode == MessCode.IsOK){
          return data.oneItem;
        }else{
          return null;
        }

      }else if (response.statusCode == 401) {
        if (!isRetry) {
          var newUser = await await AuthService.getStoredUser();
          if (newUser != null) {
            return await getCaySamById(id,isRetry: true);
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
      else {
        // Giữ nguyên logic xử lý lỗi
        print(
            "Lỗi API getCaySamById: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      // Giữ nguyên logic xử lý exception
      print("Exception khi gọi API getCaySamById: $e");
      return null;
    }
  }
  Future<ApiResponse<CaySamModel>?> updateNFCCaySam({
    required String id,
    required String serialNumber,                  // id cần chỉnh sửa
  }) async {
    final url = Uri.parse("${host}api/CaySam/UpdateNFCCaySam/${id}&${serialNumber}");
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
  Future<ApiResponse<CaySamModel>?> CheckNFCCaySam({
    required String serialNumber,                  // id cần chỉnh sửa
  }) async {
    final url = Uri.parse("${host}api/CaySam/CheckNFCCaySam/${serialNumber}");
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
  Future<ApiResponse<CaySamDinhKem>?> addDinhKemFileCaySam({
    required Map<String, dynamic> data,
    required File? file,
  }) async {
    final url = Uri.parse("${host}api/CaySam/AddDinhKemFileCaySam");
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");

    Kttoken? user;
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }

    var request = http.MultipartRequest("POST", url);

    // 1. Headers
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
    request.fields['modelJson'] = jsonEncode(data);
    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.path.split('/').last,
        ),
      );
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonRes = jsonDecode(respStr);
        return ApiResponse<CaySamDinhKem>.fromJson(
          jsonRes,
              (json) => CaySamDinhKem.fromJson(json),
        );
      } else {
        print("❌ Lỗi Server: ${response.statusCode} - $respStr");
        return null;
      }
    } catch (e) {
      print("❌ Lỗi kết nối: $e");
      return null;
    }
  }
}