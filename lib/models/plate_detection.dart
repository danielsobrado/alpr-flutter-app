import 'package:json_annotation/json_annotation.dart';

part 'plate_detection.g.dart';

@JsonSerializable()
class PlateDetection {
  final String id;
  final String plateNumber;
  final DateTime detectedAt;
  final double confidence;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? imagePath;
  final String provider; // Which ALPR service detected it
  final Map<String, dynamic>? metadata;

  const PlateDetection({
    required this.id,
    required this.plateNumber,
    required this.detectedAt,
    required this.confidence,
    this.location,
    this.latitude,
    this.longitude,
    this.imagePath,
    required this.provider,
    this.metadata,
  });

  factory PlateDetection.fromJson(Map<String, dynamic> json) =>
      _$PlateDetectionFromJson(json);

  Map<String, dynamic> toJson() => _$PlateDetectionToJson(this);

  PlateDetection copyWith({
    String? id,
    String? plateNumber,
    DateTime? detectedAt,
    double? confidence,
    String? location,
    double? latitude,
    double? longitude,
    String? imagePath,
    String? provider,
    Map<String, dynamic>? metadata,
  }) {
    return PlateDetection(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      detectedAt: detectedAt ?? this.detectedAt,
      confidence: confidence ?? this.confidence,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imagePath: imagePath ?? this.imagePath,
      provider: provider ?? this.provider,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class PlateAnalytics {
  final String plateNumber;
  final int totalDetections;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final double averageConfidence;
  final List<String> locations;
  final List<String> providers;
  final Map<String, int> detectionsByHour; // Hour of day -> count
  final Map<String, int> detectionsByDay; // Day of week -> count
  final int totalNotes;

  const PlateAnalytics({
    required this.plateNumber,
    required this.totalDetections,
    required this.firstSeen,
    required this.lastSeen,
    required this.averageConfidence,
    required this.locations,
    required this.providers,
    required this.detectionsByHour,
    required this.detectionsByDay,
    required this.totalNotes,
  });

  factory PlateAnalytics.fromJson(Map<String, dynamic> json) =>
      _$PlateAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$PlateAnalyticsToJson(this);

  Duration get timeBetweenFirstAndLast =>
      lastSeen.difference(firstSeen);

  double get detectionsPerDay =>
      totalDetections / (timeBetweenFirstAndLast.inDays + 1);

  String get mostCommonHour {
    if (detectionsByHour.isEmpty) return 'N/A';
    final maxEntry = detectionsByHour.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    final hour = int.parse(maxEntry.key);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $period';
  }

  String get mostCommonDay {
    if (detectionsByDay.isEmpty) return 'N/A';
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final maxEntry = detectionsByDay.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    final dayIndex = int.parse(maxEntry.key);
    return dayIndex >= 0 && dayIndex < days.length ? days[dayIndex] : 'N/A';
  }
}