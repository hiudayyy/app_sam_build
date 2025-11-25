import 'package:nftsam/models/vuontrong/caysam_model.dart';

import 'cay_sam.dart';

class CaySamUserModel {
  final String caySamId;
  final String? userId;
  final DateTime? ngayCapNhat;
  final CaySam? caySam;

  CaySamUserModel({
    required this.caySamId,
    this.userId,
    this.ngayCapNhat,
    this.caySam,
  });

  factory CaySamUserModel.fromJson(Map<String, dynamic> json) {
    return CaySamUserModel(
      caySamId: json['caySamId'] ?? '',
      userId: json['userId'],
      ngayCapNhat: json['ngayCapNhat'] != null
          ? DateTime.tryParse(json['ngayCapNhat'])
          : null,
      caySam: json['caySam'] != null ? CaySam.fromJson(json['caySam']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caySamId': caySamId,
      'userId': userId,
      'ngayCapNhat': ngayCapNhat?.toIso8601String(),
      'caySam': caySam?.toJson(),
    };
  }
}

