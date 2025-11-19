class LoSamCameraModel {
  final int id;
  final int loSamId;
  final int loSamLoaiCameraId;
  final String? ipCamera;
  final String rtsp;
  final String? onvifCamera;
  final String userName;
  final String password;
  final int trangThai;
  String? action;
  final String? loSam;
  final LoSamLoaiCameraModel? loSamLoaiCamera;

  LoSamCameraModel({
    required this.id,
    required this.loSamId,
    required this.loSamLoaiCameraId,
    this.ipCamera,
    required this.rtsp,
    this.onvifCamera,
    required this.userName,
    required this.password,
    required this.trangThai,
    this.action,
    this.loSam,
    this.loSamLoaiCamera,
  });

  factory LoSamCameraModel.fromJson(Map<String, dynamic> json) {
    return LoSamCameraModel(
      id: json['id'] ?? 0,
      loSamId: json['loSamId'] ?? 0,
      loSamLoaiCameraId: json['loSamLoaiCameraId'] ?? 0,
      ipCamera: json['ipCamera'] ?? "",
      rtsp: json['rtsp'] ?? '',
      onvifCamera: json['onvifCamera'],
      userName: json['userName'] ?? '',
      password: json['password'] ?? '',
      trangThai: json['trangThai'] ?? 0,
      action: json['action'] ?? "",
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
      'ipCamera':ipCamera,
      'rtsp': rtsp,
      'onvifCamera':onvifCamera,
      'userName': userName,
      'password' : password,
      'trangThai': trangThai,
      'action': action,
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
