import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/location.dart';

void main() {
  /// Test suite focusing on the Location model functionality.
  ///
  /// These tests verify that the Location class correctly handles object
  /// creation, property assignments, and serialisation/deserialisation.
  group('Location Model Tests', () {
    /// Verifies that a Location can be instantiated with only the required parameters.
    ///
    /// Tests that mandatory fields (name, latitude, longitude) are properly assigned
    /// and that optional fields (isCurrent) default to expected values.
    test('Location can be created with required parameters', () {
      final location = Location(
        name: 'New York',
        latitude: 40.7128,
        longitude: -74.0060,
      );

      expect(location.name, 'New York');
      expect(location.latitude, 40.7128);
      expect(location.longitude, -74.0060);
      expect(location.isCurrent, false); // Default value
    });

    /// Verifies that a Location can be created with the optional isCurrent flag.
    ///
    /// Tests that both required and optional parameters are correctly assigned
    /// when explicitly provided in the constructor.
    test('Location can be created with isCurrent parameter', () {
      final location = Location(
        name: 'Current City',
        latitude: 51.5074,
        longitude: -0.1278,
        isCurrent: true,
      );

      expect(location.name, 'Current City');
      expect(location.isCurrent, true);
    });

    /// Tests the deserialisation functionality from JSON to Location object.
    ///
    /// Ensures that the fromJson factory method correctly parses JSON data
    /// and creates a valid Location instance with matching properties.
    test('Location can be created from JSON', () {
      final json = {
        'name': 'London',
        'latitude': 51.5074,
        'longitude': -0.1278,
        'isCurrent': true,
      };

      final location = Location.fromJson(json);

      expect(location.name, 'London');
      expect(location.latitude, 51.5074);
      expect(location.longitude, -0.1278);
      expect(location.isCurrent, true);
    });

    /// Tests the serialisation functionality from Location to JSON.
    ///
    /// Verifies that the toJson method correctly converts a Location instance
    /// into a map representation suitable for storage or network transmission.
    test('Location can be converted to JSON', () {
      final location = Location(
        name: 'Paris',
        latitude: 48.8566,
        longitude: 2.3522,
        isCurrent: false,
      );

      final json = location.toJson();

      expect(json['name'], 'Paris');
      expect(json['latitude'], 48.8566);
      expect(json['longitude'], 2.3522);
      expect(json['isCurrent'], false);
    });
  });
}
