import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/plate_result.dart';

/// Service for ALPR processing using Chaquopy + Predator Python integration
class ChaquopyAlprService {
  static const MethodChannel _channel = MethodChannel('chaquopy_alpr');
  
  bool _isInitialized = false;

  /// Check if Chaquopy is available and initialize
  Future<bool> isChaquopyAvailable() async {
    try {
      await _channel.invokeMethod('initialize');
      return true;
    } catch (e) {
      print('Chaquopy not available: $e');
      return false;
    }
  }

  /// Initialize the Chaquopy ALPR service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final result = await _channel.invokeMethod('initialize');
      if (result == true) {
        _isInitialized = true;
        print('ChaquopyAlprService initialized successfully');
      } else {
        throw Exception('Failed to initialize Chaquopy ALPR');
      }
    } catch (e) {
      print('Error initializing ChaquopyAlprService: $e');
      rethrow;
    }
  }

  /// Process image for license plate recognition using Chaquopy
  Future<List<PlateResult>> recognizePlatesFromFile({
    required String imagePath,
    String country = 'us',
    String region = '',
    int topN = 10,
  }) async {
    if (!_isInitialized) {
      throw Exception('ChaquopyAlprService not initialized. Call initialize() first.');
    }

    try {
      print('Processing image with Chaquopy ALPR: $imagePath');
      
      // Call Chaquopy method
      final result = await _channel.invokeMethod('recognizeFile', {
        'imagePath': imagePath,
        'country': country,
        'topN': topN,
      });
      
      if (result is String) {
        // Parse JSON response
        final Map<String, dynamic> jsonResult = json.decode(result);
        
        // Convert to PlateResult objects
        final List<PlateResult> plates = _parseChaquopyResults(jsonResult);
        
        return plates.take(topN).toList();
      } else {
        throw Exception('Unexpected result type from Chaquopy');
      }
    } catch (e) {
      print('Error recognizing plates with Chaquopy: $e');
      return [];
    }
  }

  /// Process image from bytes
  Future<List<PlateResult>> recognizePlatesFromBytes({
    required List<int> imageBytes,
    String country = 'us',
    String region = '',
    int topN = 10,
  }) async {
    try {
      // Save bytes to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, 'temp_chaquopy_${DateTime.now().millisecondsSinceEpoch}.jpg'));
      await tempFile.writeAsBytes(imageBytes);
      
      // Process with file method
      final results = await recognizePlatesFromFile(
        imagePath: tempFile.path,
        country: country,
        region: region,
        topN: topN,
      );
      
      // Clean up
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      return results;
    } catch (e) {
      print('Error recognizing plates from bytes: $e');
      return [];
    }
  }

  /// Set confidence threshold for plate detection
  Future<bool> setConfidenceThreshold(double threshold) async {
    if (!_isInitialized) {
      throw Exception('ChaquopyAlprService not initialized');
    }

    try {
      final result = await _channel.invokeMethod('setConfidenceThreshold', {
        'threshold': threshold,
      });
      
      if (result is String) {
        final Map<String, dynamic> jsonResult = json.decode(result);
        return jsonResult['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error setting confidence threshold: $e');
      return false;
    }
  }

  /// Get version and capability information
  Future<Map<String, dynamic>?> getVersionInfo() async {
    if (!_isInitialized) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod('getVersionInfo');
      
      if (result is String) {
        return json.decode(result);
      }
      return null;
    } catch (e) {
      print('Error getting version info: $e');
      return null;
    }
  }

  /// Parse Chaquopy/Predator results into PlateResult objects
  List<PlateResult> _parseChaquopyResults(Map<String, dynamic> chaquopyResult) {
    final List<PlateResult> plates = [];
    
    try {
      if (chaquopyResult['success'] != true) {
        print('Chaquopy processing failed: ${chaquopyResult['error'] ?? 'Unknown error'}');
        return plates;
      }
      
      final platesData = chaquopyResult['plates_detected'] as List<dynamic>? ?? [];
      
      for (final plateData in platesData) {
        if (plateData is Map<String, dynamic>) {
          try {
            // Extract coordinates
            final coords = plateData['coordinates'] as Map<String, dynamic>? ?? {};
            final List<Coordinate> coordinates = [
              Coordinate(x: ((coords['x'] as num?)?.toInt() ?? 0), y: ((coords['y'] as num?)?.toInt() ?? 0)),
              Coordinate(x: ((coords['x'] as num?)?.toInt() ?? 0) + ((coords['width'] as num?)?.toInt() ?? 0), y: ((coords['y'] as num?)?.toInt() ?? 0)),
              Coordinate(x: ((coords['x'] as num?)?.toInt() ?? 0) + ((coords['width'] as num?)?.toInt() ?? 0), y: ((coords['y'] as num?)?.toInt() ?? 0) + ((coords['height'] as num?)?.toInt() ?? 0)),
              Coordinate(x: ((coords['x'] as num?)?.toInt() ?? 0), y: ((coords['y'] as num?)?.toInt() ?? 0) + ((coords['height'] as num?)?.toInt() ?? 0)),
            ];
            
            // Create plate result
            final plateResult = PlateResult(
              plateNumber: plateData['plate_number'] as String? ?? '',
              confidence: (plateData['confidence'] as num?)?.toDouble() ?? 0.0,
              matchesTemplate: 1, // Default for Chaquopy results
              plateIndex: 0, // Default for Chaquopy results
              region: plateData['region'] as String? ?? 'us',
              regionConfidence: 90, // Default for Chaquopy results
              processingTimeMs: ((chaquopyResult['processing_time'] as num?)?.toDouble() ?? 0.0) * 1000, // Convert to ms
              requestedTopN: 10, // Default for Chaquopy results
              coordinates: coordinates,
              candidates: [], // Chaquopy version doesn't provide candidates
            );
            
            plates.add(plateResult);
          } catch (e) {
            print('Error parsing individual plate result: $e');
          }
        }
      }
      
      print('Parsed ${plates.length} plates from Chaquopy results');
    } catch (e) {
      print('Error parsing Chaquopy results: $e');
    }
    
    return plates;
  }

  /// Get processing statistics from last run
  Future<Map<String, dynamic>?> getLastProcessingStats() async {
    // Could be enhanced to track processing statistics
    return null;
  }

  /// Check if the service is initialized and ready
  bool get isInitialized => _isInitialized;

  /// Get engine name for identification
  String get engineName => 'Chaquopy Predator ALPR';

  /// Dispose and cleanup resources
  void dispose() {
    _isInitialized = false;
  }
}