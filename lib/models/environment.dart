class DeviceZone {
  final String id;
  final String name;
  final String? description;
  final ZoneLocation location;
  final int deviceCount;
  final ZoneStatus status;
  final String createdAt;

  DeviceZone({
    required this.id,
    required this.name,
    this.description,
    required this.location,
    required this.deviceCount,
    required this.status,
    required this.createdAt,
  });

  factory DeviceZone.fromJson(Map<String, dynamic> json) {
    return DeviceZone(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: ZoneLocation.fromJson(json['location']),
      deviceCount: json['deviceCount'],
      status: ZoneStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location.toJson(),
      'deviceCount': deviceCount,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
    };
  }
}

class ZoneLocation {
  final double? latitude;
  final double? longitude;
  final String address;

  ZoneLocation({this.latitude, this.longitude, this.address = ''});

  factory ZoneLocation.fromJson(Map<String, dynamic> json) {
    return ZoneLocation(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}

enum ZoneStatus { active, inactive, maintenance }

class SensorDevice {
  final String id;
  final String name;
  final SensorType type;
  final String zoneId;
  final DeviceStatus status;
  final int? batteryLevel;
  final String lastSync;
  final String? model;
  final String installDate;
  final String? calibrationDate;

  SensorDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.zoneId,
    required this.status,
    this.batteryLevel,
    required this.lastSync,
    this.model,
    required this.installDate,
    this.calibrationDate,
  });

  factory SensorDevice.fromJson(Map<String, dynamic> json) {
    return SensorDevice(
      id: json['id'],
      name: json['name'],
      type: SensorType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
      ),
      zoneId: json['zoneId'],
      status: DeviceStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
      ),
      batteryLevel: json['batteryLevel'],
      lastSync: json['lastSync'],
      model: json['model'],
      installDate: json['installDate'],
      calibrationDate: json['calibrationDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'zoneId': zoneId,
      'status': status.toString().split('.').last,
      'batteryLevel': batteryLevel,
      'lastSync': lastSync,
      'model': model,
      'installDate': installDate,
      'calibrationDate': calibrationDate,
    };
  }
}

enum SensorType { temperature, humidity, soilMoisture, ph, light, rainfall }
enum DeviceStatus { online, offline, error }

class EnvironmentReading {
  final String id;
  final String deviceId;
  final String zoneId;
  final String timestamp;
  final String sensorType;
  final double value;
  final String unit;
  final bool isValid;
  final String? notes;

  EnvironmentReading({
    required this.id,
    required this.deviceId,
    required this.zoneId,
    required this.timestamp,
    required this.sensorType,
    required this.value,
    required this.unit,
    required this.isValid,
    this.notes,
  });

  factory EnvironmentReading.fromJson(Map<String, dynamic> json) {
    return EnvironmentReading(
      id: json['id'],
      deviceId: json['deviceId'],
      zoneId: json['zoneId'],
      timestamp: json['timestamp'],
      sensorType: json['sensorType'],
      value: json['value'].toDouble(),
      unit: json['unit'],
      isValid: json['isValid'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'zoneId': zoneId,
      'timestamp': timestamp,
      'sensorType': sensorType,
      'value': value,
      'unit': unit,
      'isValid': isValid,
      'notes': notes,
    };
  }
}

class DataCollection {
  final String id;
  final String zoneId;
  final String collectionDate;
  final CollectionInterval interval;
  final CollectionStatus status;
  final int deviceCount;
  final int readingsCount;
  final double? averageTemperature;
  final double? averageHumidity;
  final double? averageSoilMoisture;
  final String? notes;

  DataCollection({
    required this.id,
    required this.zoneId,
    required this.collectionDate,
    required this.interval,
    required this.status,
    required this.deviceCount,
    required this.readingsCount,
    this.averageTemperature,
    this.averageHumidity,
    this.averageSoilMoisture,
    this.notes,
  });

  factory DataCollection.fromJson(Map<String, dynamic> json) {
    return DataCollection(
      id: json['id'],
      zoneId: json['zoneId'],
      collectionDate: json['collectionDate'],
      interval: CollectionInterval.values.firstWhere(
            (e) => e.toString().split('.').last == json['interval'],
      ),
      status: CollectionStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
      ),
      deviceCount: json['deviceCount'],
      readingsCount: json['readingsCount'],
      averageTemperature: json['averageTemperature']?.toDouble(),
      averageHumidity: json['averageHumidity']?.toDouble(),
      averageSoilMoisture: json['averageSoilMoisture']?.toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zoneId': zoneId,
      'collectionDate': collectionDate,
      'interval': interval.toString().split('.').last,
      'status': status.toString().split('.').last,
      'deviceCount': deviceCount,
      'readingsCount': readingsCount,
      'averageTemperature': averageTemperature,
      'averageHumidity': averageHumidity,
      'averageSoilMoisture': averageSoilMoisture,
      'notes': notes,
    };
  }
}

enum CollectionInterval { daily, weekly, monthly }
enum CollectionStatus { pending, collecting, completed, failed }

class EnvironmentAlert {
  final String id;
  final String zoneId;
  final String? deviceId;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final String timestamp;
  final bool isResolved;
  final String? resolvedAt;
  final String? resolvedBy;

  EnvironmentAlert({
    required this.id,
    required this.zoneId,
    this.deviceId,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.isResolved,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory EnvironmentAlert.fromJson(Map<String, dynamic> json) {
    return EnvironmentAlert(
      id: json['id'],
      zoneId: json['zoneId'],
      deviceId: json['deviceId'],
      type: AlertType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
      ),
      severity: AlertSeverity.values.firstWhere(
            (e) => e.toString().split('.').last == json['severity'],
      ),
      message: json['message'],
      timestamp: json['timestamp'],
      isResolved: json['isResolved'],
      resolvedAt: json['resolvedAt'],
      resolvedBy: json['resolvedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zoneId': zoneId,
      'deviceId': deviceId,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'message': message,
      'timestamp': timestamp,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt,
      'resolvedBy': resolvedBy,
    };
  }
}

enum AlertType {
  temperatureHigh,
  temperatureLow,
  humidityHigh,
  humidityLow,
  soilDry,
  soilWet,
  deviceOffline,
  batteryLow
}

enum AlertSeverity { low, medium, high, critical }