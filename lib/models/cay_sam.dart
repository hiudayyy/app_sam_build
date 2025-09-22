import 'dart:ui';

import 'package:flutter/material.dart';

class CaySam {
  final String id;
  final String? nhatKyId;
  final String? moiTruongId;
  final String? xacThucId;
  final String? blockChain;
  final String? tenCay;
  final String? loaiCay;
  final String? ngayTrong;
  final TrangThaiCay? trangThai;
  final String? viTri;
  final String? gridPosition;
  final String? investorId;
  final String? areaId;

  CaySam({
    required this.id,
    this.nhatKyId,
    this.moiTruongId,
    this.xacThucId,
    this.blockChain,
    this.tenCay,
    this.loaiCay,
    this.ngayTrong,
    this.trangThai,
    this.viTri,
    this.gridPosition,
    this.investorId,
    this.areaId,
  });
  CaySam.empty()
      : id = '',
        nhatKyId = null,
        moiTruongId = null,
        xacThucId = null,
        blockChain = null,
        tenCay = null,
        loaiCay = null,
        ngayTrong = null,
        trangThai = null,
        viTri = null,
        gridPosition = null,
        investorId = null,
        areaId = null;
  factory CaySam.fromJson(Map<String, dynamic> json) {
    return CaySam(
      id: json['ID'],
      nhatKyId: json['NhatKy_ID'],
      moiTruongId: json['MoiTruong_ID'],
      xacThucId: json['XacThuc_ID'],
      blockChain: json['BlockChain'],
      tenCay: json['tenCay'],
      loaiCay: json['loaiCay'],
      ngayTrong: json['ngayTrong'],
      trangThai: _getTrangThaiFromString(json['trangThai']),
      viTri: json['viTri'],
      gridPosition: json['gridPosition'],
      investorId: json['investorId'],
      areaId: json['areaId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'NhatKy_ID': nhatKyId,
      'MoiTruong_ID': moiTruongId,
      'XacThuc_ID': xacThucId,
      'BlockChain': blockChain,
      'tenCay': tenCay,
      'loaiCay': loaiCay,
      'ngayTrong': ngayTrong,
      'trangThai': trangThai?.toString().split('.').last,
      'viTri': viTri,
      'gridPosition': gridPosition,
      'investorId': investorId,
      'areaId': areaId,
    };
  }

  static TrangThaiCay? _getTrangThaiFromString(String? status) {
    switch (status) {
      case 'khoe_manh':
        return TrangThaiCay.khoeMauh;
      case 'yeu':
        return TrangThaiCay.yeu;
      case 'benh':
        return TrangThaiCay.benh;
      case 'chet':
        return TrangThaiCay.chet;
      default:
        return null;
    }
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
        return Colors.yellow[700]!;
      case TrangThaiCay.benh:
        return Colors.orange;
      case TrangThaiCay.chet:
        return Colors.red;
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
        return Icons.cancel;
    }
  }
}