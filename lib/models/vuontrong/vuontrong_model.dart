class VuonTrongModel {
  int vuonTrongId;
  String tenVuon;
  String diaChi;
  String viTri;
  String ghiChu;
  int trangThai;

  VuonTrongModel({
    required this.vuonTrongId,
    required this.tenVuon,
    required this.diaChi,
    required this.viTri,
    required this.ghiChu,
    required this.trangThai,
  });

  factory VuonTrongModel.fromJson(Map<String, dynamic> json) {
    return VuonTrongModel(
      vuonTrongId: json['vuonTrong_ID'] ?? 0,
      tenVuon: json['tenVuon'] ?? '',
      diaChi: json['diaChi'] ?? '',
      viTri: json['viTri'] ?? '',
      ghiChu: json['ghiChu'] ?? '',
      trangThai: json['trangThai'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vuonTrong_ID': vuonTrongId,
      'tenVuon': tenVuon,
      'diaChi': diaChi,
      'viTri': viTri,
      'ghiChu': ghiChu,
      'trangThai': trangThai,
    };
  }
}
