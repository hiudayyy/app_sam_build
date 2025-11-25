import 'package:nftsam/models/user.dart';
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
  final List<htPhanQuyenTaiKhoan> htPhanQuyenTaiKhoans;

  UserModel({
    required this.id,
    required this.tenTaiKhoan,
    required this.matKhau,
    required this.ngayKhoiTao,
    required this.trangThai,
    required this.sdt,
    required this.email,
    required this.htPhanQuyenTaiKhoans,
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
      htPhanQuyenTaiKhoans: (json['htPhanQuyenTaiKhoans'] as List<dynamic>? ?? [])
          .map((e) => htPhanQuyenTaiKhoan.fromJson(e))
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
      'htPhanQuyenTaiKhoans': htPhanQuyenTaiKhoans.map((e) => e.toJson()).toList(),
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

class htPhanQuyenTaiKhoan {
  final String maTaiKhoan;
  final String? hT_TaiKhoan;
  final String maVaiTro;
  final String? hT_VaiTro;

  htPhanQuyenTaiKhoan({
    required this.maTaiKhoan,
    this.hT_TaiKhoan,
    required this.maVaiTro,
    this.hT_VaiTro,
  });

  factory htPhanQuyenTaiKhoan.fromJson(Map<String, dynamic> json) {
    return htPhanQuyenTaiKhoan(
      maTaiKhoan: json['maTaiKhoan'] ?? '',
      hT_TaiKhoan: json['hT_TaiKhoan'],
      maVaiTro: json['maVaiTro'] ?? '',
      hT_VaiTro: json['hT_VaiTro'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maTaiKhoan': maTaiKhoan,
      'hT_TaiKhoan': hT_TaiKhoan,
      'maVaiTro': maVaiTro,
      'hT_VaiTro':hT_VaiTro,
    };
  }
}

class RoleUtils {
  static UserRole? toUserRole(String id) {
    switch (id) {
      case "nft_admin":
        return UserRole.nft_admin;
      case "nft_invester":
        return UserRole.nft_invester;
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