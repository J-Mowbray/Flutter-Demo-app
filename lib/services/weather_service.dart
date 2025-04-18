import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather_app/models/weather_data.dart';
import 'package:weather_app/models/location.dart';
import 'package:flutter/foundation.dart';

/// Service for retrieving weather data from external APIs.
///
/// Provides methods to fetch current weather conditions and forecasts
/// from the Open-Meteo weather API.
class WeatherService {
  /// Base URL for Open-Meteo weather API.
  static const String baseUrl = 'https://api.open-meteo.com/v1';

  /// Base URL for Open-Meteo air quality API.
  static const String airQualityUrl =
      'https://air-quality-api.open-meteo.com/v1';

  /// HTTP client for connection reuse and improved performance.
  final http.Client _httpClient = http.Client();

  /// Fetches current weather conditions for a specific location.
  ///
  /// Returns a CurrentWeather object with comprehensive weather data.
  Future<CurrentWeather> getCurrentWeather(
    double latitude,
    double longitude,
  ) async {
    /// Add cache busting parameter to ensure fresh data from API
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final url = Uri.parse(
      '$baseUrl/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,rain,uv_index,is_day,cloud_cover,wind_speed_10m&wind_speed_unit=mph&timezone=auto&cache_bust=$timestamp',
    );

    try {
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          print('Weather data response: ${data['current']}');
        }

        /// Fetch air quality data separately
        final airQualityData = await _fetchAirQualityData(latitude, longitude);

        /// Combine weather and air quality data
        final Map<String, dynamic> currentData = {
          ...data['current'],
          ...airQualityData,
        };

        return CurrentWeather.fromJson(currentData);
      } else {
        throw Exception(
          'Failed to fetch the current weather data: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching current weather: $e');
      }
      throw Exception('Failed to fetch the current weather data: $e');
    }
  }

  /// Fetches air quality and pollen data from the Air Quality API.
  ///
  /// Returns a map containing air quality index and pollen count values.
  Future<Map<String, dynamic>> _fetchAirQualityData(
    double latitude,
    double longitude,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      /// Use corrected parameter names for pollen data
      final url = Uri.parse(
        '$airQualityUrl/air-quality?latitude=$latitude&longitude=$longitude&current=european_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,alder_pollen,birch_pollen,grass_pollen,mugwort_pollen,olive_pollen,ragweed_pollen,dust,ammonia&timezone=auto&cache_bust=$timestamp',
      );

      if (kDebugMode) {
        print('Air quality API URL: $url');
      }

      final response = await _httpClient.get(url);

      if (kDebugMode) {
        print('Air quality API status code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          print('Air quality data response: ${data['current']}');
        }

        /// Get air quality index
        int airQualityIndex = 0;
        if (data['current'] != null &&
            data['current']['european_aqi'] != null) {
          airQualityIndex = (data['current']['european_aqi'] as num).toInt();
        }

        /// Calculate average pollen count from available pollen types with correct parameter names
        double pollenCount = _calculateAveragePollenCount(data['current']);

        if (kDebugMode) {
          print('Final airQualityIndex: $airQualityIndex');
          print('Calculated pollenCount: $pollenCount');
        }

        return {
          'air_quality_index': airQualityIndex,
          'pollen_count': pollenCount,
        };
      } else {
        if (kDebugMode) {
          print('Air quality API error response: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching air quality data: $e');
      }
    }

    /// Return default values if we can't fetch air quality data
    return {'air_quality_index': 0, 'pollen_count': 0.0};
  }

  /// Calculates an average pollen count from multiple pollen types.
  ///
  /// Takes a data map containing various pollen measurements and returns
  /// their average as a representative value.
  double _calculateAveragePollenCount(Map<String, dynamic> data) {
    double totalPollen = 0.0;
    int count = 0;

    /// Check and add all available pollen types with corrected parameter names
    final pollenTypes = [
      'alder_pollen',
      'birch_pollen',
      'grass_pollen',
      'mugwort_pollen',
      'olive_pollen',
      'ragweed_pollen',
    ];

    for (final type in pollenTypes) {
      if (data[type] != null) {
        totalPollen += (data[type] as num).toDouble();
        count++;
      }
    }

    /// Calculate average or return 0 if no pollen data
    return count > 0 ? totalPollen / count : 0.0;
  }

  /// Fetches hourly weather forecast for the next 24 hours.
  ///
  /// Returns a list of HourlyForecast objects representing hour-by-hour predictions.
  Future<List<HourlyForecast>> getHourlyForecast(
    double latitude,
    double longitude,
  ) async {
    /// Add cache busting parameter
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final url = Uri.parse(
      '$baseUrl/forecast?latitude=$latitude&longitude=$longitude&hourly=temperature_2m,cloud_cover,precipitation_probability,wind_speed_10m,is_day&forecast_hours=24&wind_speed_unit=mph&timezone=auto&cache_bust=$timestamp',
    );

    try {
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<String> times = List<String>.from(data['hourly']['time']);

        List<HourlyForecast> forecasts = [];

        for (int i = 0; i < times.length; i++) {
          forecasts.add(
            HourlyForecast(
              temperature: data['hourly']['temperature_2m'][i].toDouble(),
              windSpeed: data['hourly']['wind_speed_10m'][i].toDouble(),
              cloudCover: data['hourly']['cloud_cover'][i],
              rainProbability:
                  data['hourly']['precipitation_probability'][i].toDouble(),
              isDay: data['hourly']['is_day'][i] == 1,
              time: DateTime.parse(times[i]),
            ),
          );
        }

        return forecasts;
      } else {
        throw Exception(
          'Failed to fetch hourly forecast: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching hourly forecast: $e');
      }
      throw Exception('Failed to fetch hourly forecast: $e');
    }
  }

  /// Fetches daily weather forecast for the next 7 days.
  ///
  /// Returns a list of DailyForecast objects with day-by-day predictions.
  Future<List<DailyForecast>> getDailyForecast(
    double latitude,
    double longitude,
  ) async {
    /// Add cache busting parameter
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final url = Uri.parse(
      '$baseUrl/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,cloud_cover_max,uv_index_max&forecast_days=7&wind_speed_unit=mph&timezone=auto&cache_bust=$timestamp',
    );

    try {
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<String> dates = List<String>.from(data['daily']['time']);

        List<DailyForecast> forecasts = [];

        for (int i = 0; i < dates.length; i++) {
          forecasts.add(
            DailyForecast(
              minTemperature: data['daily']['temperature_2m_min'][i].toDouble(),
              maxTemperature: data['daily']['temperature_2m_max'][i].toDouble(),
              windSpeed: data['daily']['wind_speed_10m_max'][i].toDouble(),
              rainProbability:
                  data['daily']['precipitation_probability_max'][i].toDouble(),
              uvIndex: data['daily']['uv_index_max'][i].toDouble(),
              cloudCover: data['daily']['cloud_cover_max'][i],
              date: DateTime.parse(dates[i]),
            ),
          );
        }

        return forecasts;
      } else {
        throw Exception(
          'Failed to fetch daily forecast: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching daily forecast: $e');
      }
      throw Exception('Failed to fetch daily forecast: $e');
    }
  }

  /// Aggregates all weather data into a comprehensive object.
  ///
  /// Concurrently fetches current, hourly and daily weather data
  /// for a specific location and combines them into a single WeatherData entity.
  Future<WeatherData> getCompleteWeatherData(Location location) async {
    try {
      /// Fetch all the data concurrently
      final results = await Future.wait([
        getCurrentWeather(location.latitude, location.longitude),
        getHourlyForecast(location.latitude, location.longitude),
        getDailyForecast(location.latitude, location.longitude),
      ]);

      final current = results[0] as CurrentWeather;
      final hourly = results[1] as List<HourlyForecast>;
      final daily = results[2] as List<DailyForecast>;

      return WeatherData(
        current: current,
        hourlyForecast: hourly,
        dailyForecast: daily,
        location: Location(
          name: location.name,
          latitude: location.latitude,
          longitude: location.longitude,
          isCurrent: location.isCurrent,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting complete weather data: $e');
      }
      rethrow;
    }
  }

  /// Fetches weather data for multiple locations in a single batch operation.
  ///
  /// Returns a map where keys are location identifiers and values are the
  /// corresponding WeatherData objects.
  Future<Map<String, WeatherData>> getWeatherForMultipleLocations(
    List<Location> locations,
  ) async {
    final results = await Future.wait(
      locations.map(
        (location) => getCompleteWeatherData(
          location,
        ).then((data) => MapEntry(_getLocationKey(location), data)),
      ),
    );

    return Map.fromEntries(results);
  }

  /// Generates a unique key for a location based on its coordinates.
  ///
  /// Useful for identifying locations in maps and collections.
  String _getLocationKey(Location location) {
    return '${location.latitude},${location.longitude}';
  }

  /// Properly disposes of resources held by this service.
  ///
  /// Should be called when the service is no longer needed to prevent memory leaks.
  void dispose() {
    _httpClient.close();
  }
}
