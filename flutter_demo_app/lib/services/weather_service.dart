// Weather Service to interface with the Open-Meteo API

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather_app/models/weather_data.dart';
import 'package:weather_app/models/location.dart';

class WeatherService {
  static const String baseUrl = 'https://api.open-meteo.com/v1';

  // HTTP client for connection reuse
  final http.Client _httpClient = http.Client();

  // Fetch the current weather data
  Future<CurrentWeather> getCurrentWeather(
    double latitude,
    double longitude,
  ) async {
    // Add cache busting parameter to ensure fresh data from API
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final url = Uri.parse(
      '$baseUrl/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,rain,uv_index,is_day,cloud_cover,wind_speed_10m&wind_speed_unit=mph&timezone=auto&cache_bust=$timestamp',
    );

    final response = await _httpClient.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Simulating values not available in free tier
      final Map<String, dynamic> currentData = {
        ...data['current'],
        'pollen_count': 3.5, // Simulated value
        'air_quality_index': 42, // Simulated value
      };

      return CurrentWeather.fromJson(currentData);
    } else {
      throw Exception('Failed to fetch the current weather data!');
    }
  }

  // Fetch the hourly forecast for the next 24 hours
  Future<List<HourlyForecast>> getHourlyForecast(
    double latitude,
    double longitude,
  ) async {
    // Add cache busting parameter
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final url = Uri.parse(
      '$baseUrl/forecast?latitude=$latitude&longitude=$longitude&hourly=temperature_2m,cloud_cover,precipitation_probability,wind_speed_10m,is_day&forecast_hours=24&wind_speed_unit=mph&timezone=auto&cache_bust=$timestamp',
    );

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
      throw Exception('Failed to fetch hourly forecast!');
    }
  }

  // Fetch daily forecast for the next 7 days
  Future<List<DailyForecast>> getDailyForecast(
    double latitude,
    double longitude,
  ) async {
    // Add cache busting parameter
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final url = Uri.parse(
      '$baseUrl/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,cloud_cover_max,uv_index_max&forecast_days=7&wind_speed_unit=mph&timezone=auto&cache_bust=$timestamp',
    );

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
      throw Exception('Failed to fetch daily forecast!');
    }
  }

  // Combine all data into a single WeatherData object
  Future<WeatherData> getCompleteWeatherData(Location location) async {
    // Fetch all the data concurrently
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
  }

  // Batch fetch weather data for multiple locations at once
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

  String _getLocationKey(Location location) {
    return '${location.latitude},${location.longitude}';
  }

  // Remember to dispose of the client when done
  void dispose() {
    _httpClient.close();
  }
}
