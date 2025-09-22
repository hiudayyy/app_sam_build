class LoSamCameraModel {
  final int id;
  final int loSamId;
  final int loSamLoaiCameraId;
  final String rtsp;
  final String url;
  final int trangThai;
  final String? loSam;
  final LoSamLoaiCameraModel? loSamLoaiCamera;

  LoSamCameraModel({
    required this.id,
    required this.loSamId,
    required this.loSamLoaiCameraId,
    required this.rtsp,
    required this.url,
    required this.trangThai,
    this.loSam,
    this.loSamLoaiCamera,
  });

  factory LoSamCameraModel.fromJson(Map<String, dynamic> json) {
    return LoSamCameraModel(
      id: json['id'] ?? 0,
      loSamId: json['loSamId'] ?? 0,
      loSamLoaiCameraId: json['loSamLoaiCameraId'] ?? 0,
      rtsp: json['rtsp'] ?? '',
      url: json['url'] ?? '',
      trangThai: json['trangThai'] ?? 0,
      loSam: json['loSam'],
      loSamLoaiCamera: json['loSamLoaiCamera'] != null
          ? LoSamLoaiCameraModel.fromJson(json['loSamLoaiCamera'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loSamId': loSamId,
      'loSamLoaiCameraId': loSamLoaiCameraId,
      'rtsp': rtsp,
      'url': url,
      'trangThai': trangThai,
      'loSam': loSam,
      'loSamLoaiCamera': loSamLoaiCamera?.toJson(),
    };
  }
}

class LoSamLoaiCameraModel {
  final int id;
  final String ten;

  LoSamLoaiCameraModel({
    required this.id,
    required this.ten,
  });

  factory LoSamLoaiCameraModel.fromJson(Map<String, dynamic> json) {
    return LoSamLoaiCameraModel(
      id: json['id'] ?? 0,
      ten: json['ten'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
    };
  }
}
