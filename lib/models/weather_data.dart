import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/models/location.dart';

/// Represents current weather conditions at a specific location and time.
///
/// Contains comprehensive meteorological data including temperature,
/// precipitation, air quality, and other environmental indicators.
class CurrentWeather {
  /// Current temperature in degrees Celsius.
  final double temperature;

  /// Current rainfall amount in millimetres.
  final double rainfall;

  /// Ultraviolet radiation index value (0-12 scale).
  final double uvIndex;

  /// Measured pollen concentration level.
  final double pollenCount;

  /// Air quality index value (typically 0-500 scale).
  final int airQualityIndex;

  /// Indicates whether it's currently daytime (true) or nighttime (false).
  final bool isDay;

  /// Wind speed in miles per hour.
  final double windSpeed;

  /// Cloud cover percentage (0-100).
  final int cloudCover;

  /// Timestamp when this weather data was recorded.
  final DateTime time;

  /// Creates a new CurrentWeather instance with required parameters.
  CurrentWeather({
    required this.temperature,
    required this.rainfall,
    required this.uvIndex,
    required this.pollenCount,
    required this.airQualityIndex,
    required this.isDay,
    required this.windSpeed,
    required this.cloudCover,
    required this.time,
  });

  /// Creates a CurrentWeather instance from API JSON response.
  ///
  /// Includes robust error handling for missing or invalid data fields.
  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    /// Extract time with a default of current time if missing
    DateTime time;
    try {
      time = DateTime.parse(json['time']);
    } catch (e) {
      /// If time parsing fails, use current time
      time = DateTime.now();
      if (kDebugMode) {
        print('Error parsing time, using current time: $e');
      }
    }

    /// Helper function to safely convert values to double
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      try {
        return double.parse(value.toString());
      } catch (e) {
        if (kDebugMode) {
          print('Error converting "$value" to double: $e');
        }
        return 0.0;
      }
    }

    /// Helper function to safely convert to int
    int safeToInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      try {
        return int.parse(value.toString());
      } catch (e) {
        if (kDebugMode) {
          print('Error converting "$value" to int: $e');
        }
        return 0;
      }
    }

    return CurrentWeather(
      temperature: safeToDouble(json['temperature_2m']),
      rainfall: safeToDouble(json['rain']),
      uvIndex: safeToDouble(json['uv_index']),
      pollenCount: safeToDouble(json['pollen_count']),
      airQualityIndex: safeToInt(json['air_quality_index']),
      isDay: json['is_day'] == 1,
      windSpeed: safeToDouble(json['wind_speed_10m']),
      cloudCover: safeToInt(json['cloud_cover']),
      time: time,
    );
  }

  /// Returns the formatted time in hours and minutes (e.g., "14:30").
  String get formattedTime => DateFormat.Hm().format(time);

  /// Returns the formatted date (e.g., "21 Jul 2023").
  String get formattedDate => DateFormat.yMMMd().format(time);
}

/// Represents hourly weather forecast data.
///
/// Contains weather predictions for a specific hour including temperature,
/// wind conditions, and precipitation probability.
class HourlyForecast {
  /// Predicted temperature in degrees Celsius.
  final double temperature;

  /// Predicted wind speed in miles per hour.
  final double windSpeed;

  /// Predicted cloud cover percentage (0-100).
  final int cloudCover;

  /// Probability of precipitation as a percentage (0-100).
  final double rainProbability;

  /// Indicates whether this forecast is for daytime (true) or nighttime (false).
  final bool isDay;

  /// The specific hour this forecast represents.
  final DateTime time;

  /// Creates a new HourlyForecast instance with required parameters.
  HourlyForecast({
    required this.temperature,
    required this.windSpeed,
    required this.cloudCover,
    required this.rainProbability,
    required this.isDay,
    required this.time,
  });

