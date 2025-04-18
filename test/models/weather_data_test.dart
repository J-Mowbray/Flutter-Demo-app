import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/weather_data.dart';
import 'package:weather_app/models/location.dart';

/// Helper function to run code with suppressed print statements.
///
/// This prevents console pollution during testing whilst still allowing
/// the code to execute normally. Particularly useful when testing
/// code that logs errors or warnings that we expect.
T suppressPrints<T>(T Function() testFunction) {
  return runZoned<T>(
    testFunction,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, ____) {
        // Do nothing with print output
      },
    ),
  );
}

void main() {
  /// Tests for the CurrentWeather model.
  ///
  /// Covers creation from JSON, handling of missing or invalid data,
  /// and proper formatting of weather information.
  group('CurrentWeather', () {
    /// Tests the fallback to current time when the time field is missing.
    ///
    /// This is critical for ensuring the application doesn't crash when
    /// receiving incomplete data from an API.
    test('handles missing time field by using current time', () {
      suppressPrints(() {
        final beforeTest = DateTime.now();

        final jsonWithoutTime = {
          'temperature_2m': 22.0,
          'is_day': 1,
          // No time field - intentionally missing
        };

        final weather = CurrentWeather.fromJson(jsonWithoutTime);

        final afterTest = DateTime.now();

        // Verify time is between beforeTest and afterTest
        expect(
          weather.time.isAfter(beforeTest) ||
              weather.time.isAtSameMomentAs(beforeTest),
          true,
        );
        expect(
          weather.time.isBefore(afterTest) ||
              weather.time.isAtSameMomentAs(afterTest),
          true,
        );

        // Other fields should still be parsed correctly
        expect(weather.temperature, 22.0);
        expect(weather.isDay, true);
      });
    });

    /// Tests that a complete JSON object is correctly parsed.
    ///
    /// Ensures all fields are properly extracted and assigned when
    /// all expected data is present in the API response.
    test('creates from complete JSON correctly', () {
      final completeJson = {
        'temperature_2m': 25.5,
        'rain': 0.0,
        'uv_index': 7.2,
        'pollen_count': 3.5,
        'air_quality_index': 42,
        'is_day': 1,
        'wind_speed_10m': 3.8,
        'cloud_cover': 25,
        'time': '2023-07-21T15:00:00Z',
      };

      final weather = CurrentWeather.fromJson(completeJson);

      expect(weather.temperature, 25.5);
      expect(weather.rainfall, 0.0);
      expect(weather.uvIndex, 7.2);
      expect(weather.pollenCount, 3.5);
      expect(weather.airQualityIndex, 42);
      expect(weather.isDay, true);
      expect(weather.windSpeed, 3.8);
      expect(weather.cloudCover, 25);
      expect(weather.time, DateTime.parse('2023-07-21T15:00:00Z'));
    });

    /// Tests handling of JSON with only essential fields present.
    ///
    /// Ensures the model applies appropriate defaults for missing
    /// non-critical data fields rather than crashing.
    test('gracefully handles missing non-essential fields', () {
      final partialJson = {
        'temperature_2m': 20.0,
        'is_day': 0,
        'time': '2023-07-21T15:00:00Z',
      };

      final weather = CurrentWeather.fromJson(partialJson);

      expect(weather.temperature, 20.0);
      expect(weather.rainfall, 0.0); // Default value
      expect(weather.uvIndex, 0.0); // Default value
      expect(weather.pollenCount, 0.0); // Default value
      expect(weather.airQualityIndex, 0); // Default value
      expect(weather.isDay, false);
      expect(weather.windSpeed, 0.0); // Default value
      expect(weather.cloudCover, 0); // Default value
      expect(weather.time, DateTime.parse('2023-07-21T15:00:00Z'));
    });

    /// Tests that time and date formatting work correctly.
    ///
    /// Verifies that the helper methods for displaying formatted
    /// time and date produce strings in the expected format.
    test('correctly formats time and date', () {
      final weather = CurrentWeather(
        temperature: 25.5,
        rainfall: 0.0,
        uvIndex: 7.2,
        pollenCount: 3.5,
        airQualityIndex: 42,
        isDay: true,
        windSpeed: 3.8,
        cloudCover: 25,
        time: DateTime.parse('2023-07-21T15:00:00Z'),
      );

      // Basic format checks
      expect(weather.formattedTime.contains(':'), true);
      expect(weather.formattedDate.contains('2023'), true);
    });

    /// Tests that extreme weather values are handled correctly.
    ///
    /// Verifies the model can process unusual or extreme weather conditions
    /// without applying any artificial caps or modifications.
    test('handles extreme weather values correctly', () {
      final extremeJson = {
        'temperature_2m': 55.0, // Very high temperature
        'rain': 100.0, // Heavy rain
        'wind_speed_10m': 150.0, // Hurricane force
        'uv_index': 12.0, // Extreme UV
        'air_quality_index': 500, // Hazardous air quality
        'cloud_cover': 100, // Complete cloud cover
        'time': '2023-07-21T15:00:00Z',
      };

      final weather = CurrentWeather.fromJson(extremeJson);

      expect(weather.temperature, 55.0);
      expect(weather.rainfall, 100.0);
      expect(weather.windSpeed, 150.0);
      expect(weather.uvIndex, 12.0);
      expect(weather.airQualityIndex, 500);
      expect(weather.cloudCover, 100);
    });

    /// Tests parsing of different ISO 8601 time format variations.
    ///
    /// Ensures the model can handle different valid time formats that
    /// might be returned by the API without failing.
    test('parses various ISO 8601 time formats correctly', () {
      // Different valid ISO 8601 formats
      final formats = [
        '2023-07-21T15:00:00Z', // UTC
        '2023-07-21T15:00:00+01:00', // With timezone offset
        '2023-07-21T15:00:00.123Z', // With milliseconds
      ];

      for (final timeStr in formats) {
        final json = {'temperature_2m': 22.0, 'time': timeStr};

        final weather = CurrentWeather.fromJson(json);
        expect(weather.time, isA<DateTime>());
      }
    });

    /// Tests handling of fields with incorrect data types.
    ///
    /// Ensures the model gracefully handles type mismatches by
    /// applying reasonable defaults rather than crashing.
    test('handles invalid field types gracefully', () {
      suppressPrints(() {
        final invalidJson = {
          'temperature_2m': "not a number", // Wrong type
          'is_day': "true", // Not 0 or 1
          'time': '2023-07-21T15:00:00Z',
        };

        // This should not throw an exception but use default values
        final weather = CurrentWeather.fromJson(invalidJson);

        // Should use default values for invalid types
        expect(weather.temperature, 0.0);
        expect(weather.isDay, false);
        expect(weather.time, isA<DateTime>());
      });
    });

    /// Tests handling of null values in the JSON data.
    ///
    /// Verifies that the model applies appropriate defaults when
    /// null values are encountered instead of crashing.
    test('handles null JSON values gracefully', () {
      final nullJson = {
        'temperature_2m': null,
        'rain': null,
        'uv_index': null,
        'is_day': null,
        'time': '2023-07-21T15:00:00Z',
      };

      final weather = CurrentWeather.fromJson(nullJson);

      expect(weather.temperature, 0.0);
      expect(weather.rainfall, 0.0);
      expect(weather.uvIndex, 0.0);
      expect(weather.isDay, false);
      expect(weather.time, DateTime.parse('2023-07-21T15:00:00Z'));
    });
  });

  /// Tests for the HourlyForecast model.
  ///
  /// Covers creation from JSON, default values, and proper formatting
  /// of hourly weather predictions.
  group('HourlyForecast', () {
    /// Tests creating an HourlyForecast from complete JSON data.
    ///
    /// Verifies all fields are properly extracted and assigned when
    /// the expected data format is received.
    test('creates from JSON correctly', () {
      final json = {
        'temperature_2m': 22.5,
        'wind_speed_10m': 4.2,
        'cloud_cover': 30,
        'precipitation_probability': 20.0,
        'is_day': 1,
        'time': '2023-07-21T16:00:00Z',
      };

      final forecast = HourlyForecast.fromJson(json);

      expect(forecast.temperature, 22.5);
      expect(forecast.windSpeed, 4.2);
      expect(forecast.cloudCover, 30);
      expect(forecast.rainProbability, 20.0);
      expect(forecast.isDay, true);
      expect(forecast.time, DateTime.parse('2023-07-21T16:00:00Z'));
    });

    /// Tests applying default values for missing fields.
    ///
    /// Ensures the model supplies appropriate defaults when
    /// fields are missing from the API response.
    test('applies default values for missing fields', () {
      final json = {
        'time': '2023-07-21T16:00:00Z', // Only time present
      };

      final forecast = HourlyForecast.fromJson(json);

      expect(forecast.temperature, 0.0);
      expect(forecast.windSpeed, 0.0);
      expect(forecast.cloudCover, 0);
      expect(forecast.rainProbability, 0.0);
      expect(forecast.isDay, false);
      expect(forecast.time, DateTime.parse('2023-07-21T16:00:00Z'));
    });

    /// Tests the time and day formatting methods.
    ///
    /// Verifies that helper methods for displaying formatted time
    /// and day name produce strings in the expected format.
    test('correctly formats time and day', () {
      final forecast = HourlyForecast(
        temperature: 22.5,
        windSpeed: 4.2,
        cloudCover: 30,
        rainProbability: 20.0,
        isDay: true,
        time: DateTime.parse('2023-07-21T16:00:00Z'), // Friday
      );

      // Basic format checks
      expect(forecast.formattedTime.contains(':'), true);
      expect(forecast.formattedDay.isNotEmpty, true);
    });

    /// Tests handling of maximum precipitation probability.
    ///
    /// Ensures the model correctly processes 100% precipitation
    /// probability without applying any artificial caps.
    test('handles extreme probability values', () {
      final extremeJson = {
        'temperature_2m': 22.5,
        'precipitation_probability': 100.0, // 100% probability
        'time': '2023-07-21T16:00:00Z',
      };

      final forecast = HourlyForecast.fromJson(extremeJson);
      expect(forecast.rainProbability, 100.0);
    });

    /// Tests proper exception throwing for invalid time formats.
    ///
    /// Verifies that the model appropriately throws a FormatException
    /// when given a time string that cannot be parsed.
    test('handles invalid time format', () {
      suppressPrints(() {
        final invalidTimeJson = {
          'temperature_2m': 22.5,
          'time': 'not-a-date', // Invalid time format
        };

        expect(
          () => HourlyForecast.fromJson(invalidTimeJson),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });

  /// Tests for the DailyForecast model.
  ///
  /// Covers creation from JSON, default values, and proper formatting
  /// of daily weather predictions.
  group('DailyForecast', () {
    /// Tests creating a DailyForecast from complete JSON data.
    ///
    /// Verifies all fields are properly extracted from the JSON response
    /// and correctly assigned to the model properties.
    test('creates from JSON correctly', () {
      final json = {
        'temperature_2m_min': 18.5,
        'temperature_2m_max': 27.8,
        'wind_speed_10m_max': 6.3,
        'precipitation_probability_max': 35.0,
        'uv_index_max': 8.5,
        'cloud_cover_max': 45,
        'time': '2023-07-22', // Just date, no time
      };

      final forecast = DailyForecast.fromJson(json);

      expect(forecast.minTemperature, 18.5);
      expect(forecast.maxTemperature, 27.8);
      expect(forecast.windSpeed, 6.3);
      expect(forecast.rainProbability, 35.0);
      expect(forecast.uvIndex, 8.5);
      expect(forecast.cloudCover, 45);
      expect(forecast.date, DateTime.parse('2023-07-22'));
    });

    /// Tests applying default values for missing fields.
    ///
    /// Ensures the model supplies appropriate defaults when
    /// weather metrics are missing from the API response.
    test('applies default values for missing fields', () {
      final json = {
        'time': '2023-07-22', // Only time present
      };

      final forecast = DailyForecast.fromJson(json);

      expect(forecast.minTemperature, 0.0);
      expect(forecast.maxTemperature, 0.0);
      expect(forecast.windSpeed, 0.0);
      expect(forecast.rainProbability, 0.0);
      expect(forecast.uvIndex, 0.0);
      expect(forecast.cloudCover, 0);
      expect(forecast.date, DateTime.parse('2023-07-22'));
    });

    /// Tests the date and day formatting methods.
    ///
    /// Verifies that helper methods for displaying formatted date
    /// and day name produce strings in the expected format.
    test('correctly formats date and day', () {
      final forecast = DailyForecast(
        minTemperature: 18.5,
        maxTemperature: 27.8,
        windSpeed: 6.3,
        rainProbability: 35.0,
        uvIndex: 8.5,
        cloudCover: 45,
        date: DateTime.parse('2023-07-22'), // Saturday
      );

      // Basic format checks
      expect(forecast.formattedDate.isNotEmpty, true);
      expect(forecast.formattedDay.isNotEmpty, true);
    });

    /// Tests handling of unusual temperature relationships.
    ///
    /// Ensures the model accepts cases where minimum temperature
    /// might be higher than maximum temperature without error.
    test('handles min temperature higher than max temperature', () {
      final unusualJson = {
        'temperature_2m_min': 30.0, // Higher than max (unusual)
        'temperature_2m_max': 25.0,
        'time': '2023-07-22',
      };

      final forecast = DailyForecast.fromJson(unusualJson);

      // The model should accept the unusual values as-is
      expect(forecast.minTemperature, 30.0);
      expect(forecast.maxTemperature, 25.0);
    });

    /// Tests handling of different date format variants.
    ///
    /// Verifies that the model can correctly parse different valid
    /// representations of the same date from the API.
    test('handles different date formats', () {
      final formats = [
        '2023-07-22', // ISO format
        '2023-07-22T00:00:00Z', // With time component (still valid for daily)
      ];

      for (final dateStr in formats) {
        final json = {
          'temperature_2m_min': 18.5,
          'temperature_2m_max': 27.8,
          'time': dateStr,
        };

        final forecast = DailyForecast.fromJson(json);
        expect(forecast.date.year, 2023);
        expect(forecast.date.month, 7);
        expect(forecast.date.day, 22);
      }
    });
  });

  /// Tests for the WeatherData composite model.
  ///
  /// Covers the creation and access of the composite weather data
  /// object that combines current, hourly and daily forecasts.
  group('WeatherData', () {
    /// Tests creating a complete WeatherData object with all components.
    ///
    /// Verifies that the composite object correctly stores and provides
    /// access to all its component parts and nested properties.
    test('creates complete object with all components', () {
      final currentWeather = CurrentWeather(
        temperature: 25.5,
        rainfall: 0.0,
        uvIndex: 7.2,
        pollenCount: 3.5,
        airQualityIndex: 42,
        isDay: true,
        windSpeed: 3.8,
        cloudCover: 25,
        time: DateTime.parse('2023-07-21T15:00:00Z'),
      );

      final hourlyForecasts = [
        HourlyForecast(
          temperature: 22.5,
          windSpeed: 4.2,
          cloudCover: 30,
          rainProbability: 20.0,
          isDay: true,
          time: DateTime.parse('2023-07-21T16:00:00Z'),
        ),
      ];

      final dailyForecasts = [
        DailyForecast(
          minTemperature: 18.5,
          maxTemperature: 27.8,
          windSpeed: 6.3,
          rainProbability: 35.0,
          uvIndex: 8.5,
          cloudCover: 45,
          date: DateTime.parse('2023-07-22'),
        ),
      ];

      final location = Location(
        name: 'Test City',
        latitude: 51.5074,
        longitude: -0.1278,
        isCurrent: true,
      );

      final weatherData = WeatherData(
        current: currentWeather,
        hourlyForecast: hourlyForecasts,
        dailyForecast: dailyForecasts,
        location: location,
      );

      // Test all components were stored correctly
      expect(weatherData.current, equals(currentWeather));
      expect(weatherData.hourlyForecast, equals(hourlyForecasts));
      expect(weatherData.dailyForecast, equals(dailyForecasts));
      expect(weatherData.location, equals(location));

      // Test we can access nested properties
      expect(weatherData.current.temperature, 25.5);
      expect(weatherData.hourlyForecast.first.temperature, 22.5);
      expect(weatherData.dailyForecast.first.maxTemperature, 27.8);
      expect(weatherData.location.name, 'Test City');
    });

    /// Tests handling of empty forecast lists.
    ///
    /// Ensures the model can represent situations where forecast
    /// data might not be available but current conditions are.
    test('handles empty forecast lists', () {
      final weatherData = WeatherData(
        current: CurrentWeather(
          temperature: 22.0,
          rainfall: 0.0,
          uvIndex: 6.0,
          pollenCount: 2.0,
          airQualityIndex: 35,
          isDay: true,
          windSpeed: 3.5,
          cloudCover: 20,
          time: DateTime.now(),
        ),
        hourlyForecast: [], // Empty hourly forecasts
        dailyForecast: [], // Empty daily forecasts
        location: Location(
          name: 'Test City',
          latitude: 51.5074,
          longitude: -0.1278,
        ),
      );

      expect(weatherData.hourlyForecast, isEmpty);
      expect(weatherData.dailyForecast, isEmpty);
    });
  });

  /// Tests covering edge cases and error handling.
  ///
  /// Focuses on the model's ability to handle unexpected or
  /// problematic input data without crashing.
  group('Edge Cases', () {
    /// Tests handling of completely empty or malformed JSON.
    ///
    /// Verifies that the model can gracefully handle cases where
    /// the API might return an empty or invalid response.
    test('handles malformed JSON gracefully', () {
      suppressPrints(() {
        final malformedJson = <String, dynamic>{
          // Empty JSON
        };

        // Should not throw, but use default values
        final weather = CurrentWeather.fromJson(malformedJson);

        expect(weather.temperature, 0.0);
        expect(weather.rainfall, 0.0);
        expect(weather.uvIndex, 0.0);

        // Time should be now (approximately)
        final now = DateTime.now();
        expect(
          weather.time.difference(now).inSeconds.abs() < 2,
          true,
          reason: 'Default time should be close to current time',
        );
      });
    });
  });
}
