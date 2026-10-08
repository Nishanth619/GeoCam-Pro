class Photo {
  final int? id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed;
  final double? heading;
  final String? address;
  final DateTime capturedAt;
  final double? temperature;
  final String? weatherCondition;
  final String? weatherIcon;
  final int? humidity;
  final double? windSpeed;
  /// Project/folder this photo belongs to (null = unassigned).
  final String? projectId;
  /// True when the photo was captured offline and its address still needs
  /// reverse geocoding once connectivity returns.
  final bool geocodePending;

  Photo({
    this.id,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.heading,
    this.address,
    required this.capturedAt,
    this.temperature,
    this.weatherCondition,
    this.weatherIcon,
    this.humidity,
    this.windSpeed,
    this.projectId,
    this.geocodePending = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'address': address,
      'capturedAt': capturedAt.toIso8601String(),
      'temperature': temperature,
      'weatherCondition': weatherCondition,
      'weatherIcon': weatherIcon,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'project_id': projectId,
      'geocode_pending': geocodePending ? 1 : 0,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as int?,
      imagePath: map['imagePath'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      altitude: map['altitude'] as double?,
      speed: map['speed'] as double?,
      heading: map['heading'] as double?,
      address: map['address'] as String?,
      capturedAt: DateTime.parse(map['capturedAt'] as String),
      temperature: map['temperature'] as double?,
      weatherCondition: map['weatherCondition'] as String?,
      weatherIcon: map['weatherIcon'] as String?,
      humidity: map['humidity'] as int?,
      windSpeed: map['windSpeed'] as double?,
      projectId: map['project_id'] as String?,
      geocodePending: (map['geocode_pending'] as int? ?? 0) == 1,
    );
  }

  Photo copyWith({
    int? id,
    String? imagePath,
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    double? heading,
    String? address,
    DateTime? capturedAt,
    double? temperature,
    String? weatherCondition,
    String? weatherIcon,
    int? humidity,
    double? windSpeed,
    String? projectId,
    bool clearProjectId = false,
    bool? geocodePending,
  }) {
    return Photo(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      address: address ?? this.address,
      capturedAt: capturedAt ?? this.capturedAt,
      temperature: temperature ?? this.temperature,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      weatherIcon: weatherIcon ?? this.weatherIcon,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      geocodePending: geocodePending ?? this.geocodePending,
    );
  }

  // Format coordinates as Decimal Degrees (6 decimal places)
  String get coordinatesDD {
    String latDir = latitude >= 0 ? 'N' : 'S';
    String lonDir = longitude >= 0 ? 'E' : 'W';
    return 'Lat ${latitude.abs().toStringAsFixed(6)}° $latDir, Long ${longitude.abs().toStringAsFixed(6)}° $lonDir';
  }

  // Format coordinates as Degrees Minutes Seconds
  String get coordinatesDMS {
    String latDir = latitude >= 0 ? 'N' : 'S';
    String lonDir = longitude >= 0 ? 'E' : 'W';
    
    String latDMS = _toDMS(latitude.abs());
    String lonDMS = _toDMS(longitude.abs());
    
    return '$latDMS $latDir, $lonDMS $lonDir';
  }

  String _toDMS(double decimal) {
    int degrees = decimal.floor();
    double minutesDecimal = (decimal - degrees) * 60;
    int minutes = minutesDecimal.floor();
    double seconds = (minutesDecimal - minutes) * 60;
    
    return '$degrees°${minutes}\'${seconds.toStringAsFixed(1)}"';
  }

  // Format altitude
  String get altitudeFormatted => altitude != null ? '${altitude!.toStringAsFixed(0)}m' : 'N/A';

  // Format temperature
  String get temperatureFormatted => temperature != null ? '${temperature!.toStringAsFixed(0)}°C' : 'N/A';
}
