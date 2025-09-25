import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/plate_result.dart';
import 'alpr_service_interface.dart';

/// Multi-engine ALPR service that allows comparison of different engines
class MultiALPRService implements ALPRServiceInterface {
  static const MethodChannel _channel = MethodChannel('chaquopy_flutter');
  
  bool _isInitialized = false;
  List<String> _availableEngines = [];
  String _selectedEngine = '';
  
  /// Available ALPR engines
  static const Map<String, String> engineDescriptions = {
    'fast_plate_ocr': 'Fast Plate OCR (Premium: 3000+ plates/sec, high accuracy)',
    'opencv_tesseract': 'OpenCV + Tesseract (Open source: reliable, customizable)',
  };

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get available engines from Python
      final result = await _channel.invokeMethod('callPython', {
        'module': 'fast_plate_ocr_engine',
        'function': 'get_available_alpr_engines',
        'args': []
      });
      
      if (result != null) {
        final data = jsonDecode(result);
        _availableEngines = List<String>.from(data['available_engines']);
        
        // Set default engine (prefer fast_plate_ocr if available)
        if (_availableEngines.contains('fast_plate_ocr')) {
          _selectedEngine = 'fast_plate_ocr';
        } else if (_availableEngines.isNotEmpty) {
          _selectedEngine = _availableEngines.first;
        }
        
        _isInitialized = true;
        print('MultiALPR initialized with engines: $_availableEngines');
        print('Default engine: $_selectedEngine');
      } else {
        throw Exception('Failed to get available engines');
      }
    } catch (e) {
      print('MultiALPR initialization failed: $e');
      rethrow;
    }
  }

  /// Get list of available ALPR engines
  List<String> get availableEngines => _availableEngines;
  
  /// Get current selected engine
  String get selectedEngine => _selectedEngine;
  
  /// Set the active ALPR engine
  void setEngine(String engineName) {
    if (_availableEngines.contains(engineName)) {
      _selectedEngine = engineName;
      print('Switched to ALPR engine: $engineName');
    } else {
      throw ArgumentError('Engine $engineName is not available');
    }
  }
  
  /// Get engine description
  String getEngineDescription(String engineName) {
    return engineDescriptions[engineName] ?? 'Unknown engine';
  }

  @override
  Future<List<PlateResult>> recognizePlatesFromFile({
    required String imagePath,
    String country = 'us',
    String region = '',
    int topN = 10,
  }) async {
    if (!_isInitialized) {
      throw Exception('MultiALPR not initialized. Call initialize() first.');
    }
    
    if (_selectedEngine.isEmpty) {
      print('No ALPR engine selected');
      return [];
    }
    
    try {
      final result = await _channel.invokeMethod('callPython', {
        'module': 'fast_plate_ocr_engine',
        'function': 'process_with_specific_engine',
        'args': [imagePath, _selectedEngine]
      });
      
      if (result != null) {
        final data = jsonDecode(result);
        if (data['success'] == true) {
          return _convertToPlateResults(data['results'], region, topN);
        } else {
          print('ALPR engine error: ${data['error']}');
          return [];
        }
      }
      
      return [];
    } catch (e) {
      print('Error in recognizePlatesFromFile: $e');
      return [];
    }
  }

  @override
  Future<List<PlateResult>> recognizePlatesFromBytes({
    required List<int> imageBytes,
    String country = 'us',
    String region = '',
    int topN = 10,
  }) async {
    // Save bytes to temp file and process
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(
        tempDir.path, 
        'temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg'
      ));
      
      await tempFile.writeAsBytes(imageBytes);
      
      final results = await recognizePlatesFromFile(
        imagePath: tempFile.path,
        country: country,
        region: region,
        topN: topN,
      );
      
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      return results;
    } catch (e) {
      print('Error in recognizePlatesFromBytes: $e');
      return [];
    }
  }
  
  /// Compare results from all available engines
  Future<Map<String, List<PlateResult>>> compareAllEngines({
    required String imagePath,
    String region = '',
    int topN = 10,
  }) async {
    if (!_isInitialized) {
      throw Exception('MultiALPR not initialized');
    }
    
    try {
      final result = await _channel.invokeMethod('callPython', {
        'module': 'fast_plate_ocr_engine',
        'function': 'compare_all_engines',
        'args': [imagePath]
      });
      
      if (result != null) {
        final data = jsonDecode(result);
        if (data['success'] == true) {
          final comparison = <String, List<PlateResult>>{};
          
          final resultsByEngine = data['results_by_engine'] as Map<String, dynamic>;
          for (final entry in resultsByEngine.entries) {
            final engineName = entry.key;
            final engineResults = entry.value as List;
            comparison[engineName] = _convertToPlateResults(engineResults, region, topN);
          }
          
          return comparison;
        }
      }
      
      return {};
    } catch (e) {
      print('Error in compareAllEngines: $e');
      return {};
    }
  }
  
  /// Get performance info for all engines
  Future<Map<String, dynamic>> getEnginePerformanceInfo() async {
    final info = <String, dynamic>{};
    
    for (final engine in _availableEngines) {
      info[engine] = {
        'description': getEngineDescription(engine),
        'speed': engine == 'fast_plate_ocr' ? 'Very High (3000+ plates/sec)' : 'Medium',
        'accuracy': engine == 'fast_plate_ocr' ? 'Very High' : 'High',
        'cost': engine == 'fast_plate_ocr' ? 'Premium' : 'Free',
        'recommended_for': engine == 'fast_plate_ocr' 
          ? ['High volume processing', 'Real-time applications', 'Maximum accuracy']
          : ['Development', 'Small scale', 'Custom requirements'],
      };
    }
    
    return info;
  }

  /// Convert engine results to PlateResult objects
  List<PlateResult> _convertToPlateResults(List results, String region, int topN) {
    final plateResults = <PlateResult>[];
    
    for (final item in results) {
      if (item is Map<String, dynamic>) {
        try {
          final coords = item['coordinates'] as Map<String, dynamic>? ?? {};
          
          final plateResult = PlateResult(
            plateNumber: item['plate']?.toString() ?? '',
            confidence: (item['confidence'] as num?)?.toDouble() ?? 0.0,
            matchesTemplate: (item['matches_template'] as num?)?.toInt() ?? 0,
            plateIndex: plateResults.length,
            region: region.isNotEmpty ? region : 'us',
            regionConfidence: 90, // Default confidence
            processingTimeMs: 500.0, // Estimated
            requestedTopN: topN,
            coordinates: [
              Coordinate(x: (coords['x1'] as num?)?.toInt() ?? 0, 
                        y: (coords['y1'] as num?)?.toInt() ?? 0),
              Coordinate(x: (coords['x2'] as num?)?.toInt() ?? 300, 
                        y: (coords['y1'] as num?)?.toInt() ?? 0),
              Coordinate(x: (coords['x2'] as num?)?.toInt() ?? 300, 
                        y: (coords['y2'] as num?)?.toInt() ?? 150),
              Coordinate(x: (coords['x1'] as num?)?.toInt() ?? 0, 
                        y: (coords['y2'] as num?)?.toInt() ?? 150),
            ],
            candidates: [
              PlateCandidate(
                plate: item['plate']?.toString() ?? '',
                confidence: (item['confidence'] as num?)?.toDouble() ?? 0.0,
                matchesTemplate: (item['matches_template'] as num?)?.toInt() ?? 0,
              ),
            ],
          );
          
          plateResults.add(plateResult);
        } catch (e) {
          print('Error converting result: $e');
        }
      }
    }
    
    return plateResults;
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Map<String, dynamic> getConfiguration() {
    return {
      'provider': 'multi_alpr',
      'available_engines': _availableEngines,
      'selected_engine': _selectedEngine,
      'engine_descriptions': engineDescriptions,
    };
  }

  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    if (config.containsKey('selected_engine')) {
      final newEngine = config['selected_engine'] as String;
      if (_availableEngines.contains(newEngine)) {
        setEngine(newEngine);
      }
    }
  }

  @override
  void dispose() {
    _isInitialized = false;
    _availableEngines.clear();
    _selectedEngine = '';
  }
}