import 'dart:io';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../models/plate_result.dart';
import 'alpr_service_interface.dart';

/// Service for license plate recognition using FastALPR with ONNX models
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

      // Load detection model
      final detectorOptions = OrtSessionOptions()
        ..setIntraOpNumThreads(1)
        ..setInterOpNumThreads(1)
        ..setSessionGraphOptimizationLevel(
          GraphOptimizationLevel.ortEnableExtended,
        );

      _detectorSession = OrtSession.fromFile(
        File(_detectorModelPath!),
        detectorOptions,
      );

      // Load OCR model
      final ocrOptions = OrtSessionOptions()
        ..setIntraOpNumThreads(1)
        ..setInterOpNumThreads(1);

      _ocrSession = OrtSession.fromFile(
        File(_ocrModelPath!),
        ocrOptions,
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
      // Decode image
      final image = img.decodeImage(Uint8List.fromList(imageBytes));
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Step 1: License plate detection
      final detections = await _detectPlates(image);
      if (detections.isEmpty) {
        return [];
      }

      // Step 2: OCR on detected plates
      final results = <PlateResult>[];
      for (int i = 0; i < detections.length && i < topN; i++) {
        final detection = detections[i];
        final plateText = await _recognizeText(image, detection);

        if (plateText.isNotEmpty) {
          results.add(PlateResult(
            plateNumber: plateText,
            confidence: detection['confidence'] ?? 0.0,
            matchesTemplate: 1,
            plateIndex: i,
            region: region.isNotEmpty ? region : 'unknown',
            regionConfidence: 100,
            processingTimeMs: 0.0, // TODO: Add timing
            requestedTopN: topN,
            coordinates: _parseCoordinates(detection),
            candidates: [], // TODO: Add candidate support
          ));
        }
      }

      return results;
    } catch (e) {
      print('Error recognizing plates from bytes: $e');
      return [];
    }
  }

  /// Detect license plates using YOLOv9 model
  Future<List<Map<String, dynamic>>> _detectPlates(img.Image image) async {
    if (_detectorSession == null) return [];

    try {
      // Preprocess image for YOLOv9 (384x384)
      final resized = img.copyResize(image, width: 384, height: 384);
      final inputTensor = _imageToTensor(resized);

      // Run detection
      final inputs = {'images': OrtValueTensor.createTensorWithDataList(
        inputTensor,
        [1, 3, 384, 384],
      )};

      final outputs = await _detectorSession!.runAsync(
        OrtRunOptions(),
        inputs,
      );

      // Parse detection results
      final detections = _parseDetectionOutput(outputs);

      // Release tensors
      for (final input in inputs.values) {
        input.release();
      }
      for (final output in outputs.values) {
        output.release();
      }

      return detections;
    } catch (e) {
      print('Error in plate detection: $e');
      return [];
    }
  }

  /// Recognize text from detected plate region
  Future<String> _recognizeText(img.Image image, Map<String, dynamic> detection) async {
    if (_ocrSession == null) return '';

    try {
      // Crop plate region from image
      final x1 = (detection['x1'] as double).round();
      final y1 = (detection['y1'] as double).round();
      final x2 = (detection['x2'] as double).round();
      final y2 = (detection['y2'] as double).round();

      final cropped = img.copyCrop(
        image,
        x: x1,
        y: y1,
        width: x2 - x1,
        height: y2 - y1,
      );

      // Preprocess for OCR model (typically 128x32)
      final resized = img.copyResize(cropped, width: 128, height: 32);
      final inputTensor = _imageToTensor(resized);

      // Run OCR
      final inputs = {'input': OrtValueTensor.createTensorWithDataList(
        inputTensor,
        [1, 3, 32, 128],
      )};

      final outputs = await _ocrSession!.runAsync(
        OrtRunOptions(),
        inputs,
      );

      // Parse OCR results
      final plateText = _parseOCROutput(outputs);

      // Release tensors
      for (final input in inputs.values) {
        input.release();
      }
      for (final output in outputs.values) {
        output.release();
      }

      return plateText;
    } catch (e) {
      print('Error in text recognition: $e');
      return '';
    }
  }

  /// Convert image to tensor for ONNX input
  List<double> _imageToTensor(img.Image image) {
    final tensor = <double>[];

    // Normalize pixel values to [0, 1] and arrange in CHW format
    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          late double value;

          if (c == 0) value = pixel.r / 255.0; // Red
          else if (c == 1) value = pixel.g / 255.0; // Green
          else value = pixel.b / 255.0; // Blue

          tensor.add(value);
        }
      }
    }

    return tensor;
  }

  /// Parse YOLO detection output
  List<Map<String, dynamic>> _parseDetectionOutput(Map<String, OrtValue?> outputs) {
    // Simplified detection parsing - would need to match actual YOLO output format
    final detections = <Map<String, dynamic>>[];

    // This is a placeholder implementation
    // Real implementation would parse the YOLO output format
    // and apply NMS (Non-Maximum Suppression)

    return detections;
  }

  /// Parse OCR output to text
  String _parseOCROutput(Map<String, OrtValue?> outputs) {
    // Simplified OCR parsing - would need to match actual model output
    // Real implementation would decode the OCR model output to text
    return '';
  }

  /// Parse detection coordinates to Coordinate objects
  List<Coordinate> _parseCoordinates(Map<String, dynamic> detection) {
    final x1 = detection['x1'] as double? ?? 0.0;
    final y1 = detection['y1'] as double? ?? 0.0;
    final x2 = detection['x2'] as double? ?? 0.0;
    final y2 = detection['y2'] as double? ?? 0.0;

    return [
      Coordinate(x: x1.round(), y: y1.round()),
      Coordinate(x: x2.round(), y: y1.round()),
      Coordinate(x: x2.round(), y: y2.round()),
      Coordinate(x: x1.round(), y: y2.round()),
    ];
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