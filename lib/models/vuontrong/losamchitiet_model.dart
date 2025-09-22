class LoSamChiTietModel {
  final int id;
  final int loSamId;
  final int loSamLoaiTuoiId;
  final int soLuong;
  final int trangThai;
  final String? loSam;
  final LoSamLoaiTuoiModel? loSamLoaiTuoi;

  LoSamChiTietModel({
    required this.id,
    required this.loSamId,
    required this.loSamLoaiTuoiId,
    required this.soLuong,
    required this.trangThai,
    this.loSam,
    this.loSamLoaiTuoi,
  });

  factory LoSamChiTietModel.fromJson(Map<String, dynamic> json) {
    return LoSamChiTietModel(
      id: json['id'] ?? 0,
      loSamId: json['loSamId'] ?? 0,
      loSamLoaiTuoiId: json['loSamLoaiTuoiId'] ?? 0,
      soLuong: json['soLuong'] ?? 0,
      trangThai: json['trangThai'] ?? 0,
      loSam: json['loSam'],
      loSamLoaiTuoi: json['loSamLoaiTuoi'] != null
          ? LoSamLoaiTuoiModel.fromJson(json['loSamLoaiTuoi'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loSamId': loSamId,
      'loSamLoaiTuoiId': loSamLoaiTuoiId,
      'soLuong': soLuong,
      'trangThai': trangThai,
      'loSam': loSam,
      'loSamLoaiTuoi': loSamLoaiTuoi?.toJson(),
    };
  }
}

class LoSamLoaiTuoiModel {
  final int id;
  final String tuoi;

  LoSamLoaiTuoiModel({
    required this.id,
    required this.tuoi,
  });

  factory LoSamLoaiTuoiModel.fromJson(Map<String, dynamic> json) {
    return LoSamLoaiTuoiModel(
      id: json['id'] ?? 0,
      tuoi: json['tuoi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tuoi': tuoi,
    };
  }
}
