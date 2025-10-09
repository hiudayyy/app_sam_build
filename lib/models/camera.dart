class Camera {
  final String id;
  final String name;
  final String location;
  final String areaId;
  final bool isOnline;
  final String streamUrl;
  final String lastUpdate;
  final CameraType type;

  const Camera({
    required this.id,
    required this.name,
    required this.location,
    required this.areaId,
    required this.isOnline,
    required this.streamUrl,
    required this.lastUpdate,
    required this.type,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      areaId: json['areaId'] ?? '',
      isOnline: json['isOnline'] ?? false,
      streamUrl: json['streamUrl'] ?? '',
      lastUpdate: json['lastUpdate'] ?? '',
      type: CameraType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => CameraType.overview,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'areaId': areaId,
      'isOnline': isOnline,
      'streamUrl': streamUrl,
      'lastUpdate': lastUpdate,
      'type': type.toString().split('.').last,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case CameraType.overview:
        return 'Tổng quan';
      case CameraType.detail:
        return 'Chi tiết';
      case CameraType.security:
        return 'An ninh';
    }
  }

  String formatLastUpdate() {
    try {
      final DateTime dateTime = DateTime.parse(lastUpdate);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}

enum CameraType {
  overview,
  detail,
  security,
}
class CameraStreamResponse {
  final String uri;
  final String content;

  CameraStreamResponse({
    required this.uri,
    required this.content,
  });

  factory CameraStreamResponse.fromJson(Map<String, dynamic> json) {
    return CameraStreamResponse(
      uri: json["uri"] ?? "",
      content: json["content"] ?? "",
    );
  }
}
