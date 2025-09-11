class ApiResponse<T> {
  final String messCode;
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
      messCode: json['messCode'] ?? "",
      typeRp: json['typeRp'] ?? "",
      message: json['message'] ?? "",
      messageGoiY: json['messageGoiY'] ?? "",
      dataPage: json['dataPage'] != null
          ? DataPage.fromJson(json['dataPage'])
          : null,
      items: json['items'] != null
          ? (json['items'] as List).map((e) => fromJsonT(e)).toList()
          : null,
      lstOptionModelType: json['lstOptionModelType'] != null
          ? (json['lstOptionModelType'] as List)
          .map((e) => OptionModelType.fromJson(e))
          .toList()
          : null,
      oneItem: json['oneItem'] != null ? fromJsonT(json['oneItem']) : null,
    );
  }
}
class DataPage {
  final String tableName;
  final int rowCount;
  final int rowCountNoWhere;
  final int skip;
  final int top;
  final List<String>? orderby;
  final String status;
  final List<String>? searchby;
  final String datefm;

  DataPage({
    required this.tableName,
    required this.rowCount,
    required this.rowCountNoWhere,
    required this.skip,
    required this.top,
    this.orderby,
    required this.status,
    this.searchby,
    required this.datefm,
  });

  factory DataPage.fromJson(Map<String, dynamic> json) {
    return DataPage(
      tableName: json['tableName'] ?? "",
      rowCount: json['rowCount'] ?? 0,
      rowCountNoWhere: json['rowCountNoWhere'] ?? 0,
      skip: json['skip'] ?? 0,
      top: json['top'] ?? 0,
      orderby: (json['orderby'] as List?)?.map((e) => e.toString()).toList(),
      status: json['status'] ?? "",
      searchby: (json['searchby'] as List?)?.map((e) => e.toString()).toList(),
      datefm: json['datefm'] ?? "",
    );
  }
}

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
      catType: json['catType'] ?? "",
      catVer: json['catVer'] ?? 0,
      catFilter: json['catFilter'] ?? "",
      items: (json['items'] as List)
          .map((e) => OptionItem.fromJson(e))
          .toList(),
    );
  }
}

class OptionItem {
  final String text;
  final String value;

  OptionItem({required this.text, required this.value});

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    return OptionItem(
      text: json['text'] ?? "",
      value: json['value'] ?? "",
    );
  }
}
