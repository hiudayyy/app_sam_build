import 'package:csam_mobile/models/user_model.dart';

class Kttoken {
  final int messCode;
  final String message;
  final String authenticateToken;
  final List<FuncTagActive> funcsTagActives;
  final String expiredAuthenticateToken;
  final String refreshToken;
  final String expiredRefreshToken;
  final String service;
  final UserModel htTaiKhoan;
  final List<HtMenuModel> htMenuModels;

  Kttoken({
    required this.messCode,
    required this.message,
    required this.authenticateToken,
    required this.funcsTagActives,
    required this.expiredAuthenticateToken,
    required this.refreshToken,
    required this.expiredRefreshToken,
    required this.service,
    required this.htTaiKhoan,
    required this.htMenuModels,
  });

  factory Kttoken.fromJson(Map<String, dynamic> json) {
    return Kttoken(
      messCode: json['messCode'] ?? 0,
      message: json['message'] ?? '',
      authenticateToken: json['authenticateToken'] ?? '',
      funcsTagActives: (json['funcsTagActives'] as List<dynamic>? ?? [])
          .map((e) => FuncTagActive.fromJson(e))
          .toList(),
      expiredAuthenticateToken: json['expiredAuthenticateToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      expiredRefreshToken: json['expiredRefreshToken'] ?? '',
      service: json['service'] ?? '',
      htTaiKhoan: UserModel.fromJson(json['htTaiKhoan'] ?? {}),
      htMenuModels: (json['htMenuModels'] as List<dynamic>? ?? [])
          .map((e) => HtMenuModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "messCode": messCode,
      "message": message,
      "authenticateToken": authenticateToken,
      "funcsTagActives": funcsTagActives.map((e) => e.toJson()).toList(),
      "expiredAuthenticateToken": expiredAuthenticateToken,
      "refreshToken": refreshToken,
      "expiredRefreshToken": expiredRefreshToken,
      "service": service,
      "htTaiKhoan": htTaiKhoan.toJson(),
      "htMenuModels": htMenuModels.map((e) => e.toJson()).toList(),
    };
  }
}
class FuncTagActive {
  final String tenController;
  final String tenActions;
  final String funcsTagActive;

  FuncTagActive({
    required this.tenController,
    required this.tenActions,
    required this.funcsTagActive,
  });

  factory FuncTagActive.fromJson(Map<String, dynamic> json) {
    return FuncTagActive(
      tenController: json['tenController'] ?? '',
      tenActions: json['tenActions'] ?? '',
      funcsTagActive: json['funcsTagActive'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "tenController": tenController,
      "tenActions": tenActions,
      "funcsTagActive": funcsTagActive,
    };
  }
}
class HtMenuModel {
  final String id;
  final String? maMenuCha;
  final String ten;
  final String moTa;
  final String? tenAction;
  final String tenController;
  final String? tenArea;
  final String ngayKhoiTao;
  final String? icon;
  final int thuTu;
  final bool hienThi;
  final List<HtMenuModel> children;

  HtMenuModel({
    required this.id,
    required this.maMenuCha,
    required this.ten,
    required this.moTa,
    required this.tenAction,
    required this.tenController,
    required this.tenArea,
    required this.ngayKhoiTao,
    required this.icon,
    required this.thuTu,
    required this.hienThi,
    required this.children,
  });

  factory HtMenuModel.fromJson(Map<String, dynamic> json) {
    return HtMenuModel(
      id: json['id'] ?? '',
      maMenuCha: json['maMenuCha'],
      ten: json['ten'] ?? '',
      moTa: json['moTa'] ?? '',
      tenAction: json['tenAction'],
      tenController: json['tenController'] ?? '',
      tenArea: json['tenArea'],
      ngayKhoiTao: json['ngayKhoiTao'] ?? '',
      icon: json['icon'],
      thuTu: json['thuTu'] ?? 0,
      hienThi: json['hienThi'] ?? false,
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => HtMenuModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "maMenuCha": maMenuCha,
      "ten": ten,
      "moTa": moTa,
      "tenAction": tenAction,
      "tenController": tenController,
      "tenArea": tenArea,
      "ngayKhoiTao": ngayKhoiTao,
      "icon": icon,
      "thuTu": thuTu,
      "hienThi": hienThi,
      "children": children.map((e) => e.toJson()).toList(),
    };
  }
}