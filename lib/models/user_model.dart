import 'package:nftsam/models/user.dart';


class UserModel {
  final String id;
  final String tenTaiKhoan;
  final String matKhau;
  final String ngayKhoiTao;
  final int trangThai;
  final String sdt;
  final String email;
  final List<htPhanQuyenTaiKhoan> htPhanQuyenTaiKhoans;
  final WalletUser? wallet;

  UserModel({
    required this.id,
    required this.tenTaiKhoan,
    required this.matKhau,
    required this.ngayKhoiTao,
    required this.trangThai,
    required this.sdt,
    required this.email,
    required this.htPhanQuyenTaiKhoans,
    this.wallet
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
      wallet: json['wallet'] != null ? WalletUser.fromJson(json['wallet']) : null,
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
      'wallet' : wallet
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
class WalletUser {
  final String? userId;
  final String? diaChiVi;
  final String? ngayCapNhat;
  final String? htTaiKhoan;

  WalletUser({
    this.userId,
    this.diaChiVi,
    this.ngayCapNhat,
    this.htTaiKhoan,
  });

  factory WalletUser.fromJson(Map<String, dynamic> json) {
    return WalletUser(
      userId: json['userId'] ?? '',
      diaChiVi: json['diaChiVi'],
      ngayCapNhat: json['ngayCapNhat'] ?? '',
      htTaiKhoan: json['htTaiKhoan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'diaChiVi': diaChiVi,
      'ngayCapNhat': ngayCapNhat,
      'htTaiKhoan':htTaiKhoan,
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