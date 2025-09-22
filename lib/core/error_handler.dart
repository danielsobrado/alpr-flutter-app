import 'package:flutter/services.dart';
import 'constants.dart';
import 'logger.dart';

// Custom exception classes
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException(this.message, {this.code, this.originalError, this.stackTrace});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError, super.stackTrace});
}

class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError, super.stackTrace});
}

class CameraException extends AppException {
  CameraException(super.message, {super.code, super.originalError, super.stackTrace});
}

class StorageException extends AppException {
  StorageException(super.message, {super.code, super.originalError, super.stackTrace});
}

class OpenALPRException extends AppException {
  OpenALPRException(super.message, {super.code, super.originalError, super.stackTrace});
}

// Firestore/Firebase-specific exceptions removed for ALPR-only mode

// Generic concrete exception for non-specific errors
class GenericAppException extends AppException {
  GenericAppException(super.message, {super.code, super.originalError, super.stackTrace});
}

class ValidationException extends AppException {
  final Map<String, String> fieldErrors;
  
  ValidationException(super.message, this.fieldErrors, {super.code, super.originalError, super.stackTrace});
}

// Error handling utility
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Handle and convert various error types to user-friendly exceptions
  AppException handleError(dynamic error, [StackTrace? stackTrace]) {
    logger.e('Handling error: ${error.runtimeType}', error, stackTrace);

    switch (error.runtimeType) {
      case PlatformException:
        return _handlePlatformException(error as PlatformException, stackTrace);
      case FormatException:
        return ValidationException(
          'Invalid data format: ${error.message}',
          {},
          originalError: error,
          stackTrace: stackTrace,
        );
      case AppException:
        return error as AppException;
      default:
        return GenericAppException(
          AppConstants.genericError,
          originalError: error,
          stackTrace: stackTrace,
        );
    }
  }

  AppException _handlePlatformException(PlatformException error, StackTrace? stackTrace) {
    String message;
    
    switch (error.code) {
      case 'camera_access_denied':
      case 'PERMISSION_DENIED':
        message = 'Camera permission denied. Please grant camera access in settings.';
        return CameraException(message, code: error.code, originalError: error, stackTrace: stackTrace);
        
      case 'camera_not_available':
        message = 'Camera not available on this device.';
        return CameraException(message, code: error.code, originalError: error, stackTrace: stackTrace);
        
      case 'storage_access_denied':
        message = 'Storage permission denied. Please grant storage access in settings.';
        return StorageException(message, code: error.code, originalError: error, stackTrace: stackTrace);
        
      case 'INIT_ERROR':
        message = 'Failed to initialize OpenALPR. Please restart the app.';
        return OpenALPRException(message, code: error.code, originalError: error, stackTrace: stackTrace);
        
      case 'NOT_INITIALIZED':
        message = 'OpenALPR not properly initialized.';
        return OpenALPRException(message, code: error.code, originalError: error, stackTrace: stackTrace);
        
      case 'RECOGNITION_ERROR':
        message = 'License plate recognition failed. Please try again.';
        return OpenALPRException(message, code: error.code, originalError: error, stackTrace: stackTrace);
        
      case 'INVALID_ARGS':
        message = 'Invalid parameters provided.';
        return ValidationException(message, {}, code: error.code, originalError: error, stackTrace: stackTrace);
        
      case 'network_error':
        message = AppConstants.networkError;
        return NetworkException(message, code: error.code, originalError: error, stackTrace: stackTrace);
        
      default:
        message = error.message ?? AppConstants.genericError;
        return GenericAppException(message, code: error.code, originalError: error, stackTrace: stackTrace);
    }
  }

  /// Validate note input
  ValidationException? validateNote(String note, String? location) {
    final fieldErrors = <String, String>{};
    
    if (note.trim().isEmpty) {
      fieldErrors['note'] = 'Note cannot be empty';
    } else if (note.length < AppConstants.minNoteLength) {
      fieldErrors['note'] = 'Note must be at least ${AppConstants.minNoteLength} character(s)';
    } else if (note.length > AppConstants.maxNoteLength) {
      fieldErrors['note'] = 'Note cannot exceed ${AppConstants.maxNoteLength} characters';
    }
    
    if (location != null && location.length > AppConstants.maxLocationLength) {
      fieldErrors['location'] = 'Location cannot exceed ${AppConstants.maxLocationLength} characters';
    }
    
    // Check for potential injection attacks
    if (_containsSuspiciousContent(note) || (location != null && _containsSuspiciousContent(location))) {
      fieldErrors['security'] = 'Invalid characters detected';
      logger.security('Suspicious content detected in note/location input', context: {
        'note_length': note.length,
        'location_length': location?.length ?? 0,
      });
    }
    
    if (fieldErrors.isNotEmpty) {
      return ValidationException('Validation failed', fieldErrors);
    }
    
    return null;
  }

  /// Validate plate number format
  bool isValidPlateNumber(String plateNumber) {
    if (plateNumber.length < AppConstants.minPlateCharacters || 
        plateNumber.length > AppConstants.maxPlateCharacters) {
      return false;
    }
    
    // Allow alphanumeric characters, spaces, and common plate separators
    final plateRegex = RegExp(r'^[A-Z0-9\s\-]+$');
    return plateRegex.hasMatch(plateNumber.toUpperCase());
  }

  /// Check for suspicious content that might indicate injection attacks
  bool _containsSuspiciousContent(String content) {
    final suspiciousPatterns = [
      r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
      r'javascript:',
      r'data:text\/html',
      r'vbscript:',
      r'onload\s*=',
      r'onerror\s*=',
      r'eval\s*\(',
      r'setTimeout\s*\(',
      r'setInterval\s*\(',
    ];
    
    for (final pattern in suspiciousPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(content)) {
        return true;
      }
    }
    
    return false;
  }
}

// Global error handler instance
final errorHandler = ErrorHandler();

// Utility functions for common error handling patterns
Future<T> safeExecute<T>(
  Future<T> Function() operation, {
  String? context,
  T? fallback,
  bool shouldRethrow = true,
}) async {
  try {
    logger.d('Executing operation: $context');
    final result = await operation();
    logger.d('Operation completed successfully: $context');
    return result;
  } catch (error, stackTrace) {
    final appException = errorHandler.handleError(error, stackTrace);
    logger.e('Operation failed: $context', appException, stackTrace);
    
    if (shouldRethrow) {
      throw appException;
    } else if (fallback != null) {
      return fallback;
    } else {
      throw appException;
    }
  }
}

T? safeExecuteSync<T>(
  T Function() operation, {
  String? context,
  T? fallback,
  bool shouldRethrow = false,
}) {
  try {
    logger.d('Executing sync operation: $context');
    final result = operation();
    logger.d('Sync operation completed successfully: $context');
    return result;
  } catch (error, stackTrace) {
    final appException = errorHandler.handleError(error, stackTrace);
    logger.e('Sync operation failed: $context', appException, stackTrace);
    
    if (shouldRethrow) {
      throw appException;
    }
    return fallback;
  }
}
