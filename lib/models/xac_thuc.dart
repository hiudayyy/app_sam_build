import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CaySamXacThuc {
  final String xacThucId;
  final String caySamId;
  final String ngayKiemDinh;
  final LoaiKiemDinh loaiKiemDinh;
  final TrangThaiKiemDinh trangThaiKiemDinh;
  final String ketQuaKiemDinh;
  final double? diemChatLuong;
  final String nguoiKiemDinh;
  final String ngayCapNhat;
  final List<String>? taiLieuDinhKem;
  final List<KiemDinhHistory> lichSuKiemDinh;
  final String? ghiChu;

  CaySamXacThuc({
    required this.xacThucId,
    required this.caySamId,
    required this.ngayKiemDinh,
    required this.loaiKiemDinh,
    required this.trangThaiKiemDinh,
    required this.ketQuaKiemDinh,
    this.diemChatLuong,
    required this.nguoiKiemDinh,
    required this.ngayCapNhat,
    this.taiLieuDinhKem,
    required this.lichSuKiemDinh,
    this.ghiChu,
  });

  factory CaySamXacThuc.fromJson(Map<String, dynamic> json) {
    return CaySamXacThuc(
      xacThucId: json['xacThucId'],
      caySamId: json['caySamId'],
      ngayKiemDinh: json['ngayKiemDinh'],
      loaiKiemDinh: LoaiKiemDinh.values.firstWhere(
            (e) => e.name == json['loaiKiemDinh'],
        orElse: () => LoaiKiemDinh.chatLuong,
      ),
      trangThaiKiemDinh: TrangThaiKiemDinh.values.firstWhere(
            (e) => e.name == json['trangThaiKiemDinh'],
        orElse: () => TrangThaiKiemDinh.choKiemDinh,
      ),
      ketQuaKiemDinh: json['ketQuaKiemDinh'],
      diemChatLuong: json['diemChatLuong']?.toDouble(),
      nguoiKiemDinh: json['nguoiKiemDinh'],
      ngayCapNhat: json['ngayCapNhat'],
      taiLieuDinhKem: json['taiLieuDinhKem']?.cast<String>(),
      lichSuKiemDinh: (json['lichSuKiemDinh'] as List<dynamic>?)
          ?.map((e) => KiemDinhHistory.fromJson(e))
          .toList() ?? [],
      ghiChu: json['ghiChu'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'xacThucId': xacThucId,
      'caySamId': caySamId,
      'ngayKiemDinh': ngayKiemDinh,
      'loaiKiemDinh': loaiKiemDinh.name,
      'trangThaiKiemDinh': trangThaiKiemDinh.name,
      'ketQuaKiemDinh': ketQuaKiemDinh,
      'diemChatLuong': diemChatLuong,
      'nguoiKiemDinh': nguoiKiemDinh,
      'ngayCapNhat': ngayCapNhat,
      'taiLieuDinhKem': taiLieuDinhKem,
      'lichSuKiemDinh': lichSuKiemDinh.map((e) => e.toJson()).toList(),
      'ghiChu': ghiChu,
    };
  }
}

class KiemDinhHistory {
  final String ngayThayDoi;
  final String nguoiThayDoi;
  final String hanhDong;
  final String? ghiChu;

  KiemDinhHistory({
    required this.ngayThayDoi,
    required this.nguoiThayDoi,
    required this.hanhDong,
    this.ghiChu,
  });

  factory KiemDinhHistory.fromJson(Map<String, dynamic> json) {
    return KiemDinhHistory(
      ngayThayDoi: json['ngayThayDoi'],
      nguoiThayDoi: json['nguoiThayDoi'],
      hanhDong: json['hanhDong'],
      ghiChu: json['ghiChu'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ngayThayDoi': ngayThayDoi,
      'nguoiThayDoi': nguoiThayDoi,
      'hanhDong': hanhDong,
      'ghiChu': ghiChu,
    };
  }
}

enum LoaiKiemDinh {
  chatLuong,
  benhTat,
  sinhTruong,
}

extension LoaiKiemDinhExtension on LoaiKiemDinh {
  String get displayName {
    switch (this) {
      case LoaiKiemDinh.chatLuong:
        return 'Chất lượng';
      case LoaiKiemDinh.benhTat:
        return 'Bệnh tật';
      case LoaiKiemDinh.sinhTruong:
        return 'Sinh trưởng';
    }
  }
}

enum TrangThaiKiemDinh {
  choKiemDinh,
  dangKiemDinh,
  hoanThanh,
  huy,
}

extension TrangThaiKiemDinhExtension on TrangThaiKiemDinh {
  String get displayName {
    switch (this) {
      case TrangThaiKiemDinh.choKiemDinh:
        return 'Chờ kiểm định';
      case TrangThaiKiemDinh.dangKiemDinh:
        return 'Đang kiểm định';
      case TrangThaiKiemDinh.hoanThanh:
        return 'Hoàn thành';
      case TrangThaiKiemDinh.huy:
        return 'Hủy';
    }
  }
}

extension LoaiKiemDinhIconExtension on LoaiKiemDinh {
  IconData get icon {
    switch (this) {
      case LoaiKiemDinh.chatLuong:
        return Icons.star;
      case LoaiKiemDinh.benhTat:
        return Icons.local_hospital;
      case LoaiKiemDinh.sinhTruong:
        return Icons.trending_up;
    }
  }
}

extension TrangThaiKiemDinhColorExtension on TrangThaiKiemDinh {
  Color get color {
    switch (this) {
      case TrangThaiKiemDinh.choKiemDinh:
        return Colors.orange;
      case TrangThaiKiemDinh.dangKiemDinh:
        return Colors.blue;
      case TrangThaiKiemDinh.hoanThanh:
        return Colors.green;
      case TrangThaiKiemDinh.huy:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case TrangThaiKiemDinh.choKiemDinh:
        return Icons.schedule;
      case TrangThaiKiemDinh.dangKiemDinh:
        return Icons.pending;
      case TrangThaiKiemDinh.hoanThanh:
        return Icons.check_circle;
      case TrangThaiKiemDinh.huy:
        return Icons.cancel;
    }
  }
}

// Extension methods for CaySamXacThuc
extension CaySamXacThucExtension on CaySamXacThuc {
  Color getStatusColor() => trangThaiKiemDinh.color;
  IconData getStatusIcon() => trangThaiKiemDinh.icon;
  IconData getTypeIcon() => loaiKiemDinh.icon;
}