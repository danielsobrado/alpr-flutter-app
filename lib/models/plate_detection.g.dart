// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plate_detection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlateDetection _$PlateDetectionFromJson(Map<String, dynamic> json) =>
    PlateDetection(
      id: json['id'] as String,
      plateNumber: json['plateNumber'] as String,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imagePath: json['imagePath'] as String?,
      provider: json['provider'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PlateDetectionToJson(PlateDetection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plateNumber': instance.plateNumber,
      'detectedAt': instance.detectedAt.toIso8601String(),
      'confidence': instance.confidence,
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'imagePath': instance.imagePath,
      'provider': instance.provider,
      'metadata': instance.metadata,
    };

PlateAnalytics _$PlateAnalyticsFromJson(Map<String, dynamic> json) =>
    PlateAnalytics(
      plateNumber: json['plateNumber'] as String,
      totalDetections: (json['totalDetections'] as num).toInt(),
      firstSeen: DateTime.parse(json['firstSeen'] as String),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      averageConfidence: (json['averageConfidence'] as num).toDouble(),
      locations: (json['locations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      providers: (json['providers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      detectionsByHour: Map<String, int>.from(json['detectionsByHour'] as Map),
      detectionsByDay: Map<String, int>.from(json['detectionsByDay'] as Map),
      totalNotes: (json['totalNotes'] as num).toInt(),
    );

Map<String, dynamic> _$PlateAnalyticsToJson(PlateAnalytics instance) =>
    <String, dynamic>{
      'plateNumber': instance.plateNumber,
      'totalDetections': instance.totalDetections,
      'firstSeen': instance.firstSeen.toIso8601String(),
      'lastSeen': instance.lastSeen.toIso8601String(),
      'averageConfidence': instance.averageConfidence,
      'locations': instance.locations,
      'providers': instance.providers,
      'detectionsByHour': instance.detectionsByHour,
      'detectionsByDay': instance.detectionsByDay,
      'totalNotes': instance.totalNotes,
    };