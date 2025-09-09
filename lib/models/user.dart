enum UserRole { admin, nhaDauTu, quanTri, nguoiKiemDinh, nguoiLamVuon }

enum Permission {
  viewDashboard,
  managePlants,
  updateDiary,
  batchUpdateDiary,
  viewEnvironment,
  manageEnvironment,
  verifyQuality,
  manageUsers,
  viewReports,
  exportData
}

class User {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final UserRole role;
  final List<Permission> permissions;
  final String? avatar;
  final String? lastLogin;
  final bool isActive;
  final String createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.permissions,
    this.avatar,
    this.lastLogin,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['fullName'],
      role: UserRole.values.firstWhere(
            (e) => e.toString().split('.').last == json['role'],
      ),
      permissions: (json['permissions'] as List)
          .map((p) => Permission.values.firstWhere(
            (e) => e.toString().split('.').last == p,
      ))
          .toList(),
      avatar: json['avatar'],
      lastLogin: json['lastLogin'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role.toString().split('.').last,
      'permissions': permissions.map((p) => p.toString().split('.').last).toList(),
      'avatar': avatar,
      'lastLogin': lastLogin,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.nhaDauTu:
        return 'Nhà đầu tư';
      case UserRole.quanTri:
        return 'Quản trị';
      case UserRole.nguoiKiemDinh:
        return 'Người kiểm định';
      case UserRole.nguoiLamVuon:
        return 'Người làm vườn';
    }
  }

  String get roleDescription {
    switch (role) {
      case UserRole.admin:
        return 'Toàn quyền quản trị hệ thống';
      case UserRole.nhaDauTu:
        return 'Theo dõi đầu tư và quản lý cây trồng';
      case UserRole.quanTri:
        return 'Quản trị vườn và xác thực chất lượng';
      case UserRole.nguoiKiemDinh:
        return 'Kiểm định và xác thực chất lượng';
      case UserRole.nguoiLamVuon:
        return 'Chăm sóc và ghi nhật ký cây trồng';
    }
  }

  static const Map<UserRole, List<Permission>> rolePermissions = {
    UserRole.admin: [
      Permission.viewDashboard,
      Permission.managePlants,
      Permission.updateDiary,
      Permission.batchUpdateDiary,
      Permission.viewEnvironment,
      Permission.manageEnvironment,
      Permission.verifyQuality,
      Permission.manageUsers,
      Permission.viewReports,
      Permission.exportData,
    ],
    UserRole.nhaDauTu: [
      Permission.viewDashboard,
      Permission.managePlants,
      Permission.viewReports,
      Permission.exportData,
    ],
    UserRole.quanTri: [
      Permission.viewDashboard,
      Permission.managePlants,
      Permission.updateDiary,
      Permission.batchUpdateDiary,
      Permission.viewEnvironment,
      Permission.manageEnvironment,
      Permission.verifyQuality,
      Permission.viewReports,
      Permission.exportData,
    ],
    UserRole.nguoiKiemDinh: [
      Permission.viewDashboard,
      Permission.verifyQuality,
      Permission.viewEnvironment,
      Permission.updateDiary,
      Permission.viewReports,
    ],
    UserRole.nguoiLamVuon: [
      Permission.viewDashboard,
      Permission.managePlants,
      Permission.updateDiary,
      Permission.batchUpdateDiary,
      Permission.viewEnvironment,
    ],
  };
}

class LoginCredentials {
  final String username;
  final String password;

  LoginCredentials({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}