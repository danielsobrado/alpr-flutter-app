import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/plate_note.dart';

/// Local file-based notes service (no cloud)
class NotesService {
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  static const _fileName = 'plate_notes.json';
  static const _localUserId = 'local';

  File? _dbFile;
  bool _initialized = false;
  final List<PlateNote> _notes = [];

  Future<void> _init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _dbFile = File(p.join(dir.path, _fileName));
    if (!await _dbFile!.exists()) {
      await _dbFile!.create(recursive: true);
      await _dbFile!.writeAsString(jsonEncode([]));
    }
    await _load();
    _initialized = true;
  }

  Future<void> _load() async {
    try {
      final content = await _dbFile!.readAsString();
      final List<dynamic> jsonList = content.isEmpty ? [] : jsonDecode(content);
      _notes
        ..clear()
        ..addAll(jsonList.map((e) => PlateNote.fromJson(Map<String, dynamic>.from(e))));
      _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      // Reset corrupt file
      _notes.clear();
      await _dbFile!.writeAsString(jsonEncode([]));
    }
  }

  Future<void> _save() async {
    final data = _notes.map((n) => n.toJson()).toList();
    await _dbFile!.writeAsString(jsonEncode(data));
  }

  String _generateId() {
    final rand = Random();
    final millis = DateTime.now().millisecondsSinceEpoch;
    final suffix = List.generate(6, (_) => rand.nextInt(36))
        .map((n) => n.toRadixString(36))
        .join();
    return '${millis}_$suffix';
  }

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
    await _init();
    try {
      final id = _generateId();
      final now = DateTime.now();
      final plateNote = PlateNote(
        id: id,
        plateNumber: plateNumber.toUpperCase().trim(),
        userId: _localUserId,
        note: note,
        location: location,
        latitude: latitude,
        longitude: longitude,
        createdAt: now,
        updatedAt: now,
        imageUrls: imageUrls,
        metadata: metadata,
      );
      _notes.insert(0, plateNote);
      await _save();
      return id;
    } catch (e) {
      print('Error adding plate note: $e');
      return null;
    }
  }

  /// Get all notes for a specific license plate
  Future<List<PlateNote>> getNotesForPlate(String plateNumber) async {
    await _init();
    try {
      final key = plateNumber.toUpperCase().trim();
      return _notes.where((n) => n.plateNumber == key).toList();
    } catch (e) {
      print('Error getting notes for plate: $e');
      return [];
    }
  }

  /// Get all notes (local user only)
  Future<List<PlateNote>> getUserNotes({int? limit}) async {
    await _init();
    try {
      final list = List<PlateNote>.from(_notes);
      if (limit != null && limit < list.length) {
        return list.take(limit).toList();
      }
      return list;
    } catch (e) {
      print('Error getting user notes: $e');
      return [];
    }
  }

  /// Update an existing note
  Future<bool> updatePlateNote(
    String noteId, {
    String? note,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
  }) async {
    await _init();
    try {
      final index = _notes.indexWhere((n) => n.id == noteId);
      if (index == -1) return false;
      var updated = _notes[index];
      updated = updated.copyWith(
        note: note ?? updated.note,
        location: location ?? updated.location,
        latitude: latitude ?? updated.latitude,
        longitude: longitude ?? updated.longitude,
        imageUrls: imageUrls ?? updated.imageUrls,
        metadata: metadata ?? updated.metadata,
        updatedAt: DateTime.now(),
      );
      _notes[index] = updated;
      await _save();
      return true;
    } catch (e) {
      print('Error updating plate note: $e');
      return false;
    }
  }

  /// Delete a note
  Future<bool> deletePlateNote(String noteId) async {
    await _init();
    try {
      final before = _notes.length;
      _notes.removeWhere((n) => n.id == noteId);
      final removed = before - _notes.length;
      await _save();
      return removed > 0;
    } catch (e) {
      print('Error deleting plate note: $e');
      return false;
    }
  }

  /// Stream of notes for a specific plate (simple, not real-time file watch)
  Stream<List<PlateNote>> watchNotesForPlate(String plateNumber) async* {
    final list = await getNotesForPlate(plateNumber);
    yield list;
  }

  /// Clear all notes
  Future<void> clearAllNotes() async {
    await _init();
    _notes.clear();
    await _save();
  }

  /// Export notes to a JSON file.
  /// Returns the primary exported file path.
  Future<String> exportNotes() async {
    await _init();
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final fileName = 'plate_notes_export_$timestamp.json';

    // Always write to app documents directory
    final docsDir = await getApplicationDocumentsDirectory();
    final exportFile = File(p.join(docsDir.path, fileName));
    await exportFile.writeAsString(await _dbFile!.readAsString());

    // Best-effort: also write to app-specific external storage (Android)
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final extFile = File(p.join(extDir.path, fileName));
        await extFile.writeAsString(await _dbFile!.readAsString());
      }
    } catch (_) {
      // Ignore external storage failures
    }

    return exportFile.path;
  }

  /// Import notes from JSON text. Returns number of notes imported.
  /// If merge is false, replaces existing notes; otherwise merges by id.
  Future<int> importNotesFromJson(String jsonText, {bool merge = true}) async {
    await _init();
    final decoded = jsonDecode(jsonText);
    if (decoded is! List) {
      throw const FormatException('Invalid JSON: expected a list');
    }
    final List<PlateNote> incoming = decoded
        .map((e) => PlateNote.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (!merge) {
      _notes
        ..clear()
        ..addAll(incoming);
    } else {
      final existingById = {for (final n in _notes) n.id: n};
      for (final n in incoming) {
        existingById[n.id] = n;
      }
      _notes
        ..clear()
        ..addAll(existingById.values);
    }

    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _save();
    return incoming.length;
  }
}
