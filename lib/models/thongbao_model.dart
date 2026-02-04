

class ThongBaoModel {
  final int id;
  final String taiKhoanId;
  final String? caySamId;
  final String tieuDe;
  final String noiDung;
  final String ngayKhoiTao;
  final bool seen;
  final UserModel? htTaiKhoan; // Lồng UserModel vào đây

  const ThongBaoModel({
    required this.id,
    required this.taiKhoanId,
    this.caySamId,
    required this.tieuDe,
    required this.noiDung,
    required this.ngayKhoiTao,
    required this.seen,
    this.htTaiKhoan,
  });

  factory ThongBaoModel.fromJson(Map<String, dynamic> json) {
    return ThongBaoModel(
      id: json['id'] ?? 0,
      taiKhoanId: json['taiKhoanId'] ?? '',
      caySamId: json['caySamId'], // Có thể null
      tieuDe: json['tieuDe'] ?? '',
      noiDung: json['noiDung'] ?? '',
      ngayKhoiTao: json['ngayKhoiTao'] ?? '',
      seen: json['seen'] ?? false,
      htTaiKhoan: json['htTaiKhoan'] != null
          ? UserModel.fromJson(json['htTaiKhoan'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taiKhoanId': taiKhoanId,
      'caySamId': caySamId,
      'tieuDe': tieuDe,
      'noiDung': noiDung,
      'ngayKhoiTao': ngayKhoiTao,
      'seen': seen,
      'htTaiKhoan': htTaiKhoan?.toJson(),
    };
  }
}



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