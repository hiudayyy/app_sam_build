import 'package:csam_mobile/models/vuontrong/sensor_model.dart';
import 'package:csam_mobile/models/vuontrong/vuontrong_model.dart';

import 'caysam_model.dart';
import 'losamcamera_model.dart';
import 'losamchitiet_model.dart';

class LoSamModel {
  final int loSamId;
  final int vuonTrongId;
  final String? tenLo;
  final String? maLo;
  final DateTime? ngay;
  final double dienTich;
  final String? loai;
  final String? ghiChu;
  final int soHang;
  final int soCot;
  final String? hinhAnh;
  final int trangThai;
  final int soLuongCaySams;
  final List<VuonTrongModel> vuonTrongs;
  final List<CaySamModel>? caySams;
  final List<LoSamChiTietModel>? loSamChiTiets;
  final List<LoSamCameraModel>? loSamCameras;
  final List<int>? sensorIds;
  final List<SensorModel>? sensorModels;

  LoSamModel({
    required this.loSamId,
    required this.vuonTrongId,
    this.tenLo,
    this.maLo,
    this.ngay,
    required this.dienTich,
    this.loai,
    this.ghiChu,
    required this.soHang,
    required this.soCot,
    this.hinhAnh,
    required this.trangThai,
    required this.soLuongCaySams,
    this.vuonTrongs = const [],
    this.caySams,
    this.loSamChiTiets,
    this.loSamCameras,
    this.sensorIds,
    this.sensorModels
  });

  factory LoSamModel.fromJson(Map<String, dynamic> json) {
    return LoSamModel(
      loSamId: json['loSam_ID'] ?? 0,
      vuonTrongId: json['vuonTrong_ID'] ?? 0,
      tenLo: json['tenLo'],
      maLo: json['maLo'],
      ngay: json['ngay'] != null ? DateTime.tryParse(json['ngay']) : null,
      dienTich: (json['dienTich'] ?? 0).toDouble(),
      loai: json['loai'],
      ghiChu: json['ghiChu'],
      soHang: json['soHang'] ?? 0,
      soCot: json['soCot'] ?? 0,
      hinhAnh: json['hinhAnh'],
      trangThai: json['trangThai'] ?? 0,
      soLuongCaySams: json['soLuongCaySams'] ?? 0,
      vuonTrongs: (json['vuonTrongs'] as List<dynamic>? ?? [])
          .map((e) => VuonTrongModel.fromJson(e))
          .toList(),
      caySams: (json['caySams'] as List<dynamic>? ?? [])
          .map((e) => CaySamModel.fromJson(e))
          .toList(),
      loSamChiTiets: (json['loSamChiTiets'] as List<dynamic>? ?? [])
          .map((e) => LoSamChiTietModel.fromJson(e))
          .toList(),
      loSamCameras: (json['loSamCameras'] as List<dynamic>? ?? [])
          .map((e) => LoSamCameraModel.fromJson(e))
          .toList(),
      sensorIds: (json['sensorIds'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList()
          ?? [],
      sensorModels:(json['sensorModels'] as List<dynamic>? ?? [])
            .map((e) => SensorModel.fromJson(e))
            .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loSam_ID': loSamId,
      'vuonTrong_ID': vuonTrongId,
      'tenLo': tenLo,
      'maLo': maLo,
      'ngay': ngay?.toIso8601String(),
      'dienTich': dienTich,
      'loai': loai,
      'ghiChu': ghiChu,
      'soHang': soHang,
      'soCot': soCot,
      'hinhAnh': hinhAnh,
      'trangThai': trangThai,
      'soLuongCaySams': soLuongCaySams,
      'vuonTrongs': vuonTrongs.map((e) => e.toJson()).toList(),
      'caySams': caySams?.map((e) => e.toJson()).toList(),
      'loSamChiTiets': loSamChiTiets?.map((e) => e.toJson()).toList(),
      'loSamCameras': loSamCameras?.map((e) => e.toJson()).toList(),
      'sensorModels': sensorModels?.map((e) => e.toJson()).toList(),
    };
  }
}
