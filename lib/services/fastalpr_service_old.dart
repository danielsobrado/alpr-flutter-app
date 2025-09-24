import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;
import '../models/plate_result.dart';
import 'alpr_service_interface.dart';
import 'model_manager.dart';

/// Service for license plate recognition using FastALPR with ONNX models
/// Updated for ONNX Runtime 1.4.1 compatibility
class FastALPRService implements ALPRServiceInterface {
  static const String _detectorModelAsset = 'assets/models/yolo-v9-t-384-license-plate-end2end.onnx';
  static const String _ocrModelAsset = 'assets/models/cct-xs-v1-global-model.onnx';

  OrtSession? _detectorSession;
  OrtSession? _ocrSession;
  bool _isInitialized = false;
  String? _detectorModelPath;
  String? _ocrModelPath;

  /// Initialize the FastALPR service
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize ONNX Runtime
      OrtEnv.instance.init();

      // Copy ONNX models to app directory
      await _copyModelsToDevice();

      // Load detection model with basic options for compatibility
      _detectorSession = OrtSession.fromFile(
        File(_detectorModelPath!),
        OrtSessionOptions(),
      );

      // Load OCR model
      _ocrSession = OrtSession.fromFile(
        File(_ocrModelPath!),
        OrtSessionOptions(),
      );

      _isInitialized = true;
      print('FastALPR initialized successfully');
    } catch (e) {
      print('Error initializing FastALPR: $e');
      rethrow;
    }
  }

  /// Copy ONNX model files to device storage
  Future<void> _copyModelsToDevice() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(path.join(documentsDir.path, 'fastalpr_models'));

    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    try {
      // Copy detector model
      final detectorBytes = await rootBundle.load(_detectorModelAsset);
      final detectorFile = File(path.join(modelsDir.path, 'detector.onnx'));
      await detectorFile.writeAsBytes(detectorBytes.buffer.asUint8List());
      _detectorModelPath = detectorFile.path;

      // Copy OCR model
      final ocrBytes = await rootBundle.load(_ocrModelAsset);
      final ocrFile = File(path.join(modelsDir.path, 'ocr.onnx'));
      await ocrFile.writeAsBytes(ocrBytes.buffer.asUint8List());
      _ocrModelPath = ocrFile.path;

      print('FastALPR models copied successfully');
    } catch (e) {
      print('Error copying FastALPR models: $e');
      throw Exception('Failed to copy required FastALPR models: $e');
    }
  }

  /// Recognize license plates from image file
  @override
  Future<List<PlateResult>> recognizePlatesFromFile({
    required String imagePath,
    String country = 'us',
    String region = '',
    int topN = 10,
  }) async {
    if (!_isInitialized) {
      throw Exception('FastALPR not initialized. Call initialize() first.');
    }

    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      return await recognizePlatesFromBytes(
        imageBytes: imageBytes,
        country: country,
        region: region,
        topN: topN,
      );
    } catch (e) {
      print('Error recognizing plates from file: $e');
      return [];
    }
  }

  /// Recognize license plates from image bytes
  @override
  Future<List<PlateResult>> recognizePlatesFromBytes({
    required List<int> imageBytes,
    String country = 'us',
    String region = '',
    int topN = 10,
  }) async {
    if (!_isInitialized) {
      throw Exception('FastALPR not initialized. Call initialize() first.');
    }

    try {
      // For now, return a placeholder result to test the integration
      // TODO: Implement actual ONNX inference when models are available
      print('FastALPR processing image with ${imageBytes.length} bytes');

      // Simulate processing delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Return mock result for testing
      return [
        PlateResult(
          plateNumber: 'FAST123',
          confidence: 85.0,
          matchesTemplate: 1,
          plateIndex: 0,
          region: region.isNotEmpty ? region : 'us',
          regionConfidence: 85,
          processingTimeMs: 500.0,
          requestedTopN: topN,
          coordinates: [
            Coordinate(x: 100, y: 100),
            Coordinate(x: 200, y: 100),
            Coordinate(x: 200, y: 150),
            Coordinate(x: 100, y: 150),
          ],
          candidates: [
            PlateCandidate(
              plate: 'FAST123',
              confidence: 85.0,
              matchesTemplate: 1,
            ),
          ],
        ),
      ];
    } catch (e) {
      print('Error recognizing plates from bytes: $e');
      return [];
    }
  }

  /// Check if FastALPR is initialized
  @override
  bool get isInitialized => _isInitialized;

  /// Get service-specific configuration options
  @override
  Map<String, dynamic> getConfiguration() {
    return {
      'provider': 'fastalpr',
      'detector_model_path': _detectorModelPath,
      'ocr_model_path': _ocrModelPath,
      'supports_yolo_detection': true,
      'supports_advanced_ocr': true,
      'mock_mode': true, // Indicate this is using mock results
    };
  }

  /// Update service configuration
  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    // Could be extended to support dynamic model switching
  }

  /// Dispose and cleanup resources
  @override
  void dispose() {
    _detectorSession?.release();
    _ocrSession?.release();
    _detectorSession = null;
    _ocrSession = null;
    _isInitialized = false;
    _detectorModelPath = null;
    _ocrModelPath = null;
  }
}