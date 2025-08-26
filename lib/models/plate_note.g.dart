// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plate_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlateNote _$PlateNoteFromJson(Map<String, dynamic> json) => PlateNote(
      id: json['id'] as String,
      plateNumber: json['plateNumber'] as String,
      userId: json['userId'] as String,
      note: json['note'] as String,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PlateNoteToJson(PlateNote instance) => <String, dynamic>{
      'id': instance.id,
      'plateNumber': instance.plateNumber,
      'userId': instance.userId,
      'note': instance.note,
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'imageUrls': instance.imageUrls,
      'metadata': instance.metadata,
    };