class SensorModel {
  int sensorId;
  String sensorCode;
  String jValue;
  String unit;
  int minValueSS;
  int maxValueSS;



  SensorModel({
    required this.sensorId,
    required this.sensorCode,
    required this.jValue,
    required this.unit,
    required this.minValueSS,
    required this.maxValueSS
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      sensorId: json['sensorId'] ?? 0,
      sensorCode: json['sensorCode'] ?? '',
      jValue: json['jValue'] ?? '',
      unit: json['unit'] ?? '',
      minValueSS: json['minValueSS'] ?? 0,
      maxValueSS: json['maxValueSS'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sensorId': sensorId,
      'sensorCode': sensorCode,
      'jValue': jValue,
      'unit': unit,
      'minValueSS': minValueSS,
      'maxValueSS':maxValueSS
    };
  }
}
class SensorDeviceModel {
  int deviceId;
  String? deviceCode;
  String? deviceName;
  List<SensorModel>? sensors;
  String? updateTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SensorDeviceModel &&
              runtimeType == other.runtimeType &&
              deviceId == other.deviceId; // So sánh bằng deviceId

  @override
  int get hashCode => deviceId.hashCode;
  SensorDeviceModel({
    required this.deviceId,
    this.deviceCode,
    this.deviceName,
    this.sensors,
    this.updateTime,
  });

  factory SensorDeviceModel.fromJson(Map<String, dynamic> json) {
    return SensorDeviceModel(
      deviceId: json['deviceId'] ?? 0,
      deviceCode: json['deviceCode'] ?? '',
      deviceName: json['deviceName'] ?? '',
      sensors: (json['sensors'] as List<dynamic>? ?? [])
          .where((e) => e != null)
          .map((e) => SensorModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      updateTime: json['updateTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceCode': deviceCode,
      'deviceName': deviceName,
      'sensors': sensors,

    };
  }
}
