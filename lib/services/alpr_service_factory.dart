import '../core/alpr_config.dart';
import 'alpr_service_interface.dart';
import 'openalpr_service.dart';
import 'fastalpr_service.dart';

/// Factory for creating ALPR service instances
class ALPRServiceFactory {
  static ALPRServiceInterface? _currentService;

  /// Get the current ALPR service instance
  static ALPRServiceInterface getCurrentService() {
    if (_currentService != null) {
      return _currentService!;
    }

    return createService(ALPRConfig.currentProvider);
  }

  /// Create a new ALPR service instance
  static ALPRServiceInterface createService(ALPRProvider provider) {
    // Dispose previous service if exists
    _currentService?.dispose();

    switch (provider) {
      case ALPRProvider.openalpr:
        _currentService = OpenALPRService();
        break;
      case ALPRProvider.fastalpr:
        _currentService = FastALPRService();
        break;
    }

    return _currentService!;
  }

  /// Switch to a different ALPR provider
  static Future<ALPRServiceInterface> switchProvider(ALPRProvider provider) async {
    // Update configuration
    ALPRConfig.setProvider(provider);

    // Create new service instance
    final service = createService(provider);

    // Initialize the new service
    await service.initialize();

    return service;
  }

  /// Check if the current service is initialized
  static bool get isCurrentServiceInitialized {
    return _currentService?.isInitialized ?? false;
  }

  /// Initialize the current service if not already initialized
  static Future<void> initializeCurrentService() async {
    final service = getCurrentService();
    if (!service.isInitialized) {
      await service.initialize();
    }
  }

  /// Get available providers
  static List<ALPRProvider> getAvailableProviders() {
    return ALPRProvider.values;
  }

  /// Get provider capabilities comparison
  static Map<ALPRProvider, Map<String, bool>> getAllProviderCapabilities() {
    final capabilities = <ALPRProvider, Map<String, bool>>{};
    for (final provider in ALPRProvider.values) {
      capabilities[provider] = ALPRConfig.getProviderCapabilities(provider);
    }
    return capabilities;
  }

  /// Dispose all services and cleanup
  static void dispose() {
    _currentService?.dispose();
    _currentService = null;
  }
}