class CaySamModel {
  final String caySamId;
  final int loSamId;
  final String? loSam;
  final String? viTriTrongLo;
  final String? blockChain;
  final String? maCaySam;
  final int? tuoiCayId;

  CaySamModel({
    required this.caySamId,
    required this.loSamId,
    this.loSam,
    this.viTriTrongLo,
    this.blockChain,
    this.maCaySam,
    this.tuoiCayId,
  });

  factory CaySamModel.fromJson(Map<String, dynamic> json) {
    return CaySamModel(
      caySamId: json['caySam_ID'] ?? '',
      loSamId: json['loSam_ID'] ?? 0,
      loSam: json['loSam'],
      viTriTrongLo: json['viTriTrongLo'] ?? '',
      blockChain: json['blockChain'],
      maCaySam: json['maCaySam'],
      tuoiCayId: json['tuoiCay_ID'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caySam_ID': caySamId,
      'loSam_ID': loSamId,
      'loSam': loSam,
      'viTriTrongLo': viTriTrongLo,
      'blockChain': blockChain,
      'maCaySam': maCaySam,
      'tuoiCay_ID': tuoiCayId,
    };
  }
}
