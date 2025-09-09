import 'package:flutter/material.dart';

class CaySam {
  final String id;
  final String? nhatKyId;
  final String? moiTruongId;
  final String? xacThucId;
  final String? blockChain;
  final String? tenCay;
  final String? loaiCay;
  final TrangThaiCay trangThai;
  final int tuoiCay;
  final String? viTri;
  final DateTime? ngayTrong;

  CaySam({
    required this.id,
    this.nhatKyId,
    this.moiTruongId,
    this.xacThucId,
    this.blockChain,
    this.tenCay,
    this.loaiCay,
    required this.trangThai,
    this.tuoiCay = 0,
    this.viTri,
    this.ngayTrong,
  });

  // Constructor for empty/placeholder CaySam
  CaySam.empty()
      : id = '',
        nhatKyId = null,
        moiTruongId = null,
        xacThucId = null,
        blockChain = null,
        tenCay = null,
        loaiCay = null,
        trangThai = TrangThaiCay.khoeMauh,
        tuoiCay = 0,
        viTri = null,
        ngayTrong = null;

  factory CaySam.fromJson(Map<String, dynamic> json) {
    return CaySam(
      id: json['ID'],
      nhatKyId: json['NhatKy_ID'],
      moiTruongId: json['MoiTruong_ID'],
      xacThucId: json['XacThuc_ID'],
      blockChain: json['BlockChain'],
      tenCay: json['TenCay'],
      loaiCay: json['LoaiCay'],
      trangThai: TrangThaiCay.values.firstWhere(
            (e) => e.name == json['TrangThai'],
        orElse: () => TrangThaiCay.khoeMauh,
      ),
      tuoiCay: json['TuoiCay'] ?? 0,
      viTri: json['ViTri'],
      ngayTrong: json['NgayTrong'] != null
          ? DateTime.tryParse(json['NgayTrong'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'NhatKy_ID': nhatKyId,
      'MoiTruong_ID': moiTruongId,
      'XacThuc_ID': xacThucId,
      'BlockChain': blockChain,
      'TenCay': tenCay,
      'LoaiCay': loaiCay,
      'TrangThai': trangThai.name,
      'TuoiCay': tuoiCay,
      'ViTri': viTri,
      'NgayTrong': ngayTrong?.toIso8601String(),
    };
  }
}

enum TrangThaiCay {
  khoeMauh,
  yeu,
  benh,
  chet,
}

extension TrangThaiCayExtension on TrangThaiCay {
  String get displayName {
    switch (this) {
      case TrangThaiCay.khoeMauh:
        return 'Khỏe mạnh';
      case TrangThaiCay.yeu:
        return 'Yếu';
      case TrangThaiCay.benh:
        return 'Bệnh';
      case TrangThaiCay.chet:
        return 'Chết';
    }
  }

  Color get color {
    switch (this) {
      case TrangThaiCay.khoeMauh:
        return Colors.green;
      case TrangThaiCay.yeu:
        return Colors.orange;
      case TrangThaiCay.benh:
        return Colors.red;
      case TrangThaiCay.chet:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case TrangThaiCay.khoeMauh:
        return Icons.check_circle;
      case TrangThaiCay.yeu:
        return Icons.warning;
      case TrangThaiCay.benh:
        return Icons.error;
      case TrangThaiCay.chet:
        return Icons.close;
    }
  }
}