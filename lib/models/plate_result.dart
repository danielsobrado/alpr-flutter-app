import 'package:json_annotation/json_annotation.dart';

part 'plate_result.g.dart';

@JsonSerializable()
class PlateResult {
  @JsonKey(name: 'plate')
  final String plateNumber;
  
  @JsonKey(name: 'confidence')
  final double confidence;
  
  @JsonKey(name: 'matches_template')
  final int matchesTemplate;
  
  @JsonKey(name: 'plate_index')
  final int plateIndex;
  
  @JsonKey(name: 'region')
  final String region;
  
  @JsonKey(name: 'region_confidence')
  final int regionConfidence;
  
  @JsonKey(name: 'processing_time_ms')
  final double processingTimeMs;
  
  @JsonKey(name: 'requested_topn')
  final int requestedTopN;
  
  @JsonKey(name: 'coordinates')
  final List<Coordinate> coordinates;
  
  @JsonKey(name: 'candidates')
  final List<PlateCandidate> candidates;

  PlateResult({
    required this.plateNumber,
    required this.confidence,
    required this.matchesTemplate,
    required this.plateIndex,
    required this.region,
    required this.regionConfidence,
    required this.processingTimeMs,
    required this.requestedTopN,
    required this.coordinates,
    required this.candidates,
  });

  factory PlateResult.fromJson(Map<String, dynamic> json) => _$PlateResultFromJson(json);
  Map<String, dynamic> toJson() => _$PlateResultToJson(this);
}

@JsonSerializable()
class Coordinate {
  @JsonKey(name: 'x')
  final int x;
  
  @JsonKey(name: 'y')
  final int y;

  Coordinate({
    required this.x,
    required this.y,
  });

  factory Coordinate.fromJson(Map<String, dynamic> json) => _$CoordinateFromJson(json);
  Map<String, dynamic> toJson() => _$CoordinateToJson(this);
}

@JsonSerializable()
class PlateCandidate {
  @JsonKey(name: 'plate')
  final String plate;
  
  @JsonKey(name: 'confidence')
  final double confidence;
  
  @JsonKey(name: 'matches_template')
  final int matchesTemplate;

  PlateCandidate({
    required this.plate,
    required this.confidence,
    required this.matchesTemplate,
  });

  factory PlateCandidate.fromJson(Map<String, dynamic> json) => _$PlateCandidateFromJson(json);
  Map<String, dynamic> toJson() => _$PlateCandidateToJson(this);
}

@JsonSerializable()
class OpenALPRResponse {
  @JsonKey(name: 'version')
  final int version;
  
  @JsonKey(name: 'data_type')
  final String dataType;
  
  @JsonKey(name: 'epoch_time')
  final int epochTime;
  
  @JsonKey(name: 'img_width')
  final int imgWidth;
  
  @JsonKey(name: 'img_height')
  final int imgHeight;
  
  @JsonKey(name: 'processing_time_ms')
  final double processingTimeMs;
  
  @JsonKey(name: 'regions_of_interest')
  final List<dynamic> regionsOfInterest;
  
  @JsonKey(name: 'results')
  final List<PlateResult> results;

  OpenALPRResponse({
    required this.version,
    required this.dataType,
    required this.epochTime,
    required this.imgWidth,
    required this.imgHeight,
    required this.processingTimeMs,
    required this.regionsOfInterest,
    required this.results,
  });

  factory OpenALPRResponse.fromJson(Map<String, dynamic> json) => _$OpenALPRResponseFromJson(json);
  Map<String, dynamic> toJson() => _$OpenALPRResponseToJson(this);
}