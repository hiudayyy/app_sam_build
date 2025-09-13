import 'package:csam_mobile/models/user.dart';
import 'package:intl/intl.dart';

import 'message_enum.dart';

class UserModel {
  final String id;
  final String tenTaiKhoan;
  final String matKhau;
  final String ngayKhoiTao;
  final int trangThai;
  final String sdt;
  final String email;
  final List<VaiTro> maVaiTros;

  UserModel({
    required this.id,
    required this.tenTaiKhoan,
    required this.matKhau,
    required this.ngayKhoiTao,
    required this.trangThai,
    required this.sdt,
    required this.email,
    required this.maVaiTros,
  });


  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      tenTaiKhoan: json['tenTaiKhoan'] ?? '',
      matKhau: json['matKhau'] ?? '',
      ngayKhoiTao: json['ngayKhoiTao'] ?? '',
      trangThai: json['trangThai'] ?? 0,
      sdt: json['sdt'] ?? '',
      email: json['email'] ?? '',
      maVaiTros: (json['maVaiTros'] as List<dynamic>? ?? [])
          .map((e) => VaiTro.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenTaiKhoan': tenTaiKhoan,
      'matKhau': matKhau,
      'ngayKhoiTao': ngayKhoiTao,
      'trangThai': trangThai,
      'sdt': sdt,
      'email': email,
      'maVaiTros': maVaiTros.map((e) => e.toJson()).toList(),
    };
  }
  Map<String, dynamic> toJsondk() {
    return {
      "tenTaiKhoan": tenTaiKhoan,
      "matKhau": matKhau,
      "ngayKhoiTao": DateTime.now().toIso8601String(), // chuẩn ISO 8601
      "trangThai": trangThai,
      "sdt": sdt,
      "email": email,
    };
  }
}

class VaiTro {
  final String id;
  final String ten;
  final String? moTa;

  VaiTro({
    required this.id,
    required this.ten,
    this.moTa,
  });

  factory VaiTro.fromJson(Map<String, dynamic> json) {
    return VaiTro(
      id: json['id'] ?? '',
      ten: json['ten'] ?? '',
      moTa: json['moTa'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
      'moTa': moTa,
    };
  }
}

class RoleUtils {
  static UserRole? toUserRole(String id) {
    switch (id) {
      case "nft_admin":
        return UserRole.nft_admin;
      case "nhaDauTu":
        return UserRole.nhaDauTu;
      case "nft_garden":
        return UserRole.nft_garden;
      case "nguoiKiemDinh":
        return UserRole.nguoiKiemDinh;
      case "nft_user":
        return UserRole.nft_user;
      default:
        return null; // không map được
    }
  }
}