import 'dart:convert';
import 'package:csam_mobile/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _userKey = 'ginseng_user';

  // Mock users data với 5 roles mới
  static final List<User> _mockUsers = [
    User(
      id: '1',
      username: 'admin',
      email: 'admin@ginsengfarm.com',
      fullName: 'Quản trị viên hệ thống',
      role: UserRole.nft_admin,
      permissions: User.rolePermissions[UserRole.nft_admin]!,
      avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
      lastLogin: '2024-01-15T08:30:00Z',
      isActive: true,
      createdAt: '2024-01-01T00:00:00Z',
    ),
    User(
      id: '2',
      username: 'investor',
      email: 'investor@ginsengfarm.com',
      fullName: 'Nguyễn Văn Đầu tư',
      role: UserRole.nhaDauTu,
      permissions: User.rolePermissions[UserRole.nhaDauTu]!,
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      lastLogin: '2024-01-15T09:15:00Z',
      isActive: true,
      createdAt: '2024-01-01T00:00:00Z',
    ),
    User(
      id: '3',
      username: 'admin_farm',
      email: 'admin.farm@ginsengfarm.com',
      fullName: 'Trần Thị Quản trị',
      role: UserRole.quanTri,
      permissions: User.rolePermissions[UserRole.quanTri]!,
      avatar: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
      lastLogin: '2024-01-15T07:45:00Z',
      isActive: true,
      createdAt: '2024-01-01T00:00:00Z',
    ),
    User(
      id: '4',
      username: 'inspector',
      email: 'inspector@ginsengfarm.com',
      fullName: 'Lê Văn Kiểm định',
      role: UserRole.nguoiKiemDinh,
      permissions: User.rolePermissions[UserRole.nguoiKiemDinh]!,
      avatar: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150&h=150&fit=crop&crop=face',
      lastLogin: '2024-01-14T16:20:00Z',
      isActive: true,
      createdAt: '2024-01-01T00:00:00Z',
    ),
    User(
      id: '5',
      username: 'worker',
      email: 'worker@ginsengfarm.com',
      fullName: 'Phạm Thị Làm vườn',
      role: UserRole.nguoiLamVuon,
      permissions: User.rolePermissions[UserRole.nguoiLamVuon]!,
      avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
      lastLogin: '2024-01-14T14:10:00Z',
      isActive: true,
      createdAt: '2024-01-01T00:00:00Z',
    ),
  ];

  // Login method
  static Future<User> login(LoginCredentials credentials) async {
    // Simulate API call delay
    await Future.delayed(Duration(seconds: 1));

    // Find user by username
    final user = _mockUsers.firstWhere(
          (u) => u.username == credentials.username,
      orElse: () => throw Exception('Tên đăng nhập không tồn tại'),
    );

    if (!user.isActive) {
      throw Exception('Tài khoản đã bị khóa');
    }

    // Simple password check (in real app, this would be hashed)
    if (credentials.password != 'password123') {
      throw Exception('Mật khẩu không chính xác');
    }

    // Update last login
    final updatedUser = User(
      id: user.id,
      username: user.username,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      permissions: user.permissions,
      avatar: user.avatar,
      lastLogin: DateTime.now().toIso8601String(),
      isActive: user.isActive,
      createdAt: user.createdAt,
    );

    // Store in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));

    return updatedUser;
  }

  // Logout method
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Get stored user
  static Future<User?> getStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      }
      return null;
    } catch (e) {
      // Clear corrupted data
      await logout();
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getStoredUser();
    return user != null && user.isActive;
  }

  // Check permission
  // static bool hasPermission(User? user, Permission permission) {
  //   return user?.permissions.contains(permission) ?? false;
  // }

  // Check role
  static bool hasRole(User? user, UserRole role) {
    return user?.role == role;
  }
  static bool hasRolemodel(UserModel? user, UserRole role) {
    return user?.oneItem?.htTaiKhoan.maVaiTros.any((x) => x.id == role) ?? false;
  }
}