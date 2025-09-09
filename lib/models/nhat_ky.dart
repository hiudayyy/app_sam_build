class CaySamNhatKy {
  final String nhatKyId;
  final String ngayGhi;
  final String? anhTongQuan;
  final int soLa;
  final TinhTrang tinhTrang;
  final int diemSucKhoe;
  final String maNguoiGhi;
  final String? ghiChu;

  CaySamNhatKy({
    required this.nhatKyId,
    required this.ngayGhi,
    this.anhTongQuan,
    required this.soLa,
    required this.tinhTrang,
    required this.diemSucKhoe,
    required this.maNguoiGhi,
    this.ghiChu,
  });

  factory CaySamNhatKy.fromJson(Map<String, dynamic> json) {
    return CaySamNhatKy(
      nhatKyId: json['nhatKyId'],
      ngayGhi: json['ngayGhi'],
      anhTongQuan: json['anhTongQuan'],
      soLa: json['soLa'],
      tinhTrang: TinhTrang.fromJson(json['tinhTrang']),
      diemSucKhoe: json['diemSucKhoe'],
      maNguoiGhi: json['maNguoiGhi'],
      ghiChu: json['ghiChu'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nhatKyId': nhatKyId,
      'ngayGhi': ngayGhi,
      'anhTongQuan': anhTongQuan,
      'soLa': soLa,
      'tinhTrang': tinhTrang.toJson(),
      'diemSucKhoe': diemSucKhoe,
      'maNguoiGhi': maNguoiGhi,
      'ghiChu': ghiChu,
    };
  }
}

class TinhTrang {
  final bool song;
  final bool nguDong;
  final bool chet;

  TinhTrang({
    required this.song,
    required this.nguDong,
    required this.chet,
  });

  factory TinhTrang.fromJson(Map<String, dynamic> json) {
    return TinhTrang(
      song: json['song'] ?? false,
      nguDong: json['nguDong'] ?? false,
      chet: json['chet'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'song': song,
      'nguDong': nguDong,
      'chet': chet,
    };
  }
}