  /// Creates an HourlyForecast instance from API JSON response.
  ///
  /// Includes robust error handling for missing or invalid data fields.
  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    /// Helper function to safely convert values to double
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      try {
        return double.parse(value.toString());
      } catch (e) {
        if (kDebugMode) {
          print('Error converting "$value" to double: $e');
        }
        return 0.0;
      }
    }

    /// Helper function to safely convert to int
    int safeToInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      try {
        return int.parse(value.toString());
      } catch (e) {
        if (kDebugMode) {
          print('Error converting "$value" to int: $e');
        }
        return 0;
      }
    }

    return HourlyForecast(
      temperature: safeToDouble(json['temperature_2m']),
      windSpeed: safeToDouble(json['wind_speed_10m']),
      cloudCover: safeToInt(json['cloud_cover']),
      rainProbability: safeToDouble(json['precipitation_probability']),
      isDay: json['is_day'] == 1,
      time: DateTime.parse(json['time']),
    );
  }

  /// Returns the formatted time in hours and minutes (e.g., "14:30").
  String get formattedTime => DateFormat.Hm().format(time);

  /// Returns the abbreviated day of week (e.g., "Mon").
  String get formattedDay => DateFormat.E().format(time);
}

/// Represents daily weather forecast data.
///
/// Contains aggregated weather predictions for an entire day,
/// including temperature ranges and other meteorological indicators.
class DailyForecast {
  /// Minimum expected temperature for the day in degrees Celsius.
  final double minTemperature;

  /// Maximum expected temperature for the day in degrees Celsius.
  final double maxTemperature;

  /// Maximum expected wind speed for the day in miles per hour.
  final double windSpeed;

  /// Maximum probability of precipitation for the day as a percentage (0-100).
  final double rainProbability;

  /// Maximum UV index expected for the day (0-12 scale).
  final double uvIndex;

  /// Maximum cloud cover percentage expected for the day (0-100).
  final int cloudCover;

  /// The date this forecast represents.
  final DateTime date;

  /// Creates a new DailyForecast instance with required parameters.
  DailyForecast({
    required this.minTemperature,
    required this.maxTemperature,
    required this.windSpeed,
    required this.rainProbability,
    required this.uvIndex,
    required this.cloudCover,
    required this.date,
  });

  /// Creates a DailyForecast instance from API JSON response.
  ///
  /// Includes robust error handling for missing or invalid data fields.
  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert values to double
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      try {
        return double.parse(value.toString());
      } catch (e) {
        if (kDebugMode) {
          print('Error converting "$value" to double: $e');
        }
        return 0.0;
      }
    }

    /// Helper function to safely convert to int
    int safeToInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      try {
        return int.parse(value.toString());
      } catch (e) {
        if (kDebugMode) {
          print('Error converting "$value" to int: $e');
        }
        return 0;
      }
    }

    return DailyForecast(
      minTemperature: safeToDouble(json['temperature_2m_min']),
      maxTemperature: safeToDouble(json['temperature_2m_max']),
      windSpeed: safeToDouble(json['wind_speed_10m_max']),
      rainProbability: safeToDouble(json['precipitation_probability_max']),
      uvIndex: safeToDouble(json['uv_index_max']),
      cloudCover: safeToInt(json['cloud_cover_max']),
      date: DateTime.parse(json['time']),
    );
  }

  /// Returns the formatted date (e.g., "21 Jul").
  String get formattedDate => DateFormat.MMMd().format(date);

  /// Returns the abbreviated day of week (e.g., "Mon").
  String get formattedDay => DateFormat.E().format(date);
}

/// Container class that aggregates all weather data for a specific location.
///
/// Combines current conditions and forecasts into a single entity.
class WeatherData {
  /// Current weather conditions.
  final CurrentWeather current;

  /// Hourly forecast data for upcoming hours.
  final List<HourlyForecast> hourlyForecast;

  /// Daily forecast data for upcoming days.
  final List<DailyForecast> dailyForecast;

  /// The location for which this weather data applies.
  final Location location;

  /// Creates a new WeatherData instance with required parameters.
  WeatherData({
    required this.current,
    required this.hourlyForecast,
    required this.dailyForecast,
    required this.location,
  });
}
