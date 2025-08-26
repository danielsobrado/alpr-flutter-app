import 'package:json_annotation/json_annotation.dart';

part 'plate_note.g.dart';

@JsonSerializable()
class PlateNote {
  final String id;
  final String plateNumber;
  final String userId;
  final String note;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? imageUrls;
  final Map<String, dynamic>? metadata;

  PlateNote({
    required this.id,
    required this.plateNumber,
    required this.userId,
    required this.note,
    this.location,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrls,
    this.metadata,
  });

  factory PlateNote.fromJson(Map<String, dynamic> json) => _$PlateNoteFromJson(json);
  Map<String, dynamic> toJson() => _$PlateNoteToJson(this);

  PlateNote copyWith({
    String? id,
    String? plateNumber,
    String? userId,
    String? note,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
  }) {
    return PlateNote(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      userId: userId ?? this.userId,
      note: note ?? this.note,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrls: imageUrls ?? this.imageUrls,
      metadata: metadata ?? this.metadata,
    );
  }
}