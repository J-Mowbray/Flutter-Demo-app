import 'package:flutter/material.dart';

/// A utility class providing helper methods for weather data processing and display.
///
/// Contains functions for determining weather conditions, formatting weather data,
/// and providing human-readable interpretations of meteorological measurements.
class WeatherHelpers {
  /// Determines the weather condition based on cloud cover and rain probability.
  ///
  /// Returns a human-readable description that represents the general
  /// atmospheric condition based on the provided parameters.
  ///
  /// Parameters:
  /// - [cloudCover]: Percentage of sky covered by clouds (0-100)
  /// - [rainProbability]: Likelihood of precipitation (0-100)
  static String getWeatherCondition({
    required int cloudCover,
    required double rainProbability,
  }) {
    if (rainProbability > 50) {
      return 'Rainy';
    } else if (cloudCover > 70) {
      return 'Cloudy';
    } else if (cloudCover > 30) {
      return 'Partly Cloudy';
    } else {
      return 'Clear';
    }
  }

  /// Returns an appropriate colour for weather icons based on the condition.
  ///
  /// Uses context-aware theming for some conditions to ensure
  /// the colours match the overall application theme.
  ///
  /// Parameters:
  /// - [context]: The build context for accessing theme data
  /// - [condition]: The weather condition string
  static Color getWeatherIconColor(BuildContext context, String condition) {
    final theme = Theme.of(context);

    switch (condition) {
      case 'Rainy':
        return Colors.blueGrey;
      case 'Cloudy':
        return Colors.grey;
      case 'Partly Cloudy':
        return theme.colorScheme.primary;
      case 'Clear':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }

  /// Converts wind speed from metres per second to kilometres per hour.
  ///
  /// Applied using the standard conversion factor of 3.6.
  ///
  /// Parameter:
  /// - [windSpeedMs]: Wind speed in metres per second
  static double convertWindSpeedToKmh(double windSpeedMs) {
    return windSpeedMs * 3.6;
  }

  /// Provides a descriptive category for UV index values.
  ///
  /// Categorises UV index into human-readable risk levels according to
  /// standard meteorological classifications.
  ///
  /// Parameter:
  /// - [uvIndex]: Numerical UV index value
  static String getUvIndexDescription(double uvIndex) {
    if (uvIndex < 3) {
      return 'Low';
    } else if (uvIndex < 6) {
      return 'Moderate';
    } else if (uvIndex < 8) {
      return 'High';
    } else if (uvIndex < 11) {
      return 'Very High';
    } else {
      return 'Extreme';
    }
  }

  /// Translates air quality index values into descriptive categories.
  ///
  /// Provides human-readable air quality assessments based on standard
  /// AQI classification ranges used by environmental agencies.
  ///
  /// Parameter:
  /// - [aqiValue]: Numerical air quality index value
  static String getAirQualityDescription(int aqiValue) {
    if (aqiValue < 50) {
      return 'Good';
    } else if (aqiValue < 100) {
      return 'Moderate';
    } else if (aqiValue < 150) {
      return 'Unhealthy for Sensitive Groups';
    } else if (aqiValue < 200) {
      return 'Unhealthy';
    } else if (aqiValue < 300) {
      return 'Very Unhealthy';
    } else {
      return 'Hazardous';
    }
  }

  /// Formats temperature values for display with optional unit marking.
  ///
  /// Returns a string representation of temperature with one decimal place,
  /// optionally appending the Celsius degree symbol.
  ///
  /// Parameters:
  /// - [temperature]: The temperature value to format
  /// - [showUnit]: Whether to display the °C unit (defaults to true)
  static String formatTemperature(double temperature, {bool showUnit = true}) {
    return '${temperature.toStringAsFixed(1)}${showUnit ? '°C' : ''}';
  }
}
