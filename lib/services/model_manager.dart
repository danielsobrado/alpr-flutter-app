import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Represents an available ONNX model for download
class ONNXModel {
  final String id;
  final String name;
  final String description;
  final String downloadUrl;
  final int fileSizeBytes;
  final String filename;
  final ModelType type;
  final Map<String, dynamic> metadata;

  const ONNXModel({
    required this.id,
    required this.name,
    required this.description,
    required this.downloadUrl,
    required this.fileSizeBytes,
    required this.filename,
    required this.type,
    this.metadata = const {},
  });

  String get fileSizeMB => (fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
}

enum ModelType { detector, ocr }

enum ModelDownloadStatus { notDownloaded, downloading, downloaded, error }

class ModelDownloadProgress {
  final String modelId;
  final int downloadedBytes;
  final int totalBytes;
  final ModelDownloadStatus status;
  final String? error;

  const ModelDownloadProgress({
    required this.modelId,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.status,
    this.error,
  });

  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
  String get progressPercent => (progress * 100).toStringAsFixed(1);
}

/// Manages ONNX model downloads and storage
class ModelManager extends ChangeNotifier {
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  final Map<String, ModelDownloadProgress> _downloadProgress = {};
  late final Directory _modelsDirectory;
  bool _isInitialized = false;

  // Available models catalog - Models currently unavailable for public download
  static const List<ONNXModel> _availableModels = [
    // Detection Models - Would need actual Fast-ALPR models
    ONNXModel(
      id: 'yolo_v9_384',
      name: 'YOLOv9 License Plate Detection',
      description: 'Professional license plate detection model (Not available in demo)',
      downloadUrl: 'https://example.com/models-not-available', // Disabled
      fileSizeBytes: 6 * 1024 * 1024,
      filename: 'yolo-v9-t-384-license-plate.onnx',
      type: ModelType.detector,
      metadata: {
        'inputSize': [384, 384],
        'accuracy': 'High',
        'speed': 'Fast',
        'architecture': 'YOLOv9',
        'note': 'Requires Fast-ALPR subscription or training custom models',
        'available': false,
      },
    ),

    // OCR Models - Would need actual Fast-Plate-OCR models  
    ONNXModel(
      id: 'cct_global',
      name: 'CCT License Plate OCR',
      description: 'Professional license plate text recognition (Not available in demo)',
      downloadUrl: 'https://example.com/models-not-available', // Disabled
      fileSizeBytes: 8 * 1024 * 1024,
      filename: 'cct-global-license-plate.onnx',
      type: ModelType.ocr,
      metadata: {
        'regions': ['global'],
        'accuracy': 'High',
        'speed': 'Fast',
        'architecture': 'CCT',
        'note': 'Requires Fast-Plate-OCR subscription or training custom models',
        'available': false,
      },
    ),
  ];

  // Getters
  List<ONNXModel> get availableModels => _availableModels;
  List<ONNXModel> get detectorModels => _availableModels.where((m) => m.type == ModelType.detector).toList();
  List<ONNXModel> get ocrModels => _availableModels.where((m) => m.type == ModelType.ocr).toList();
  Map<String, ModelDownloadProgress> get downloadProgress => Map.unmodifiable(_downloadProgress);

  /// Initialize the model manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    final documentsDir = await getApplicationDocumentsDirectory();
    _modelsDirectory = Directory(path.join(documentsDir.path, 'onnx_models'));

    if (!await _modelsDirectory.exists()) {
      await _modelsDirectory.create(recursive: true);
    }

