import 'message_enum.dart';

/// ---------------------------
/// ApiResponse generic
/// ---------------------------
class ApiResponse<T> {
  final MessCode messCode;
  final String typeRp;
  final String message;
  final String messageGoiY;
  final DataPage? dataPage;
  final List<T>? items;
  final List<OptionModelType>? lstOptionModelType;
  final T? oneItem;

  ApiResponse({
    required this.messCode,
    required this.typeRp,
    required this.message,
    required this.messageGoiY,
    this.dataPage,
    this.items,
    this.lstOptionModelType,
    this.oneItem,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    return ApiResponse<T>(
      messCode: messCodeFromInt(json['messCode'] ?? 0),
      typeRp: json['typeRp']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      messageGoiY: json['messageGoiY']?.toString() ?? '',
      dataPage: json['dataPage'] != null
          ? DataPage.fromJson(json['dataPage'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      lstOptionModelType: (json['lstOptionModelType'] as List<dynamic>?)
          ?.map((e) => OptionModelType.fromJson(e as Map<String, dynamic>))
          .toList(),
      oneItem: json['oneItem'] != null
          ? fromJsonT(json['oneItem'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson(
      Map<String, dynamic> Function(T) toJsonT,
      ) {
    return {
      "messCode": messCodeToString(messCode),
      "typeRp": typeRp,
      "message": message,
      "messageGoiY": messageGoiY,
      "dataPage": dataPage?.toJson(),
      "items": items?.map((e) => toJsonT(e)).toList(),
      "lstOptionModelType": lstOptionModelType?.map((e) => e.toJson()).toList(),
      "oneItem": oneItem != null ? toJsonT(oneItem as T) : null,
    };
  }
}

/// ---------------------------
/// Helpers cho MessCode
/// ---------------------------
MessCode messCodeFromInt(int value) {
  switch (value) {
    case 0:
      return MessCode.Unknown;
    case 1:
      return MessCode.IsOK;
    case 2:
      return MessCode.MissingInput;
    case 3:
      return MessCode.HashCode;
    case 4:
      return MessCode.ApiDateOut;
    case 5:
      return MessCode.ApiDateFalse;
    case 6:
      return MessCode.RefreshTokenExpired;
    case 7:
      return MessCode.AuthenticateNotMatchRefresh;
    case 8:
      return MessCode.LicenseExpired;
    default:
      return MessCode.Unknown;
  }
}

String messCodeToString(MessCode code) {
  switch (code) {
    case MessCode.IsOK:
      return "IsOK";
    case MessCode.MissingInput:
      return "MissingInput";
    case MessCode.HashCode:
      return "HashCode";
    case MessCode.ApiDateOut:
      return "ApiDateOut";
    case MessCode.ApiDateFalse:
      return "ApiDateFalse";
    case MessCode.RefreshTokenExpired:
      return "RefreshTokenExpired";
    case MessCode.AuthenticateNotMatchRefresh:
      return "AuthenticateNotMatchRefresh";
    case MessCode.LicenseExpired:
      return "LicenseExpired";
    default:
      return "Unknown";
  }
}

/// ---------------------------
/// DataPage
/// ---------------------------
class DataPage {
  final String tableName;
  final int rowCount;
  final int rowCountNoWhere;
  final int skip;
  final int top;
  final List<String> orderby;
  final String status;
  final List<String> searchby;
  final String datefm;

  DataPage({
    required this.tableName,
    required this.rowCount,
    required this.rowCountNoWhere,
    required this.skip,
    required this.top,
    required this.orderby,
    required this.status,
    required this.searchby,
    required this.datefm,
  });

  factory DataPage.fromJson(Map<String, dynamic> json) {
    return DataPage(
      tableName: json['tableName']?.toString() ?? '',
      rowCount: json['rowCount'] is int ? json['rowCount'] : int.tryParse(json['rowCount'].toString()) ?? 0,
      rowCountNoWhere: json['rowCountNoWhere'] is int ? json['rowCountNoWhere'] : int.tryParse(json['rowCountNoWhere'].toString()) ?? 0,
      skip: json['skip'] is int ? json['skip'] : int.tryParse(json['skip'].toString()) ?? 0,
      top: json['top'] is int ? json['top'] : int.tryParse(json['top'].toString()) ?? 0,
      orderby: (json['orderby'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      status: json['status']?.toString() ?? '',
      searchby: (json['searchby'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      datefm: json['datefm']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "tableName": tableName,
      "rowCount": rowCount,
      "rowCountNoWhere": rowCountNoWhere,
      "skip": skip,
      "top": top,
      "orderby": orderby,
      "status": status,
      "searchby": searchby,
      "datefm": datefm,
    };
  }
}

/// ---------------------------
/// OptionModelType
/// ---------------------------
class OptionModelType {
  final String catType;
  final int catVer;
  final String catFilter;
  final List<OptionItem> items;

  OptionModelType({
    required this.catType,
    required this.catVer,
    required this.catFilter,
    required this.items,
  });

  factory OptionModelType.fromJson(Map<String, dynamic> json) {
    return OptionModelType(
      catType: json['catType']?.toString() ?? '',
      catVer: json['catVer'] is int ? json['catVer'] : int.tryParse(json['catVer'].toString()) ?? 0,
      catFilter: json['catFilter']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "catType": catType,
      "catVer": catVer,
      "catFilter": catFilter,
      "items": items.map((e) => e.toJson()).toList(),
    };
  }
}

/// ---------------------------
/// OptionItem
/// ---------------------------
class OptionItem {
  final String text;
  final String value;

  OptionItem({
    required this.text,
    required this.value,
  });

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    return OptionItem(
      text: json['text']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "text": text,
      "value": value,
    };
  }
}
