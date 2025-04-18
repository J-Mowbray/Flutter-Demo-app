// Model for handling Weather Data
import 'package:intl/intl.dart';
import 'package:weather_app/models/location.dart';

class CurrentWeather {
  final double temperature;
  final double rainfall;
  final double uvIndex;
  final double pollenCount;
  final int airQualityIndex;
  final bool isDay;
  final double windSpeed;
  final int cloudCover;
  final DateTime time;

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

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: json['temperature_2m'] ?? 0.0,
      rainfall: json['rain'] ?? 0.0,
      uvIndex: json['uv_index'] ?? 0.0,
      pollenCount: json['pollen_count'] ?? 0.0,
      airQualityIndex: json['air_quality_index'] ?? 0,
      isDay: json['is_day'] == 1,
      windSpeed: json['wind_speed_10m'] ?? 0.0,
      cloudCover: json['cloud_cover'] ?? 0,
      time: DateTime.parse(json['time']),
    );
  }

  String get formattedTime => DateFormat.Hm().format(time);
  String get formattedDate => DateFormat.yMMMd().format(time);
}

class HourlyForecast {
  final double temperature;
  final double windSpeed;
  final int cloudCover;
  final double rainProbability;
  final bool isDay;
  final DateTime time;

  HourlyForecast({
    required this.temperature,
    required this.windSpeed,
    required this.cloudCover,
    required this.rainProbability,
    required this.isDay,
    required this.time,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      temperature: json['temperature_2m'] ?? 0.0,
      windSpeed: json['wind_speed_10m'] ?? 0.0,
      cloudCover: json['cloud_cover'] ?? 0,
      rainProbability: json['precipitation_probability'] ?? 0.0,
      isDay: json['is_day'] == 1,
      time: DateTime.parse(json['time']),
    );
  }

  String get formattedTime => DateFormat.Hm().format(time);
  String get formattedDay => DateFormat.E().format(time);
}

class DailyForecast {
  final double minTemperature;
  final double maxTemperature;
  final double windSpeed;
  final double rainProbability;
  final double uvIndex;
  final int cloudCover;
  final DateTime date;

  DailyForecast({
    required this.minTemperature,
    required this.maxTemperature,
    required this.windSpeed,
    required this.rainProbability,
    required this.uvIndex,
    required this.cloudCover,
    required this.date,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      minTemperature: json['temperature_2m_min'] ?? 0.0,
      maxTemperature: json['temperature_2m_max'] ?? 0.0,
      windSpeed: json['wind_speed_10m_max'] ?? 0.0,
      rainProbability: json['precipitation_probability_max'] ?? 0.0,
      uvIndex: json['uv_index_max'] ?? 0.0,
      cloudCover: json['cloud_cover_max'] ?? 0,
      date: DateTime.parse(json['time']),
    );
  }

  String get formattedDate => DateFormat.MMMd().format(date);
  String get formattedDay => DateFormat.E().format(date);
}

class WeatherData {
  final CurrentWeather current;
  final List<HourlyForecast> hourlyForecast;
  final List<DailyForecast> dailyForecast;
  final Location location;

  WeatherData({
    required this.current,
    required this.hourlyForecast,
    required this.dailyForecast,
    required this.location,
  });
}
