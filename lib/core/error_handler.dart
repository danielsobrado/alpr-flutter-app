import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class FirestoreException extends AppException {
  FirestoreException(super.message, {super.code, super.originalError, super.stackTrace});
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
      case FirebaseAuthException:
        return _handleFirebaseAuthException(error as FirebaseAuthException, stackTrace);
      case FirebaseException:
        return _handleFirebaseException(error as FirebaseException, stackTrace);
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
        return AppException(
          AppConstants.genericError,
          originalError: error,
          stackTrace: stackTrace,
        );
    }
  }

  AuthException _handleFirebaseAuthException(FirebaseAuthException error, StackTrace? stackTrace) {
    String message;
    
    switch (error.code) {
      case 'user-not-found':
        message = 'No account found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email address.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please choose a stronger password.';
        break;
      case 'invalid-email':
        message = 'Invalid email address format.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Contact support for assistance.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your internet connection.';
        break;
      case 'account-exists-with-different-credential':
        message = 'An account already exists with this email using a different sign-in method.';
        break;
      default:
        message = error.message ?? AppConstants.authError;
    }

    return AuthException(
      message,
      code: error.code,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  AppException _handleFirebaseException(FirebaseException error, StackTrace? stackTrace) {
    String message;
    
    switch (error.code) {
      case 'permission-denied':
        message = 'Access denied. Please check your permissions.';
        break;
      case 'not-found':
        message = 'Requested data not found.';
        break;
      case 'already-exists':
        message = 'Data already exists.';
        break;
      case 'resource-exhausted':
        message = 'Service temporarily unavailable. Please try again later.';
        break;
      case 'failed-precondition':
        message = 'Operation cannot be completed in current state.';
        break;
      case 'aborted':
        message = 'Operation was aborted. Please try again.';
        break;
      case 'out-of-range':
        message = 'Invalid input range.';
        break;
      case 'unimplemented':
        message = 'Feature not available.';
        break;
      case 'internal':
        message = 'Internal server error. Please try again.';
        break;
      case 'unavailable':
        message = 'Service temporarily unavailable.';
        break;
      case 'data-loss':
        message = 'Data corruption detected. Please contact support.';
        break;
      case 'unauthenticated':
        message = 'Authentication required. Please sign in.';
        break;
      default:
        message = error.message ?? AppConstants.firestoreError;
    }

    return FirestoreException(
      message,
      code: error.code,
      originalError: error,
      stackTrace: stackTrace,
    );
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
        return AppException(message, code: error.code, originalError: error, stackTrace: stackTrace);
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
  bool rethrow = true,
}) async {
  try {
    logger.d('Executing operation: $context');
    final result = await operation();
    logger.d('Operation completed successfully: $context');
    return result;
  } catch (error, stackTrace) {
    final appException = errorHandler.handleError(error, stackTrace);
    logger.e('Operation failed: $context', appException, stackTrace);
    
    if (rethrow) {
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
  bool rethrow = false,
}) {
  try {
    logger.d('Executing sync operation: $context');
    final result = operation();
    logger.d('Sync operation completed successfully: $context');
    return result;
  } catch (error, stackTrace) {
    final appException = errorHandler.handleError(error, stackTrace);
    logger.e('Sync operation failed: $context', appException, stackTrace);
    
    if (rethrow) {
      throw appException;
    }
    return fallback;
  }
}