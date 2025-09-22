class Farm {
  final String id;
  final String name;
  final String description;
  final int totalAreas;
  final String location;
  final List<Zone> zones;
  int? investorPlantCount;

  Farm({
    required this.id,
    required this.name,
    required this.description,
    required this.totalAreas,
    required this.location,
    required this.zones,
    this.investorPlantCount,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      totalAreas: json['totalAreas'],
      location: json['location'],
      zones: (json['zones'] as List)
          .map((zone) => Zone.fromJson(zone))
          .toList(),
      investorPlantCount: json['investorPlantCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'totalAreas': totalAreas,
      'location': location,
      'zones': zones.map((zone) => zone.toJson()).toList(),
      'investorPlantCount': investorPlantCount,
    };
  }

  Farm copyWith({
    String? id,
    String? name,
    String? description,
    int? totalAreas,
    String? location,
    List<Zone>? zones,
    int? investorPlantCount,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalAreas: totalAreas ?? this.totalAreas,
      location: location ?? this.location,
      zones: zones ?? this.zones,
      investorPlantCount: investorPlantCount ?? this.investorPlantCount,
    );
  }
}

class Zone {
  final String id;
  final String name;
  final String description;
  final String farmId;
  final List<Area> areas;
  int? investorPlantCount;

  Zone({
    required this.id,
    required this.name,
    required this.description,
    required this.farmId,
    required this.areas,
    this.investorPlantCount,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      farmId: json['farmId'],
      areas: (json['areas'] as List)
          .map((area) => Area.fromJson(area))
          .toList(),
      investorPlantCount: json['investorPlantCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'farmId': farmId,
      'areas': areas.map((area) => area.toJson()).toList(),
      'investorPlantCount': investorPlantCount,
    };
  }

  Zone copyWith({
    String? id,
    String? name,
    String? description,
    String? farmId,
    List<Area>? areas,
    int? investorPlantCount,
  }) {
    return Zone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      farmId: farmId ?? this.farmId,
      areas: areas ?? this.areas,
      investorPlantCount: investorPlantCount ?? this.investorPlantCount,
    );
  }
}

class Area {
  final String id;
  final String name;
  final String description;
  final String zoneId;
  final GridSize gridSize;
  final List<String> plants; // List of plant IDs
  int? investorPlantCount;

  Area({
    required this.id,
    required this.name,
    required this.description,
    required this.zoneId,
    required this.gridSize,
    required this.plants,
    this.investorPlantCount,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      zoneId: json['zoneId'],
      gridSize: GridSize.fromJson(json['gridSize']),
      plants: List<String>.from(json['plants'] ?? []),
      investorPlantCount: json['investorPlantCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'zoneId': zoneId,
      'gridSize': gridSize.toJson(),
      'plants': plants,
      'investorPlantCount': investorPlantCount,
    };
  }

  Area copyWith({
    String? id,
    String? name,
    String? description,
    String? zoneId,
    GridSize? gridSize,
    List<String>? plants,
    int? investorPlantCount,
  }) {
    return Area(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      zoneId: zoneId ?? this.zoneId,
      gridSize: gridSize ?? this.gridSize,
      plants: plants ?? this.plants,
      investorPlantCount: investorPlantCount ?? this.investorPlantCount,
    );
  }
}

class GridSize {
  final int rows;
  final List<String> cols;

  GridSize({
    required this.rows,
    required this.cols,
  });

  factory GridSize.fromJson(Map<String, dynamic> json) {
    return GridSize(
      rows: json['rows'],
      cols: List<String>.from(json['cols']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'cols': cols,
    };
  }
}

enum NavigationLevel {
  farm,
  zone,
  grid,
}