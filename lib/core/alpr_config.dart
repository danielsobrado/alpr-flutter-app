enum ALPRProvider {
  openalpr,
  fastalpr,
}

class ALPRConfig {
  // Default settings
  static const ALPRProvider defaultProvider = ALPRProvider.openalpr;

  // Current configuration
  static ALPRProvider _currentProvider = defaultProvider;

  // Getters
  static ALPRProvider get currentProvider => _currentProvider;

  // Provider configuration
  static void setProvider(ALPRProvider provider) {
    _currentProvider = provider;
  }

  // Configuration display names
  static String getProviderDisplayName(ALPRProvider provider) {
    switch (provider) {
      case ALPRProvider.openalpr:
        return 'OpenALPR (Native)';
      case ALPRProvider.fastalpr:
        return 'FastALPR (ONNX)';
    }
  }

  // Configuration descriptions
  static String getProviderDescription(ALPRProvider provider) {
    switch (provider) {
      case ALPRProvider.openalpr:
        return 'Native OpenALPR library with local processing';
      case ALPRProvider.fastalpr:
        return 'Fast-ALPR with ONNX Runtime and YOLOv9 models';
    }
  }

  // Provider capabilities
  static Map<String, bool> getProviderCapabilities(ALPRProvider provider) {
    switch (provider) {
      case ALPRProvider.openalpr:
        return {
          'local_processing': true,
          'real_time': true,
          'region_specific': true,
          'confidence_scores': true,
          'bounding_boxes': true,
        };
      case ALPRProvider.fastalpr:
        return {
          'local_processing': true,
          'real_time': true,
          'yolo_detection': true,
          'advanced_ocr': true,
          'confidence_scores': true,
          'bounding_boxes': true,
        };
    }
  }
}