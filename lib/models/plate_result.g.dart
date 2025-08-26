// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plate_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlateResult _$PlateResultFromJson(Map<String, dynamic> json) => PlateResult(
      plateNumber: json['plate'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      matchesTemplate: json['matches_template'] as int,
      plateIndex: json['plate_index'] as int,
      region: json['region'] as String,
      regionConfidence: json['region_confidence'] as int,
      processingTimeMs: (json['processing_time_ms'] as num).toDouble(),
      requestedTopN: json['requested_topn'] as int,
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => Coordinate.fromJson(e as Map<String, dynamic>))
          .toList(),
      candidates: (json['candidates'] as List<dynamic>)
          .map((e) => PlateCandidate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlateResultToJson(PlateResult instance) =>
    <String, dynamic>{
      'plate': instance.plateNumber,
      'confidence': instance.confidence,
      'matches_template': instance.matchesTemplate,
      'plate_index': instance.plateIndex,
      'region': instance.region,
      'region_confidence': instance.regionConfidence,
      'processing_time_ms': instance.processingTimeMs,
      'requested_topn': instance.requestedTopN,
      'coordinates': instance.coordinates.map((e) => e.toJson()).toList(),
      'candidates': instance.candidates.map((e) => e.toJson()).toList(),
    };

Coordinate _$CoordinateFromJson(Map<String, dynamic> json) => Coordinate(
      x: json['x'] as int,
      y: json['y'] as int,
    );

Map<String, dynamic> _$CoordinateToJson(Coordinate instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };

PlateCandidate _$PlateCandidateFromJson(Map<String, dynamic> json) =>
    PlateCandidate(
      plate: json['plate'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      matchesTemplate: json['matches_template'] as int,
    );

Map<String, dynamic> _$PlateCandidateToJson(PlateCandidate instance) =>
    <String, dynamic>{
      'plate': instance.plate,
      'confidence': instance.confidence,
      'matches_template': instance.matchesTemplate,
    };

OpenALPRResponse _$OpenALPRResponseFromJson(Map<String, dynamic> json) =>
    OpenALPRResponse(
      version: json['version'] as int,
      dataType: json['data_type'] as String,
      epochTime: json['epoch_time'] as int,
      imgWidth: json['img_width'] as int,
      imgHeight: json['img_height'] as int,
      processingTimeMs: (json['processing_time_ms'] as num).toDouble(),
      regionsOfInterest: json['regions_of_interest'] as List<dynamic>,
      results: (json['results'] as List<dynamic>)
          .map((e) => PlateResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OpenALPRResponseToJson(OpenALPRResponse instance) =>
    <String, dynamic>{
      'version': instance.version,
      'data_type': instance.dataType,
      'epoch_time': instance.epochTime,
      'img_width': instance.imgWidth,
      'img_height': instance.imgHeight,
      'processing_time_ms': instance.processingTimeMs,
      'regions_of_interest': instance.regionsOfInterest,
      'results': instance.results.map((e) => e.toJson()).toList(),
    };