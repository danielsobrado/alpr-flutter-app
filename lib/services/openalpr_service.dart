import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/plate_result.dart';
import 'alpr_service_interface.dart';

/// Service for license plate recognition using OpenALPR
class OpenALPRService implements ALPRServiceInterface {
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
    
    // Create required directory structure
    await _createDirectoryStructure(targetDir);
    
    try {
      // Copy main configuration file
      final configAsset = await rootBundle.loadString('assets/$_runtimeDataDirName/$_configFileName');
      final configFile = File(path.join(targetDir.path, _configFileName));
      await configFile.writeAsString(configAsset);
      
      // Copy all runtime data files
      await _copyRuntimeDataFiles(targetDir);
      
      _configPath = configFile.path;
      _runtimeDataPath = targetDir.path;
      
      print('OpenALPR assets copied successfully');
      print('Config path: $_configPath');
      print('Runtime data path: $_runtimeDataPath');
    } catch (e) {
      print('Error copying OpenALPR assets: $e');
      throw Exception('Failed to copy required OpenALPR assets: $e');
    }
  }

  /// Create required directory structure for OpenALPR
  Future<void> _createDirectoryStructure(Directory targetDir) async {
    final directories = [
      'config',
      'ocr/tessdata',
      'postprocess',
      'region',
      'keypoints/us',
    ];
    
    for (final dir in directories) {
      final directory = Directory(path.join(targetDir.path, dir));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
  }

  /// Copy all runtime data files from assets
  Future<void> _copyRuntimeDataFiles(Directory targetDir) async {
    // File mappings: asset path -> target path
    final fileMap = {
      'assets/$_runtimeDataDirName/config/us.conf': 'config/us.conf',
      'assets/$_runtimeDataDirName/ocr/tessdata/lus.traineddata': 'ocr/tessdata/lus.traineddata',
      'assets/$_runtimeDataDirName/postprocess/us.patterns': 'postprocess/us.patterns',
      'assets/$_runtimeDataDirName/region/us.xml': 'region/us.xml',
    };

    for (final entry in fileMap.entries) {
      final assetPath = entry.key;
      final targetPath = entry.value;
      final targetFile = File(path.join(targetDir.path, targetPath));

      try {
        if (assetPath.endsWith('.traineddata')) {
          // Handle binary files
          final bytes = await rootBundle.load(assetPath);
          await targetFile.writeAsBytes(bytes.buffer.asUint8List());
        } else {
          // Handle text files
          final content = await rootBundle.loadString(assetPath);
          await targetFile.writeAsString(content);
        }
        print('Copied: $assetPath -> ${targetFile.path}');
      } catch (e) {
        print('Warning: Could not copy $assetPath: $e');
        // Continue with other files if one fails
      }
    }
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
  @override
  bool get isInitialized => _isInitialized;

  /// Get service-specific configuration options
  @override
  Map<String, dynamic> getConfiguration() {
    return {
      'provider': 'openalpr',
      'config_path': _configPath,
      'runtime_data_path': _runtimeDataPath,
      'supports_regions': true,
      'supports_country_codes': true,
    };
  }

  /// Update service configuration
  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    // OpenALPR configuration is handled through initialization
    // Could be extended to support dynamic configuration updates
  }

  /// Dispose and cleanup resources
  @override
  void dispose() {
    _isInitialized = false;
    _configPath = null;
    _runtimeDataPath = null;
  }
}
