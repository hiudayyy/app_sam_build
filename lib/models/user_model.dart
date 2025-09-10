import 'package:csam_mobile/models/user.dart';
import 'package:intl/intl.dart';

import 'message_enum.dart';

class UserModel {
  final MessCode messCode;
  final String message;
  final OneItem? oneItem;

  UserModel({
    required this.messCode,
    required this.message,
    this.oneItem,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      messCode: MessCode.values[json['messCode']],
      message: json['message'] ?? '',
      oneItem: json['oneItem'] != null ? OneItem.fromJson(json['oneItem']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messCode': messCode.index,
      'message': message,
      'oneItem': oneItem?.toJson(),
    };
  }
}

class OneItem {
  final String authenticateToken;
  final List<FuncsTagActive> funcsTagActives;
  final HTTaiKhoan htTaiKhoan;

  OneItem({
    required this.authenticateToken,
    required this.funcsTagActives,
    required this.htTaiKhoan,
  });

  factory OneItem.fromJson(Map<String, dynamic> json) {
    return OneItem(
      authenticateToken: json['authenticateToken'] ?? '',
      funcsTagActives: (json['funcsTagActives'] as List<dynamic>? ?? [])
          .map((e) => FuncsTagActive.fromJson(e))
          .toList(),
      htTaiKhoan: HTTaiKhoan.fromJson(json['htTaiKhoan']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authenticateToken': authenticateToken,
      'funcsTagActives': funcsTagActives.map((e) => e.toJson()).toList(),
      'htTaiKhoan': htTaiKhoan.toJson(),
    };
  }
}

class FuncsTagActive {
  final String tenController;
  final String funcsTagActive;

  FuncsTagActive({
    required this.tenController,
    required this.funcsTagActive,
  });

  factory FuncsTagActive.fromJson(Map<String, dynamic> json) {
    return FuncsTagActive(
      tenController: json['tenController'] ?? '',
      funcsTagActive: json['funcsTagActive'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenController': tenController,
      'funcsTagActive': funcsTagActive,
    };
  }
}

class HTTaiKhoan {
  final String id;
  final String tenTaiKhoan;
  final List<VaiTro> maVaiTros;

  HTTaiKhoan({
    required this.id,
    required this.tenTaiKhoan,
    required this.maVaiTros,
  });

  factory HTTaiKhoan.fromJson(Map<String, dynamic> json) {
    return HTTaiKhoan(
      id: json['id'] ?? '',
      tenTaiKhoan: json['tenTaiKhoan'] ?? '',
      maVaiTros: (json['maVaiTros'] as List<dynamic>? ?? [])
          .map((e) => VaiTro.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenTaiKhoan': tenTaiKhoan,
      'maVaiTros': maVaiTros.map((e) => e.toJson()).toList(),
    };
  }
}

class VaiTro {
  final String id;
  final String ten;

  VaiTro({
    required this.id,
    required this.ten,
  });

  factory VaiTro.fromJson(Map<String, dynamic> json) {
    return VaiTro(
      id: json['id'] ?? '',
      ten: json['ten'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
    };
  }
}
class RoleUtils {
  static UserRole? toUserRole(String id) {
    switch (id) {
      case "admin":
        return UserRole.nft_admin;
      case "nhaDauTu":
        return UserRole.nhaDauTu;
      case "quanTri":
        return UserRole.quanTri;
      case "nguoiKiemDinh":
        return UserRole.nguoiKiemDinh;
      case "nguoiLamVuon":
        return UserRole.nguoiLamVuon;
      default:
        return null; // không map được
    }
  }
}