class CaySamDinhKem {
  final int idFile;
  final String caySamId;
  final String idTaiKhoan;
  final String dinhKemFile;
  final DateTime? thoiGian;
  final bool trangThai;

  CaySamDinhKem({
    required this.idFile,
    required this.caySamId,
    required this.idTaiKhoan,
    required this.dinhKemFile,
    this.thoiGian,
    required this.trangThai,
  });

  factory CaySamDinhKem.fromJson(Map<String, dynamic> json) {
    return CaySamDinhKem(
      idFile: json['idFile'] ?? 0, // Hoặc json['IdFile'] tùy API trả về
      caySamId: json['caySam_ID'] ?? '', // Mapping theo property C# CaySam_ID
      idTaiKhoan: json['idTaiKhoan'] ?? '',
      dinhKemFile: json['dinhKemFile'] ?? '',
      thoiGian: json['thoiGian'] != null
          ? DateTime.tryParse(json['thoiGian'])
          : null,
      trangThai: json['trangThai'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idFile': idFile,
      'caySam_ID': caySamId,
      'idTaiKhoan': idTaiKhoan,
      'dinhKemFile': dinhKemFile,
      'thoiGian': thoiGian?.toIso8601String(),
      'trangThai': trangThai,
    };
  }
}