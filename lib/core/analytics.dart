import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'constants.dart';
import 'logger.dart';

class AppAnalytics {
  static final AppAnalytics _instance = AppAnalytics._internal();
  factory AppAnalytics() => _instance;
  AppAnalytics._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized || !AppConfig.enableAnalytics) return;

    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    
    // Set up crash reporting
    if (AppConfig.enableCrashlytics) {
      _crashlytics.setCrashlyticsCollectionEnabled(true);
    }

    _isInitialized = true;
    logger.i('AppAnalytics initialized');
  }

  /// Track user sign in
  Future<void> trackUserSignIn(String method) async {
    if (!_isInitialized || !AppConfig.enableAnalytics) return;

    try {
      await _analytics.logEvent(
        name: AppConstants.userSignedInEvent,
        parameters: {
          'method': method,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      logger.userAction('User signed in', parameters: {'method': method});
    } catch (e) {
      logger.e('Failed to track user sign in', e);
    }
  }

  /// Track user sign out
  Future<void> trackUserSignOut() async {
    if (!_isInitialized || !AppConfig.enableAnalytics) return;

    try {
      await _analytics.logEvent(
        name: AppConstants.userSignedOutEvent,
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      logger.userAction('User signed out');
    } catch (e) {
      logger.e('Failed to track user sign out', e);
    }
  }

  /// Track license plate detection
  Future<void> trackPlateDetected({
    required String plateNumber,
    required double confidence,
    required String region,
    required Duration processingTime,
    required int plateCount,
  }) async {
    if (!_isInitialized || !AppConfig.enableAnalytics) return;

    try {
      await _analytics.logEvent(
        name: AppConstants.plateDetectedEvent,
        parameters: {
          'confidence': confidence.round(),
          'region': region,
          'processing_time_ms': processingTime.inMilliseconds,
          'plate_count': plateCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      logger.userAction('Plate detected', parameters: {
        'plateNumber': _maskPlateNumber(plateNumber),
        'confidence': confidence,
        'region': region,
        'processingTime': processingTime.inMilliseconds,
      });
    } catch (e) {
      logger.e('Failed to track plate detection', e);
    }
  }

  /// Track note addition
  Future<void> trackNoteAdded({
    required String plateNumber,
    required int noteLength,
    required bool hasLocation,
  }) async {
    if (!_isInitialized || !AppConfig.enableAnalytics) return;

    try {
      await _analytics.logEvent(
        name: AppConstants.noteAddedEvent,
        parameters: {
          'note_length': noteLength,
          'has_location': hasLocation,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      logger.userAction('Note added', parameters: {
        'plateNumber': _maskPlateNumber(plateNumber),
        'noteLength': noteLength,
        'hasLocation': hasLocation,
      });
    } catch (e) {
      logger.e('Failed to track note addition', e);
    }
  }

  /// Track camera errors
  Future<void> trackCameraError(String errorCode, String errorMessage) async {
    if (!_isInitialized || !AppConfig.enableAnalytics) return;

    try {
      await _analytics.logEvent(
        name: AppConstants.cameraErrorEvent,
        parameters: {
          'error_code': errorCode,
          'error_type': 'camera',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      logger.w('Camera error tracked', {
        'errorCode': errorCode,
        'errorMessage': errorMessage,
      });
    } catch (e) {
      logger.e('Failed to track camera error', e);
    }
  }

  /// Track OpenALPR errors
  Future<void> trackOpenAlprError(String errorCode, String errorMessage) async {
    if (!_isInitialized || !AppConfig.enableAnalytics) return;

    try {
      await _analytics.logEvent(
        name: AppConstants.openAlprErrorEvent,
        parameters: {
          'error_code': errorCode,
          'error_type': 'openalpr',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      logger.w('OpenALPR error tracked', {
        'errorCode': errorCode,
        'errorMessage': errorMessage,
      });
    } catch (e) {
      logger.e('Failed to track OpenALPR error', e);
    }
  }

  /// Track Firestore errors
  Future<void> trackFirestoreError(String operation, String errorCode) async {
    if (!_isInitialized || !AppConfig.enableAnalytics) return;

    try {
      await _analytics.logEvent(
        name: AppConstants.firestoreErrorEvent,
        parameters: {
          'operation': operation,
          'error_code': errorCode,
          'error_type': 'firestore',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      logger.w('Firestore error tracked', {
        'operation': operation,
        'errorCode': errorCode,
      });
    } catch (e) {
      logger.e('Failed to track Firestore error', e);
    }
  }

  /// Track app performance metrics
  Future<void> trackPerformance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized || !AppConfig.enableAnalytics) return;

    try {
      final parameters = <String, dynamic>{
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (additionalData != null) {
        parameters.addAll(additionalData);
      }

      await _analytics.logEvent(
        name: 'performance_metric',
        parameters: parameters,
      );
      
      logger.performance(operation, duration, metadata: additionalData);
    } catch (e) {
      logger.e('Failed to track performance metric', e);
    }
  }

  /// Set user properties
  Future<void> setUserProperties({
    required String userId,
    String? userType,
    int? totalNotes,
    int? totalDetections,
  }) async {
    if (!_isInitialized || !AppConfig.enableAnalytics) return;

    try {
      await _analytics.setUserId(id: userId);
      
      if (userType != null) {
        await _analytics.setUserProperty(name: 'user_type', value: userType);
      }
      
      if (totalNotes != null) {
        await _analytics.setUserProperty(name: 'total_notes', value: totalNotes.toString());
      }
      
      if (totalDetections != null) {
        await _analytics.setUserProperty(name: 'total_detections', value: totalDetections.toString());
      }
      
      logger.i('User properties set', {
        'userId': userId.substring(0, 8) + '***', // Mask for privacy
        'userType': userType,
        'totalNotes': totalNotes,
        'totalDetections': totalDetections,
      });
    } catch (e) {
      logger.e('Failed to set user properties', e);
    }
  }

  /// Record custom error for Crashlytics
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (!_isInitialized || !AppConfig.enableCrashlytics) return;

    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
      
      logger.e('Error recorded to Crashlytics', exception, stackTrace);
    } catch (e) {
      logger.e('Failed to record error to Crashlytics', e);
    }
  }

  /// Set crash keys for better debugging
  void setCrashKeys(Map<String, dynamic> keys) {
    if (!_isInitialized || !AppConfig.enableCrashlytics) return;

    try {
      for (final entry in keys.entries) {
        _crashlytics.setCustomKey(entry.key, entry.value);
      }
      
      logger.d('Crash keys set', keys);
    } catch (e) {
      logger.e('Failed to set crash keys', e);
    }
  }

  /// Mask plate number for privacy (show first 2 and last 2 characters)
  String _maskPlateNumber(String plateNumber) {
    if (plateNumber.length <= 4) {
      return plateNumber.replaceRange(1, plateNumber.length - 1, '*' * (plateNumber.length - 2));
    } else {
      return plateNumber.substring(0, 2) + '*' * (plateNumber.length - 4) + plateNumber.substring(plateNumber.length - 2);
    }
  }
}

// Global analytics instance
final analytics = AppAnalytics();