    // Initialize download progress for all models
    for (final model in _availableModels) {
      final isDownloaded = await isModelDownloaded(model.id);
      _downloadProgress[model.id] = ModelDownloadProgress(
        modelId: model.id,
        downloadedBytes: isDownloaded ? model.fileSizeBytes : 0,
        totalBytes: model.fileSizeBytes,
        status: isDownloaded ? ModelDownloadStatus.downloaded : ModelDownloadStatus.notDownloaded,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Check if a model is downloaded
  Future<bool> isModelDownloaded(String modelId) async {
    final model = _availableModels.firstWhere((m) => m.id == modelId);
    final modelFile = File(path.join(_modelsDirectory.path, model.filename));

    if (!await modelFile.exists()) return false;

    // Verify file size matches expected
    final fileSize = await modelFile.length();
    return fileSize == model.fileSizeBytes;
  }

  /// Get the file path for a downloaded model
  Future<String?> getModelPath(String modelId) async {
    if (!await isModelDownloaded(modelId)) return null;

    final model = _availableModels.firstWhere((m) => m.id == modelId);
    return path.join(_modelsDirectory.path, model.filename);
  }

  /// Download a model
  Future<void> downloadModel(String modelId, {Function(ModelDownloadProgress)? onProgress}) async {
    final model = _availableModels.firstWhere((m) => m.id == modelId);
    final modelFile = File(path.join(_modelsDirectory.path, model.filename));

    // Check if already downloaded
    if (await isModelDownloaded(modelId)) {
      _downloadProgress[modelId] = ModelDownloadProgress(
        modelId: modelId,
        downloadedBytes: model.fileSizeBytes,
        totalBytes: model.fileSizeBytes,
        status: ModelDownloadStatus.downloaded,
      );
      notifyListeners();
      return;
    }

    try {
      // Update status to downloading
      _downloadProgress[modelId] = ModelDownloadProgress(
        modelId: modelId,
        downloadedBytes: 0,
        totalBytes: model.fileSizeBytes,
        status: ModelDownloadStatus.downloading,
      );
      notifyListeners();
      onProgress?.call(_downloadProgress[modelId]!);

      // Start download
      final request = http.Request('GET', Uri.parse(model.downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download model: HTTP ${response.statusCode}');
      }

      // Create file and stream download
      final fileSink = modelFile.openWrite();
      int downloadedBytes = 0;

      await response.stream.listen((chunk) {
        fileSink.add(chunk);
        downloadedBytes += chunk.length;

        // Update progress
        final progress = ModelDownloadProgress(
          modelId: modelId,
          downloadedBytes: downloadedBytes,
          totalBytes: model.fileSizeBytes,
          status: ModelDownloadStatus.downloading,
        );
        _downloadProgress[modelId] = progress;
        notifyListeners();
        onProgress?.call(progress);
      }).asFuture();

      await fileSink.close();

      // Verify download
      final actualSize = await modelFile.length();
      if (actualSize != model.fileSizeBytes) {
        await modelFile.delete();
        throw Exception('Downloaded file size mismatch. Expected ${model.fileSizeBytes}, got $actualSize');
      }

      // Update status to completed
      _downloadProgress[modelId] = ModelDownloadProgress(
        modelId: modelId,
        downloadedBytes: model.fileSizeBytes,
        totalBytes: model.fileSizeBytes,
        status: ModelDownloadStatus.downloaded,
      );
      notifyListeners();
      onProgress?.call(_downloadProgress[modelId]!);

    } catch (e) {
      // Update status to error
      _downloadProgress[modelId] = ModelDownloadProgress(
        modelId: modelId,
        downloadedBytes: 0,
        totalBytes: model.fileSizeBytes,
        status: ModelDownloadStatus.error,
        error: e.toString(),
      );
      notifyListeners();
      onProgress?.call(_downloadProgress[modelId]!);
      rethrow;
    }
  }

  /// Delete a downloaded model
  Future<void> deleteModel(String modelId) async {
    final model = _availableModels.firstWhere((m) => m.id == modelId);
    final modelFile = File(path.join(_modelsDirectory.path, model.filename));

    if (await modelFile.exists()) {
      await modelFile.delete();
    }

    _downloadProgress[modelId] = ModelDownloadProgress(
      modelId: modelId,
      downloadedBytes: 0,
      totalBytes: model.fileSizeBytes,
      status: ModelDownloadStatus.notDownloaded,
    );
    notifyListeners();
  }

  /// Get downloaded models by type
  Future<List<ONNXModel>> getDownloadedModels(ModelType type) async {
    final models = <ONNXModel>[];

    for (final model in _availableModels.where((m) => m.type == type)) {
      if (await isModelDownloaded(model.id)) {
        models.add(model);
      }
    }

    return models;
  }

  /// Get total storage used by downloaded models
  Future<double> getTotalStorageUsedMB() async {
    double totalMB = 0;

    for (final model in _availableModels) {
      if (await isModelDownloaded(model.id)) {
        totalMB += double.parse(model.fileSizeMB);
      }
    }

    return totalMB;
  }

  /// Clear all downloaded models
  Future<void> clearAllModels() async {
    for (final model in _availableModels) {
      if (await isModelDownloaded(model.id)) {
        await deleteModel(model.id);
      }
    }
  }
}