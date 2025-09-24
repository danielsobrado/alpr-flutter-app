import '../models/plate_result.dart';

/// Abstract interface for ALPR service implementations
abstract class ALPRServiceInterface {
  /// Initialize the ALPR service
  Future<void> initialize();

  /// Check if the service is initialized
  bool get isInitialized;

  /// Recognize license plates from image file
  Future<List<PlateResult>> recognizePlatesFromFile({
    required String imagePath,
    String country = 'us',
    String region = '',
    int topN = 10,
  });

  /// Recognize license plates from image bytes
  Future<List<PlateResult>> recognizePlatesFromBytes({
    required List<int> imageBytes,
    String country = 'us',
    String region = '',
    int topN = 10,
  });

  /// Dispose and cleanup resources
  void dispose();

  /// Get service-specific configuration options
  Map<String, dynamic> getConfiguration();

  /// Update service configuration
  Future<void> updateConfiguration(Map<String, dynamic> config);
}