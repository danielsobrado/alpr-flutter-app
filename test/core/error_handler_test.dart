import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:alpr_flutter_app/core/error_handler.dart';
import 'package:alpr_flutter_app/core/constants.dart';

void main() {
  group('ErrorHandler', () {
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler();
    });

    group('handleError', () {
      test('should handle FirebaseAuthException correctly', () {
        // Arrange
        final authException = FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user record found',
        );

        // Act
        final result = errorHandler.handleError(authException);

        // Assert
        expect(result, isA<AuthException>());
        expect(result.message, 'No account found with this email address.');
        expect(result.code, 'user-not-found');
      });

      test('should handle PlatformException for camera errors', () {
        // Arrange
        final platformException = PlatformException(
          code: 'camera_access_denied',
          message: 'Camera permission denied',
        );

        // Act
        final result = errorHandler.handleError(platformException);

        // Assert
        expect(result, isA<CameraException>());
        expect(result.message, 'Camera permission denied. Please grant camera access in settings.');
        expect(result.code, 'camera_access_denied');
      });

      test('should handle PlatformException for OpenALPR errors', () {
        // Arrange
        final platformException = PlatformException(
          code: 'RECOGNITION_ERROR',
          message: 'Failed to recognize plate',
        );

        // Act
        final result = errorHandler.handleError(platformException);

        // Assert
        expect(result, isA<OpenALPRException>());
        expect(result.message, 'License plate recognition failed. Please try again.');
        expect(result.code, 'RECOGNITION_ERROR');
      });

      test('should handle generic errors', () {
        // Arrange
        final genericError = Exception('Something went wrong');

        // Act
        final result = errorHandler.handleError(genericError);

        // Assert
        expect(result, isA<AppException>());
        expect(result.message, AppConstants.genericError);
        expect(result.originalError, genericError);
      });

      test('should pass through AppException unchanged', () {
        // Arrange
        final appException = ValidationException('Invalid input', {});

        // Act
        final result = errorHandler.handleError(appException);

        // Assert
        expect(result, same(appException));
      });
    });

    group('validateNote', () {
      test('should return null for valid note', () {
        // Arrange
        const validNote = 'This is a valid note about the license plate';
        const validLocation = 'Main Street, Downtown';

        // Act
        final result = errorHandler.validateNote(validNote, validLocation);

        // Assert
        expect(result, isNull);
      });

      test('should return error for empty note', () {
        // Arrange
        const emptyNote = '';

        // Act
        final result = errorHandler.validateNote(emptyNote, null);

        // Assert
        expect(result, isA<ValidationException>());
        expect(result!.fieldErrors['note'], 'Note cannot be empty');
      });

      test('should return error for note too long', () {
        // Arrange
        final longNote = 'a' * (AppConstants.maxNoteLength + 1);

        // Act
        final result = errorHandler.validateNote(longNote, null);

        // Assert
        expect(result, isA<ValidationException>());
        expect(result!.fieldErrors['note'], 'Note cannot exceed ${AppConstants.maxNoteLength} characters');
      });

      test('should return error for location too long', () {
        // Arrange
        const validNote = 'Valid note';
        final longLocation = 'a' * (AppConstants.maxLocationLength + 1);

        // Act
        final result = errorHandler.validateNote(validNote, longLocation);

        // Assert
        expect(result, isA<ValidationException>());
        expect(result!.fieldErrors['location'], 'Location cannot exceed ${AppConstants.maxLocationLength} characters');
      });

      test('should detect suspicious content in note', () {
        // Arrange
        const suspiciousNote = 'Valid note <script>alert("xss")</script>';

        // Act
        final result = errorHandler.validateNote(suspiciousNote, null);

        // Assert
        expect(result, isA<ValidationException>());
        expect(result!.fieldErrors['security'], 'Invalid characters detected');
      });

      test('should detect suspicious content in location', () {
        // Arrange
        const validNote = 'Valid note';
        const suspiciousLocation = 'Location javascript:void(0)';

        // Act
        final result = errorHandler.validateNote(validNote, suspiciousLocation);

        // Assert
        expect(result, isA<ValidationException>());
        expect(result!.fieldErrors['security'], 'Invalid characters detected');
      });
    });

    group('isValidPlateNumber', () {
      test('should return true for valid US plate format', () {
        // Arrange
        const validPlate = 'ABC123';

        // Act
        final result = errorHandler.isValidPlateNumber(validPlate);

        // Assert
        expect(result, isTrue);
      });

      test('should return true for valid plate with spaces', () {
        // Arrange
        const validPlate = 'AB 123';

        // Act
        final result = errorHandler.isValidPlateNumber(validPlate);

        // Assert
        expect(result, isTrue);
      });

      test('should return true for valid plate with dashes', () {
        // Arrange
        const validPlate = 'AB-123';

        // Act
        final result = errorHandler.isValidPlateNumber(validPlate);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for plate too short', () {
        // Arrange
        const shortPlate = 'AB';

        // Act
        final result = errorHandler.isValidPlateNumber(shortPlate);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for plate too long', () {
        // Arrange
        const longPlate = 'ABCDEFGHIJK';

        // Act
        final result = errorHandler.isValidPlateNumber(longPlate);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for plate with invalid characters', () {
        // Arrange
        const invalidPlate = 'ABC@123';

        // Act
        final result = errorHandler.isValidPlateNumber(invalidPlate);

        // Assert
        expect(result, isFalse);
      });
    });
  });

  group('safeExecute', () {
    test('should return result when operation succeeds', () async {
      // Arrange
      Future<String> successfulOperation() async {
        return 'success';
      }

      // Act
      final result = await safeExecute(successfulOperation, context: 'test operation');

      // Assert
      expect(result, 'success');
    });

    test('should throw AppException when operation fails', () async {
      // Arrange
      Future<String> failingOperation() async {
        throw Exception('Something went wrong');
      }

      // Act & Assert
      expect(
        () async => await safeExecute(failingOperation, context: 'test operation'),
        throwsA(isA<AppException>()),
      );
    });

    test('should return fallback when operation fails and rethrow is false', () async {
      // Arrange
      Future<String> failingOperation() async {
        throw Exception('Something went wrong');
      }

      // Act
      final result = await safeExecute(
        failingOperation,
        context: 'test operation',
        fallback: 'fallback',
        rethrow: false,
      );

      // Assert
      expect(result, 'fallback');
    });
  });

  group('safeExecuteSync', () {
    test('should return result when operation succeeds', () {
      // Arrange
      String successfulOperation() {
        return 'success';
      }

      // Act
      final result = safeExecuteSync(successfulOperation, context: 'test operation');

      // Assert
      expect(result, 'success');
    });

    test('should return fallback when operation fails', () {
      // Arrange
      String failingOperation() {
        throw Exception('Something went wrong');
      }

      // Act
      final result = safeExecuteSync(
        failingOperation,
        context: 'test operation',
        fallback: 'fallback',
      );

      // Assert
      expect(result, 'fallback');
    });

    test('should throw when operation fails and rethrow is true', () {
      // Arrange
      String failingOperation() {
        throw Exception('Something went wrong');
      }

      // Act & Assert
      expect(
        () => safeExecuteSync(
          failingOperation,
          context: 'test operation',
          rethrow: true,
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}