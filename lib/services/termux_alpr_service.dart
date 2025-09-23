import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/plate_result.dart';

/// Service for ALPR processing using Termux + Predator Mobile
class TermuxAlprService {
  static const MethodChannel _channel = MethodChannel('termux_integration');
  
  bool _isInitialized = false;
  String? _termuxScriptPath;

  /// Check if Termux is available and properly configured
  Future<bool> isTermuxAvailable() async {
    try {
      final result = await _channel.invokeMethod('checkTermux');
      return result == true;
    } catch (e) {
      print('Error checking Termux availability: $e');
      return false;
    }
  }

  /// Initialize the Termux ALPR service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check if Termux is available
      final termuxAvailable = await isTermuxAvailable();
      if (!termuxAvailable) {
        throw Exception('Termux not installed or not accessible');
      }

      // Set the script path in Termux environment
      _termuxScriptPath = '/data/data/com.termux/files/home/Predator/predator_mobile.py';
      
      _isInitialized = true;
      print('TermuxAlprService initialized successfully');
    } catch (e) {
      print('Error initializing TermuxAlprService: $e');
      rethrow;
    }
  }

  /// Process image for license plate recognition using Termux
  Future<List<PlateResult>> recognizePlatesFromFile({
    required String imagePath,
    String country = 'us',
    String region = '',
    int topN = 10,
  }) async {
    if (!_isInitialized) {
      throw Exception('TermuxAlprService not initialized. Call initialize() first.');
    }

    try {
      // Prepare image for processing
      final processedImagePath = await _prepareImageForTermux(imagePath);
      
      // Run Predator mobile script in Termux
      final result = await _runTermuxScript(processedImagePath);
      
      // Parse results
      final List<PlateResult> plates = _parseTermuxResults(result);
      
      // Clean up temporary file
      await _cleanupTempFile(processedImagePath);
      
      return plates.take(topN).toList();
    } catch (e) {
      print('Error recognizing plates with Termux: $e');
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
      final tempFile = File(path.join(tempDir.path, 'temp_alpr_${DateTime.now().millisecondsSinceEpoch}.jpg'));
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

  /// Prepare image for Termux processing
  Future<String> _prepareImageForTermux(String originalImagePath) async {
    try {
      // Create accessible temp directory
      final tempDir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final termuxTempDir = Directory(path.join(tempDir.path, 'termux_alpr'));
      
      if (!await termuxTempDir.exists()) {
        await termuxTempDir.create(recursive: true);
      }
      
      // Copy image to accessible location with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final termuxImagePath = path.join(termuxTempDir.path, 'alpr_input_$timestamp.jpg');
      
      final originalFile = File(originalImagePath);
      await originalFile.copy(termuxImagePath);
      
      // Make file readable by Termux
      await Process.run('chmod', ['644', termuxImagePath]);
      
      return termuxImagePath;
    } catch (e) {
      print('Error preparing image for Termux: $e');
      rethrow;
    }
  }

  /// Run Predator mobile script in Termux
  Future<Map<String, dynamic>> _runTermuxScript(String imagePath) async {
    try {
      print('Running Termux ALPR script on: $imagePath');
      
      final result = await _channel.invokeMethod('runTermuxScript', {
        'script': 'python $_termuxScriptPath',
        'arguments': [imagePath],
        'timeout': 30000, // 30 second timeout
      });
      
      if (result is String) {
        try {
          return json.decode(result);
        } catch (e) {
          print('Error parsing Termux result JSON: $e');
          print('Raw result: $result');
          return {'error': 'Invalid JSON response from Termux', 'success': false};
        }
      } else {
        return {'error': 'Unexpected result type from Termux', 'success': false};
      }
    } catch (e) {
      print('Error running Termux script: $e');
      return {'error': 'Failed to execute Termux script: $e', 'success': false};
    }
  }

  /// Parse Termux/Predator results into PlateResult objects
  List<PlateResult> _parseTermuxResults(Map<String, dynamic> termuxResult) {
    final List<PlateResult> plates = [];
    
    try {
      if (termuxResult['success'] != true) {
        print('Termux processing failed: ${termuxResult['error'] ?? 'Unknown error'}');
        return plates;
      }
      
      final platesData = termuxResult['plates_detected'] as List<dynamic>? ?? [];
      
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
              matchesTemplate: 1, // Default for Termux results
              plateIndex: 0, // Default for Termux results
              region: plateData['region'] as String? ?? 'us',
              regionConfidence: 90, // Default for Termux results
              processingTimeMs: ((termuxResult['processing_time'] as num?)?.toDouble() ?? 0.0) * 1000, // Convert to ms
              requestedTopN: 10, // Default for Termux results
              coordinates: coordinates,
              candidates: [], // Termux version doesn't provide candidates
            );
            
            plates.add(plateResult);
          } catch (e) {
            print('Error parsing individual plate result: $e');
          }
        }
      }
      
      print('Parsed ${plates.length} plates from Termux results');
    } catch (e) {
      print('Error parsing Termux results: $e');
    }
    
    return plates;
  }

  /// Clean up temporary files
  Future<void> _cleanupTempFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error cleaning up temp file: $e');
    }
  }

  /// Get processing statistics from last run
  Future<Map<String, dynamic>?> getLastProcessingStats() async {
    // This could be enhanced to store and retrieve processing statistics
    return null;
  }

  /// Check if the service is initialized and ready
  bool get isInitialized => _isInitialized;

  /// Dispose and cleanup resources
  void dispose() {
    _isInitialized = false;
    _termuxScriptPath = null;
  }
}