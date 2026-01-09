import 'package:nftsam/models/nhat_ky.dart';

import 'caysamdinhkem_model.dart';

class CaySamModel {
  final String caySamId;
  final int loSamId;
  final String? loSam;
  final String? viTriTrongLo;
  final String? blockChain;
  final String? maCaySam;
  final int? tuoiCayId;
  final bool? isNFC;
  final List<CaySamNhatKy?> caySamNhatKys;
  final List<CaySamDinhKem?> caySam_DinhKems;

  CaySamModel({
    required this.caySamId,
    required this.loSamId,
    this.loSam,
    this.viTriTrongLo,
    this.blockChain,
    this.maCaySam,
    this.tuoiCayId,
    this.isNFC,
    required this.caySamNhatKys,
    required this.caySam_DinhKems,
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
      isNFC: json['isNFC'] ?? false,
      caySamNhatKys: (json['caySamNhatKys'] as List<dynamic>? ?? [])
          .where((e) => e != null)
          .map((e) => CaySamNhatKy.fromJson(e as Map<String, dynamic>))
          .toList(),
      caySam_DinhKems: (json['caySam_DinhKems'] as List<dynamic>? ?? [])
          .where((e) => e != null)
          .map((e) => CaySamDinhKem.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      'caySamNhatKys': caySamNhatKys,
      'isNFC' : isNFC
    };
  }
}
