import 'package:flutter_test/flutter_test.dart';
import 'package:alpr_flutter_app/models/plate_result.dart';

void main() {
  group('PlateResult', () {
    test('should create PlateResult from JSON correctly', () {
      // Arrange
      final json = {
        'plate': 'ABC123',
        'confidence': 85.5,
        'matches_template': 1,
        'plate_index': 0,
        'region': 'us',
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
            'plate': 'ABC123',
            'confidence': 85.5,
            'matches_template': 1,
          },
        ],
      };

      // Act
      final plateResult = PlateResult.fromJson(json);

      // Assert
      expect(plateResult.plateNumber, 'ABC123');
      expect(plateResult.confidence, 85.5);
      expect(plateResult.matchesTemplate, 1);
      expect(plateResult.plateIndex, 0);
      expect(plateResult.region, 'us');
      expect(plateResult.regionConfidence, 90);
      expect(plateResult.processingTimeMs, 250.0);
      expect(plateResult.requestedTopN, 5);
      expect(plateResult.coordinates.length, 4);
      expect(plateResult.candidates.length, 1);
    });

    test('should convert PlateResult to JSON correctly', () {
      // Arrange
      final plateResult = PlateResult(
        plateNumber: 'XYZ789',
        confidence: 92.3,
        matchesTemplate: 1,
        plateIndex: 1,
        region: 'eu',
        regionConfidence: 88,
        processingTimeMs: 180.0,
        requestedTopN: 3,
        coordinates: [
          Coordinate(x: 50, y: 100),
          Coordinate(x: 250, y: 100),
          Coordinate(x: 250, y: 140),
          Coordinate(x: 50, y: 140),
        ],
        candidates: [
          PlateCandidate(
            plate: 'XYZ789',
            confidence: 92.3,
            matchesTemplate: 1,
          ),
        ],
      );

      // Act
      final json = plateResult.toJson();

      // Assert
      expect(json['plate'], 'XYZ789');
      expect(json['confidence'], 92.3);
      expect(json['matches_template'], 1);
      expect(json['plate_index'], 1);
      expect(json['region'], 'eu');
      expect(json['region_confidence'], 88);
      expect(json['processing_time_ms'], 180.0);
      expect(json['requested_topn'], 3);
      expect(json['coordinates'], isA<List>());
      expect(json['candidates'], isA<List>());
    });
  });

  group('Coordinate', () {
    test('should create Coordinate from JSON correctly', () {
      // Arrange
      final json = {'x': 150, 'y': 300};

      // Act
      final coordinate = Coordinate.fromJson(json);

      // Assert
      expect(coordinate.x, 150);
      expect(coordinate.y, 300);
    });

    test('should convert Coordinate to JSON correctly', () {
      // Arrange
      final coordinate = Coordinate(x: 75, y: 125);

      // Act
      final json = coordinate.toJson();

      // Assert
      expect(json['x'], 75);
      expect(json['y'], 125);
    });
  });

  group('PlateCandidate', () {
    test('should create PlateCandidate from JSON correctly', () {
      // Arrange
      final json = {
        'plate': 'DEF456',
        'confidence': 78.9,
        'matches_template': 0,
      };

      // Act
      final candidate = PlateCandidate.fromJson(json);

      // Assert
      expect(candidate.plate, 'DEF456');
      expect(candidate.confidence, 78.9);
      expect(candidate.matchesTemplate, 0);
    });

    test('should convert PlateCandidate to JSON correctly', () {
      // Arrange
      final candidate = PlateCandidate(
        plate: 'GHI789',
        confidence: 67.4,
        matchesTemplate: 1,
      );

      // Act
      final json = candidate.toJson();

      // Assert
      expect(json['plate'], 'GHI789');
      expect(json['confidence'], 67.4);
      expect(json['matches_template'], 1);
    });
  });

  group('OpenALPRResponse', () {
    test('should create OpenALPRResponse from JSON correctly', () {
      // Arrange
      final json = {
        'version': 2,
        'data_type': 'alpr_results',
        'epoch_time': 1234567890,
        'img_width': 1280,
        'img_height': 720,
        'processing_time_ms': 450.0,
        'regions_of_interest': [],
        'results': [
          {
            'plate': 'TEST123',
            'confidence': 95.0,
            'matches_template': 1,
            'plate_index': 0,
            'region': 'us',
            'region_confidence': 95,
            'processing_time_ms': 450.0,
            'requested_topn': 5,
            'coordinates': [
              {'x': 100, 'y': 200},
              {'x': 300, 'y': 200},
              {'x': 300, 'y': 250},
              {'x': 100, 'y': 250},
            ],
            'candidates': [
              {
                'plate': 'TEST123',
                'confidence': 95.0,
                'matches_template': 1,
              },
            ],
          },
        ],
      };

      // Act
      final response = OpenALPRResponse.fromJson(json);

      // Assert
      expect(response.version, 2);
      expect(response.dataType, 'alpr_results');
      expect(response.epochTime, 1234567890);
      expect(response.imgWidth, 1280);
      expect(response.imgHeight, 720);
      expect(response.processingTimeMs, 450.0);
      expect(response.regionsOfInterest.length, 0);
      expect(response.results.length, 1);
      expect(response.results.first.plateNumber, 'TEST123');
    });
  });
}