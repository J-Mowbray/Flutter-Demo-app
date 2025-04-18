import 'package:flutter/material.dart';

class WeatherIcon extends StatelessWidget {
  final int cloudCover;
  final double rainProbability;
  final bool isDay;
  final double size;

  const WeatherIcon({
    super.key,
    required this.cloudCover,
    required this.rainProbability,
    required this.isDay,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    if (rainProbability > 50) {
      // Rainy weather
      icon = Icons.thunderstorm;
      color = Colors.blueGrey;
    } else if (cloudCover > 70) {
      // Cloudy weather
      icon = Icons.cloud;
      color = Colors.grey;
    } else if (cloudCover > 30) {
      // Partly cloudy
      icon = isDay ? Icons.wb_cloudy : Icons.nights_stay;
      color = isDay ? Colors.orange : Colors.indigo;
    } else {
      // Clear sky
      icon = isDay ? Icons.wb_sunny : Icons.nights_stay;
      color = isDay ? Colors.orange : Colors.indigo;
    }

    return Icon(icon, size: size, color: color);
  }
}
