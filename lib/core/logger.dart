import 'dart:developer' as developer;
import 'package:logger/logger.dart';
import 'constants.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late Logger _logger;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;

    _logger = Logger(
      printer: AppConfig.isProduction 
          ? ProductionLogPrinter()
          : PrettyPrinter(
              methodCount: 2,
              errorMethodCount: 8,
              lineLength: 120,
              colors: true,
              printEmojis: true,
              dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
            ),
      level: AppConfig.isProduction ? Level.warning : Level.debug,
      output: ConsoleOutput(),
    );

    _isInitialized = true;
    i('AppLogger initialized');
  }

  // Debug logs (development only)
  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  // Info logs
  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.i(message, error: error, stackTrace: stackTrace);
    
    // Also log to developer console for better debugging
    developer.log(
      message, 
      name: 'ALPR_INFO',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Warning logs
  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.w(message, error: error, stackTrace: stackTrace);
    
    developer.log(
      message, 
      name: 'ALPR_WARNING',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Error logs
  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.e(message, error: error, stackTrace: stackTrace);
    
    // Crashlytics disabled in ALPR-only mode
    
    developer.log(
      message, 
      name: 'ALPR_ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Fatal logs
  void f(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) initialize();
    _logger.f(message, error: error, stackTrace: stackTrace);
    
    // Crashlytics disabled in ALPR-only mode
    
    developer.log(
      message, 
      name: 'ALPR_FATAL',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Performance logging
  void performance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    final message = '$operation completed in ${duration.inMilliseconds}ms';
    
    if (duration.inSeconds > 5) {
      w('$message (SLOW OPERATION)', metadata);
    } else {
      i(message, metadata);
    }
    
    // Log performance metrics for analysis
    if (AppConfig.enableAnalytics && metadata != null) {
      // This would integrate with Firebase Performance Monitoring
      developer.log(
        message,
        name: 'ALPR_PERFORMANCE',
      );
    }
  }

  // User action logging
  void userAction(String action, {Map<String, dynamic>? parameters}) {
    i('User action: $action', parameters);
    
    // This would integrate with Firebase Analytics
    if (AppConfig.enableAnalytics) {
      developer.log(
        'User action: $action',
        name: 'ALPR_USER_ACTION',
      );
    }
  }

  // Security logging
  void security(String event, {Map<String, dynamic>? context}) {
    w('Security event: $event', context);
    
    // Crashlytics disabled in ALPR-only mode
  }
}

// Production log printer with minimal formatting
class ProductionLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final time = DateTime.now().toIso8601String();
    final level = event.level.name.toUpperCase();
    final message = event.message;
    
    return ['[$time] [$level] $message'];
  }
}

// Global logger instance
final logger = AppLogger();
