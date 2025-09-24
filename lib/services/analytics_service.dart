import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plate_detection.dart';
import '../models/plate_note.dart';
import '../models/plate_result.dart';

class AnalyticsService {
  static const String _detectionsKey = 'plate_detections';
  static const String _notesKey = 'plate_notes';
  
  SharedPreferences? _prefs;
  List<PlateDetection> _detections = [];
  List<PlateNote> _notes = [];
  
  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Initialize the analytics service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadDetections();
    await _loadNotes();
  }

  /// Record a new plate detection
  Future<void> recordDetection(PlateResult plateResult, String provider) async {
    await initialize();
    
    final detection = PlateDetection(
      id: '${DateTime.now().millisecondsSinceEpoch}_${plateResult.plateNumber}',
      plateNumber: plateResult.plateNumber,
      detectedAt: DateTime.now(),
      confidence: plateResult.confidence,
      provider: provider,
      metadata: {
        'processing_time': plateResult.processingTimeMs,
        'region': plateResult.region,
        'coordinates': plateResult.coordinates.map((c) => {'x': c.x, 'y': c.y}).toList(),
      },
    );
    
    _detections.add(detection);
    await _saveDetections();
  }

  /// Record multiple detections from a list
  Future<void> recordDetections(List<PlateResult> plateResults, String provider) async {
    for (final result in plateResults) {
      await recordDetection(result, provider);
    }
  }

  /// Get analytics for a specific plate
  PlateAnalytics? getPlateAnalytics(String plateNumber) {
    final plateDetections = _detections
        .where((d) => d.plateNumber.toUpperCase() == plateNumber.toUpperCase())
        .toList();
    
    if (plateDetections.isEmpty) return null;

    plateDetections.sort((a, b) => a.detectedAt.compareTo(b.detectedAt));
    
    // Calculate hourly distribution
    final detectionsByHour = <String, int>{};
    final detectionsByDay = <String, int>{};
    for (final detection in plateDetections) {
      final hour = detection.detectedAt.hour.toString();
      final day = detection.detectedAt.weekday.toString();
      detectionsByHour[hour] = (detectionsByHour[hour] ?? 0) + 1;
      detectionsByDay[day] = (detectionsByDay[day] ?? 0) + 1;
    }

    // Get unique locations and providers
    final locations = plateDetections
        .where((d) => d.location != null)
        .map((d) => d.location!)
        .toSet()
        .toList();
    
    final providers = plateDetections
        .map((d) => d.provider)
        .toSet()
        .toList();

    // Count notes for this plate
    final noteCount = _notes
        .where((n) => n.plateNumber.toUpperCase() == plateNumber.toUpperCase())
        .length;

    return PlateAnalytics(
      plateNumber: plateNumber,
      totalDetections: plateDetections.length,
      firstSeen: plateDetections.first.detectedAt,
      lastSeen: plateDetections.last.detectedAt,
      averageConfidence: plateDetections
          .map((d) => d.confidence)
          .reduce((a, b) => a + b) / plateDetections.length,
      locations: locations,
      providers: providers,
      detectionsByHour: detectionsByHour,
      detectionsByDay: detectionsByDay,
      totalNotes: noteCount,
    );
  }

  /// Get all unique plates that have been detected
  List<String> getAllDetectedPlates() {
    return _detections
        .map((d) => d.plateNumber.toUpperCase())
        .toSet()
        .toList()
      ..sort();
  }

  /// Get analytics for all plates
  List<PlateAnalytics> getAllPlateAnalytics() {
    return getAllDetectedPlates()
        .map((plate) => getPlateAnalytics(plate))
        .where((analytics) => analytics != null)
        .cast<PlateAnalytics>()
        .toList();
  }

  /// Get detections filtered by date range
  List<PlateDetection> getDetectionsInRange(DateTime start, DateTime end, {String? plateFilter}) {
    return _detections.where((detection) {
      final inRange = detection.detectedAt.isAfter(start) && 
                     detection.detectedAt.isBefore(end.add(const Duration(days: 1)));
      
      if (plateFilter != null && plateFilter.isNotEmpty) {
        return inRange && detection.plateNumber.toUpperCase().contains(plateFilter.toUpperCase());
      }
      
      return inRange;
    }).toList();
  }

  /// Get notes for a specific plate
  List<PlateNote> getNotesForPlate(String plateNumber) {
    return _notes
        .where((n) => n.plateNumber.toUpperCase() == plateNumber.toUpperCase())
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get total statistics
  Map<String, dynamic> getTotalStatistics() {
    final totalDetections = _detections.length;
    final uniquePlates = getAllDetectedPlates().length;
    final totalNotes = _notes.length;
    
    final now = DateTime.now();
    final todayDetections = _detections
        .where((d) => d.detectedAt.day == now.day && 
                     d.detectedAt.month == now.month && 
                     d.detectedAt.year == now.year)
        .length;
    
    final thisWeekDetections = _detections
        .where((d) => now.difference(d.detectedAt).inDays < 7)
        .length;

    // Most frequent plate
    final plateFrequency = <String, int>{};
    for (final detection in _detections) {
      final plate = detection.plateNumber.toUpperCase();
      plateFrequency[plate] = (plateFrequency[plate] ?? 0) + 1;
    }
    
    String? mostFrequentPlate;
    int maxFrequency = 0;
    plateFrequency.forEach((plate, count) {
      if (count > maxFrequency) {
        maxFrequency = count;
        mostFrequentPlate = plate;
      }
    });

    return {
      'totalDetections': totalDetections,
      'uniquePlates': uniquePlates,
      'totalNotes': totalNotes,
      'todayDetections': todayDetections,
      'thisWeekDetections': thisWeekDetections,
      'mostFrequentPlate': mostFrequentPlate,
      'mostFrequentPlateCount': maxFrequency,
      'averageDetectionsPerDay': totalDetections > 0 && _detections.isNotEmpty
          ? totalDetections / (now.difference(_detections.first.detectedAt).inDays + 1)
          : 0.0,
    };
  }

  /// Clear all analytics data
  Future<void> clearAllData() async {
    _detections.clear();
    _notes.clear();
    await _prefs?.remove(_detectionsKey);
    await _prefs?.remove(_notesKey);
  }

  /// Load detections from storage
  Future<void> _loadDetections() async {
    final detectionsJson = _prefs?.getStringList(_detectionsKey) ?? [];
    _detections = detectionsJson
        .map((json) => PlateDetection.fromJson(jsonDecode(json)))
        .toList();
  }

  /// Save detections to storage
  Future<void> _saveDetections() async {
    final detectionsJson = _detections
        .map((detection) => jsonEncode(detection.toJson()))
        .toList();
    await _prefs?.setStringList(_detectionsKey, detectionsJson);
  }

  /// Load notes from storage (if available)
  Future<void> _loadNotes() async {
    final notesJson = _prefs?.getStringList(_notesKey) ?? [];
    _notes = notesJson
        .map((json) => PlateNote.fromJson(jsonDecode(json)))
        .toList();
  }

  /// Add a note (called from other parts of the app)
  Future<void> addNote(PlateNote note) async {
    _notes.add(note);
    final notesJson = _notes
        .map((note) => jsonEncode(note.toJson()))
        .toList();
    await _prefs?.setStringList(_notesKey, notesJson);
  }
}