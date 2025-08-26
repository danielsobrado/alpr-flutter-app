import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_core/firebase_core.dart';

// Test helper functions and mocks
class TestHelpers {
  static void setupFirebaseAuthMocks() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  static Future<void> initializeFirebaseForTesting() async {
    // Mock Firebase initialization for tests
    TestWidgetsFlutterBinding.ensureInitialized();
  }
}

// Mock classes for testing
class MockFirebaseApp extends Mock implements FirebaseApp {}

// Test constants
class TestConstants {
  static const String testUserId = 'test_user_id';
  static const String testUserEmail = 'test@example.com';
  static const String testUserName = 'Test User';
  static const String testPlateNumber = 'ABC123';
  static const String testNoteContent = 'Test note content';
  static const String testLocation = 'Test location';
}

// Test data builders
class TestDataBuilder {
  static Map<String, dynamic> buildPlateResultJson({
    String plateNumber = TestConstants.testPlateNumber,
    double confidence = 85.0,
    String region = 'us',
  }) {
    return {
      'plate': plateNumber,
      'confidence': confidence,
      'matches_template': 1,
      'plate_index': 0,
      'region': region,
      'region_confidence': 90,
      'processing_time_ms': 250.0,
      'requested_topn': 5,
      'coordinates': [
        {'x': 100, 'y': 200},
        {'x': 300, 'y': 200},
        {'x': 300, 'y': 250},
        {'x': 100, 'y': 250},
      ],
      'candidates': [
        {
          'plate': plateNumber,
          'confidence': confidence,
          'matches_template': 1,
        },
      ],
    };
  }

  static Map<String, dynamic> buildUserModelJson({
    String uid = TestConstants.testUserId,
    String email = TestConstants.testUserEmail,
    String displayName = TestConstants.testUserName,
  }) {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': null,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> buildPlateNoteJson({
    String id = 'test_note_id',
    String plateNumber = TestConstants.testPlateNumber,
    String userId = TestConstants.testUserId,
    String note = TestConstants.testNoteContent,
    String? location,
  }) {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'userId': userId,
      'note': note,
      'location': location,
      'latitude': null,
      'longitude': null,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'imageUrls': null,
      'metadata': {
        'confidence': 85.0,
        'region': 'us',
        'detectedAt': DateTime.now().toIso8601String(),
      },
    };
  }
}

// Custom matchers for testing
Matcher isValidPlateNumber() => predicate<String>(
  (plateNumber) => RegExp(r'^[A-Z0-9\s\-]+$').hasMatch(plateNumber),
  'is a valid plate number format',
);

Matcher hasValidLength(int min, int max) => predicate<String>(
  (value) => value.length >= min && value.length <= max,
  'has length between $min and $max characters',
);