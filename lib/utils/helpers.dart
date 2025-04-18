import 'package:flutter/material.dart';

class WeatherHelpers {
  // Determine weather condition based on cloud cover and rain probability
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

  // Get appropriate weather icon color based on the weather condition
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

  // Convert wind speed from m/s to km/h
  static double convertWindSpeedToKmh(double windSpeedMs) {
    return windSpeedMs * 3.6;
  }

  // Get UV index description based on the UV value
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

  // Get air quality description based on the AQI value
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

  // Format temperature with appropriate unit
  static String formatTemperature(double temperature, {bool showUnit = true}) {
    return '${temperature.toStringAsFixed(1)}${showUnit ? '°C' : ''}';
  }
}
