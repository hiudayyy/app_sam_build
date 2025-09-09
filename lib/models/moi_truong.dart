class CaySamMoiTruong {
  final String moiTruongId;
  final String ngayDo;
  final double doAmDat;
  final double nhietDo;
  final double doAmKhongKhi;
  final double luongMua;
  final String? ghiChu;

  CaySamMoiTruong({
    required this.moiTruongId,
    required this.ngayDo,
    required this.doAmDat,
    required this.nhietDo,
    required this.doAmKhongKhi,
    required this.luongMua,
    this.ghiChu,
  });

  factory CaySamMoiTruong.fromJson(Map<String, dynamic> json) {
    return CaySamMoiTruong(
      moiTruongId: json['moiTruongId'],
      ngayDo: json['ngayDo'],
      doAmDat: (json['doAmDat'] as num).toDouble(),
      nhietDo: (json['nhietDo'] as num).toDouble(),
      doAmKhongKhi: (json['doAmKhongKhi'] as num).toDouble(),
      luongMua: (json['luongMua'] as num).toDouble(),
      ghiChu: json['ghiChu'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moiTruongId': moiTruongId,
      'ngayDo': ngayDo,
      'doAmDat': doAmDat,
      'nhietDo': nhietDo,
      'doAmKhongKhi': doAmKhongKhi,
      'luongMua': luongMua,
      'ghiChu': ghiChu,
    };
  }
}

class SensorReading {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double rainfall;

  SensorReading({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.rainfall,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      timestamp: DateTime.parse(json['timestamp']),
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      soilMoisture: (json['soilMoisture'] as num).toDouble(),
      rainfall: (json['rainfall'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'soilMoisture': soilMoisture,
      'rainfall': rainfall,
    };
  }
}