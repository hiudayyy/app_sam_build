import 'dart:convert';
import 'package:nftsam/api/api_login.dart';
import 'package:nftsam/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../models/kttoken.dart';
import '../models/user.dart';

class AuthService {
  static const String _userKey = 'ginseng_user';
  final api = API();

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Get stored user
  static Future<UserModel?> getStoredUser() async {
    final api = API();
    try {
      final prefs = await SharedPreferences.getInstance();

      // Lấy chuỗi JSON đã lưu
      String? userJson = prefs.getString(_userKey);
      if (userJson == null) return null; // chưa login lần nào

      // Parse lại thành UserModel
      final Map<String, dynamic> json = jsonDecode(userJson);
      final user = Kttoken.fromJson(json);
      if(user.authenticateToken == ""){
        return null;
      }
      // Kiểm tra expiredAuthenticateToken
      final expiredStr = user.expiredAuthenticateToken;
      if (expiredStr.isNotEmpty) {
        final expired = parseCustomDate(expiredStr);

        if (expired != null) {
          if (DateTime.now().isBefore(expired)) {
            // Token còn hạn
            return user.htTaiKhoan;
          } else {
            // Token hết hạn -> xoá user khỏi prefs
            api.resetToken(user);
          }
        }
      }
      return user.htTaiKhoan;
    } catch (e) {
      // Clear corrupted data
      await logout();
      return null;
    }
  }

  // Check role
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