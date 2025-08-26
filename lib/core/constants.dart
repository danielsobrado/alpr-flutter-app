class AppConstants {
  // App Information
  static const String appName = 'ALPR Scanner';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.example.alpr_flutter_app';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String plateNotesCollection = 'plate_notes';
  
  // OpenALPR Configuration
  static const String openAlprConfigFile = 'openalpr.conf';
  static const String runtimeDataPath = 'runtime_data';
  static const String openAlprChannel = 'openalpr_flutter';
  static const String defaultCountry = 'us';
  static const String defaultRegion = '';
  static const int defaultTopN = 10;
  static const double minConfidenceThreshold = 65.0;
  static const int minPlateCharacters = 4;
  static const int maxPlateCharacters = 8;
  
  // Camera Configuration
  static const int maxImageWidth = 1280;
  static const int maxImageHeight = 720;
  static const Duration cameraTimeout = Duration(seconds: 10);
  static const Duration processingTimeout = Duration(seconds: 30);
  
  // Network Configuration
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration retryDelay = Duration(seconds: 1);
  static const int maxRetryAttempts = 3;
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 4);
  static const Duration loadingTimeout = Duration(seconds: 15);
  
  // Validation Rules
  static const int minNoteLength = 1;
  static const int maxNoteLength = 1000;
  static const int maxLocationLength = 200;
  
  // Storage Keys
  static const String lastLoginKey = 'last_login';
  static const String userPreferencesKey = 'user_preferences';
  static const String cacheVersionKey = 'cache_version';
  
  // Error Messages
  static const String genericError = 'An unexpected error occurred. Please try again.';
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String authError = 'Authentication failed. Please sign in again.';
  static const String cameraError = 'Camera access error. Please check permissions.';
  static const String storageError = 'Storage access error. Please check permissions.';
  static const String openAlprError = 'Plate recognition failed. Please try again.';
  static const String firestoreError = 'Data sync error. Your changes will be saved when connection is restored.';
  
  // Analytics Events
  static const String plateDetectedEvent = 'plate_detected';
  static const String noteAddedEvent = 'note_added';
  static const String userSignedInEvent = 'user_signed_in';
  static const String userSignedOutEvent = 'user_signed_out';
  static const String cameraErrorEvent = 'camera_error';
  static const String openAlprErrorEvent = 'openalpr_error';
  static const String firestoreErrorEvent = 'firestore_error';
}

class AppConfig {
  // Environment-specific configurations
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);
  static const bool enableCrashlytics = bool.fromEnvironment('ENABLE_CRASHLYTICS', defaultValue: true);
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);
  
  // Debug configurations
  static const bool showDebugBanner = !isProduction;
  static const bool enablePerformanceMonitoring = isProduction;
  
  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableLocationTracking = true;
  static const bool enableImageCaching = true;
}

// Route names for navigation
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String allNotes = '/all_notes';
  static const String settings = '/settings';
  static const String about = '/about';
}

// Asset paths
class AppAssets {
  static const String openAlprConfig = 'assets/runtime_data/openalpr.conf';
  static const String googleLogo = 'assets/images/google_logo.png';
}

// Theme constants
class AppTheme {
  static const int primaryColorValue = 0xFF1976D2;
  static const int primaryColorDarkValue = 0xFF64B5F6;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double iconSize = 24.0;
  static const double buttonHeight = 48.0;
}