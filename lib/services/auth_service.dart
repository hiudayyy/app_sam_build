import 'dart:convert';
import 'package:nftsam/api/api_login.dart';
import 'package:nftsam/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../models/kttoken.dart';
import '../models/message_enum.dart';
import '../models/user.dart';

class AuthService {
  static const String _userKey = 'ginseng_user';
  final api = API();

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Get stored user
  // static Future<UserModel?> getStoredUser() async {
  //   final api = API();
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //
  //     // Lấy chuỗi JSON đã lưu
  //     String? userJson = prefs.getString(_userKey);
  //     if (userJson == null) return null; // chưa login lần nào
  //
  //     // Parse lại thành UserModel
  //     final Map<String, dynamic> json = jsonDecode(userJson);
  //     final user = Kttoken.fromJson(json);
  //     if(user.authenticateToken == ""){
  //       return null;
  //     }
  //     // Kiểm tra expiredAuthenticateToken
  //     final expiredStr = user.expiredAuthenticateToken;
  //     if (expiredStr.isNotEmpty) {
  //       final expired = parseCustomDate(expiredStr);
  //
  //       if (expired != null) {
  //         if (DateTime.now().isBefore(expired)) {
  //           // Token còn hạn
  //           return user.htTaiKhoan;
  //         } else {
  //           final newData = await api.resetToken(user); // Gọi hàm API bạn đã sửa
  //
  //           if (newData != null && newData.messCode == MessCode.IsOK) {
  //             // Refresh thành công -> Trả về User MỚI
  //             return newData.oneItem?.htTaiKhoan;
  //           } else {
  //             await prefs.remove(_userKey);
  //             await logout();
  //             return null;
  //           }
  //
  //         }
  //       }
  //     }
  //     return user.htTaiKhoan;
  //   } catch (e) {
  //     // Clear corrupted data
  //     await logout();
  //     return null;
  //   }
  // }

  // Check role
  static Future<UserModel?> getStoredUser() async {
    final api = API();
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString(_userKey);
      if (userJson == null) return null;
      final Map<String, dynamic> json = jsonDecode(userJson);
      final userWrapper = Kttoken.fromJson(json); // Đọc Kttoken từ cache
      if (userWrapper.authenticateToken.isEmpty) {
        await prefs.remove(_userKey);
        return null;
      }
      final expiredStr = userWrapper.expiredAuthenticateToken;
      if (expiredStr.isNotEmpty) {
        final expired = parseCustomDate(expiredStr); // Hàm date của bạn
        if (expired != null && DateTime.now().isAfter(expired)) {
          print("Token hết hạn, đang gọi API reset...");
          final newData = await api.resetToken(userWrapper);
          if (newData != null && newData.messCode == MessCode.IsOK) {
            final Kttoken? newKttoken = newData.oneItem;
            if (newKttoken != null) {
              String newUserJson = jsonEncode(newKttoken.toJson());
              await prefs.setString(_userKey, newUserJson);
              print("Làm mới token thành công.");
              return newKttoken.htTaiKhoan;
            }
          }
          print("Làm mới token thất bại -> Logout.");
          await prefs.remove(_userKey);
          return null;
        }
      }
      return userWrapper.htTaiKhoan;

    } catch (e) {
      print("Lỗi khi lấy user stored: $e");
      // Nếu lỗi format JSON hoặc lỗi khác thì xóa luôn cho sạch
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      return null;
    }
  }
  static bool hasRole(User? user, UserRole role) {
    return user?.role == role;
  }
  static bool hasRolemodel(Kttoken? user, UserRole role) {
    return user?.htTaiKhoan.htPhanQuyenTaiKhoans.any((x) => x.maVaiTro == role) ?? false;
  }
}

DateTime? parseCustomDate(String input) {
  if (input.length != 14) return null;
  return DateTime(
    int.parse(input.substring(0, 4)),   // yyyy
    int.parse(input.substring(4, 6)),   // MM
    int.parse(input.substring(6, 8)),   // dd
    int.parse(input.substring(8, 10)),  // HH
    int.parse(input.substring(10, 12)), // mm
    int.parse(input.substring(12, 14)), // ss
  );
}