import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plate_note.dart';
import 'auth_service.dart';

class NotesService {
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Add a new note for a license plate
  Future<String?> addPlateNote({
    required String plateNumber,
    required String note,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final noteDoc = _firestore.collection('plate_notes').doc();
      final plateNote = PlateNote(
        id: noteDoc.id,
        plateNumber: plateNumber.toUpperCase().trim(),
        userId: user.uid,
        note: note,
        location: location,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: imageUrls,
        metadata: metadata,
      );

      await noteDoc.set({
        'id': plateNote.id,
        'plateNumber': plateNote.plateNumber,
        'userId': plateNote.userId,
        'note': plateNote.note,
        'location': plateNote.location,
        'latitude': plateNote.latitude,
        'longitude': plateNote.longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrls': plateNote.imageUrls,
        'metadata': plateNote.metadata,
      });

      return noteDoc.id;
    } catch (e) {
      print('Error adding plate note: $e');
      return null;
    }
  }

  /// Get all notes for a specific license plate
  Future<List<PlateNote>> getNotesForPlate(String plateNumber) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('plate_notes')
          .where('plateNumber', isEqualTo: plateNumber.toUpperCase().trim())
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return PlateNote(
          id: data['id'],
          plateNumber: data['plateNumber'],
          userId: data['userId'],
          note: data['note'] ?? '',
          location: data['location'],
          latitude: data['latitude']?.toDouble(),
          longitude: data['longitude']?.toDouble(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          imageUrls: data['imageUrls'] != null 
              ? List<String>.from(data['imageUrls'])
              : null,
          metadata: data['metadata'] != null 
              ? Map<String, dynamic>.from(data['metadata'])
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error getting notes for plate: $e');
      return [];
    }
  }

  /// Get all notes for the current user
  Future<List<PlateNote>> getUserNotes({int? limit}) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return [];
      }

      Query query = _firestore
          .collection('plate_notes')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PlateNote(
          id: data['id'],
          plateNumber: data['plateNumber'],
          userId: data['userId'],
          note: data['note'] ?? '',
          location: data['location'],
          latitude: data['latitude']?.toDouble(),
          longitude: data['longitude']?.toDouble(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          imageUrls: data['imageUrls'] != null 
              ? List<String>.from(data['imageUrls'])
              : null,
          metadata: data['metadata'] != null 
              ? Map<String, dynamic>.from(data['metadata'])
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error getting user notes: $e');
      return [];
    }
  }

  /// Update an existing note
  Future<bool> updatePlateNote(String noteId, {
    String? note,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (note != null) updateData['note'] = note;
      if (location != null) updateData['location'] = location;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (imageUrls != null) updateData['imageUrls'] = imageUrls;
      if (metadata != null) updateData['metadata'] = metadata;

      await _firestore
          .collection('plate_notes')
          .doc(noteId)
          .update(updateData);

      return true;
    } catch (e) {
      print('Error updating plate note: $e');
      return false;
    }
  }

  /// Delete a note
  Future<bool> deletePlateNote(String noteId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('plate_notes')
          .doc(noteId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting plate note: $e');
      return false;
    }
  }

  /// Stream of notes for a specific plate
  Stream<List<PlateNote>> watchNotesForPlate(String plateNumber) {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('plate_notes')
        .where('plateNumber', isEqualTo: plateNumber.toUpperCase().trim())
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PlateNote(
          id: data['id'],
          plateNumber: data['plateNumber'],
          userId: data['userId'],
          note: data['note'] ?? '',
          location: data['location'],
          latitude: data['latitude']?.toDouble(),
          longitude: data['longitude']?.toDouble(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          imageUrls: data['imageUrls'] != null 
              ? List<String>.from(data['imageUrls'])
              : null,
          metadata: data['metadata'] != null 
              ? Map<String, dynamic>.from(data['metadata'])
              : null,
        );
      }).toList();
    });
  }
}