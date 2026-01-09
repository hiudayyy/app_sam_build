import 'cay_sam.dart';

class CaySamNhatKy {
  final int id;
  final String? caySamId;
  final String? taiKhoanId;
  final String? ngayGhi;
  final String? hinhAnhTongQuan;
  final String? hinhAnhChiTiet;
  final int soLa;
  final double? trongLuong;
  final int diemSucKhoe;
  final int tinhTrang; // giữ nguyên int
  final String? ghiChu;
  final List<caySamNhatKy_SensorReading>? caySamNhatKy_SensorReadings;

  CaySamNhatKy({
    required this.id,
    required this.caySamId,
    required this.taiKhoanId,
    required this.ngayGhi,
    required this.hinhAnhTongQuan,
    required this.hinhAnhChiTiet,
    required this.soLa,
    this.trongLuong,
    required this.diemSucKhoe,
    required this.tinhTrang,
    this.ghiChu,
    this.caySamNhatKy_SensorReadings
  });

  factory CaySamNhatKy.fromJson(Map<String, dynamic> json) {
    return CaySamNhatKy(
      id: json['id'] as int,
      caySamId: json['caySamId'] as String?,
      taiKhoanId: json['taiKhoanId'] as String?,
      ngayGhi: json['ngayGhi'] as String?,
      hinhAnhTongQuan: json['hinhAnhTongQuan'],
      hinhAnhChiTiet: json['hinhAnhChiTiet'],
      soLa: json['soLa'] as int,
      trongLuong: (json['trongLuong'] as num?)?.toDouble(),
      diemSucKhoe: json['diemSucKhoe'] as int,
      tinhTrang: json['tinhTrang'] as int,
      ghiChu: json['ghiChu'] as String?,
      caySamNhatKy_SensorReadings: (json['caySamNhatKy_SensorReadings'] as List<dynamic>? ?? [])
          .where((e) => e != null)
          .map((e) => caySamNhatKy_SensorReading.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'caySamId': caySamId,
    'taiKhoanId': taiKhoanId,
    'ngayGhi': ngayGhi,
    'hinhAnhTongQuan': hinhAnhTongQuan,
    'hinhAnhChiTiet': hinhAnhChiTiet,
    'soLa': soLa,
    'trongLuong': trongLuong,
    'diemSucKhoe': diemSucKhoe,
    'tinhTrang': tinhTrang,
    'ghiChu': ghiChu,
  };
}
