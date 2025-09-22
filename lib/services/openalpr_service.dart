import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/plate_result.dart';

/// Service for license plate recognition using OpenALPR
class OpenALPRService {
  static const MethodChannel _channel = MethodChannel('openalpr_flutter');
  
  static const String _configFileName = 'openalpr.conf';
  static const String _runtimeDataDirName = 'runtime_data';
  
  bool _isInitialized = false;
  String? _configPath;
  String? _runtimeDataPath;

  /// Initialize the OpenALPR service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Copy configuration files to app's document directory
      await _copyAssets();
      
      // Initialize OpenALPR with configuration
      final result = await _channel.invokeMethod('initialize', {
        'configPath': _configPath,
        'runtimeDataPath': _runtimeDataPath,
      });
      
      if (result == true) {
        _isInitialized = true;
        print('OpenALPR initialized successfully');
      } else {
        throw Exception('Failed to initialize OpenALPR');
      }
    } catch (e) {
      print('Error initializing OpenALPR: $e');
      rethrow;
    }
  }

  /// Copy OpenALPR configuration assets to app directory
  Future<void> _copyAssets() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(path.join(documentsDir.path, _runtimeDataDirName));
    
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    
    // Copy configuration file
    final configAsset = await rootBundle.loadString('assets/$_runtimeDataDirName/$_configFileName');
    final configFile = File(path.join(targetDir.path, _configFileName));
    await configFile.writeAsString(configAsset);
    
    _configPath = configFile.path;
    _runtimeDataPath = targetDir.path;
  }

  /// Recognize license plates from image file
  Future<List<PlateResult>> recognizePlatesFromFile({
    required String imagePath,
    String country = 'us',
    String region = '',
    int topN = 10,
  }) async {
    if (!_isInitialized) {
      throw Exception('OpenALPR not initialized. Call initialize() first.');
    }
    
    try {
      final result = await _channel.invokeMethod('recognizeFile', {
        'imagePath': imagePath,
        'country': country,
        'region': region,
        'configPath': _configPath,
        'topN': topN,
      });
      
      if (result != null) {
        final response = OpenALPRResponse.fromJson(jsonDecode(result));
        return response.results;
      }
      
      return [];
    } catch (e) {
      print('Error recognizing plates: $e');
      return [];
    }
  }

  /// Recognize license plates from camera image bytes
  Future<List<PlateResult>> recognizePlatesFromBytes({
    required List<int> imageBytes,
    String country = 'us',
    String region = '',
    int topN = 10,
  }) async {
    if (!_isInitialized) {
      throw Exception('OpenALPR not initialized. Call initialize() first.');
    }
    
    try {
      // Save bytes to temporary file first
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, 'temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg'));
      await tempFile.writeAsBytes(imageBytes);
      
      final results = await recognizePlatesFromFile(
        imagePath: tempFile.path,
        country: country,
        region: region,
        topN: topN,
      );
      
      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      return results;
    } catch (e) {
      print('Error recognizing plates from bytes: $e');
      return [];
    }
  }

  /// Check if OpenALPR is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose and cleanup resources
  void dispose() {
    _isInitialized = false;
    _configPath = null;
    _runtimeDataPath = null;
  }
}
