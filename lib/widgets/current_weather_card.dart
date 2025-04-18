import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import 'weather_icon.dart';

class CurrentWeatherCard extends StatelessWidget {
  final CurrentWeather weather;
  final String locationName;
  final VoidCallback onTap;

  const CurrentWeatherCard({
    super.key,
    required this.weather,
    required this.locationName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationName,
                          style: theme.textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${weather.formattedDate} | ${weather.formattedTime}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7 * 255),
                          ),
                        ),
                      ],
                    ),
                  ),
                  WeatherIcon(
                    cloudCover: weather.cloudCover,
                    rainProbability:
                        weather.rainfall *
                        10, // Converting to probability-like value
                    isDay: weather.isDay,
                    size: 50,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '${weather.temperature.toStringAsFixed(1)}°C',
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          context,
                          icon: Icons.water_drop,
                          label: 'Rainfall',
                          value: '${weather.rainfall} mm',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          context,
                          icon: Icons.air,
                          label: 'Wind',
                          value: '${weather.windSpeed.toStringAsFixed(1)} mp/h',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem(
                    context,
                    icon: Icons.wb_sunny,
                    label: 'UV Index',
                    value: weather.uvIndex.toStringAsFixed(1),
                  ),
                  _buildDetailItem(
                    context,
                    icon: Icons.grass,
                    label: 'Pollen',
                    value: weather.pollenCount.toStringAsFixed(1),
                  ),
                  _buildDetailItem(
                    context,
                    icon: Icons.air,
                    label: 'Air Quality',
                    value: weather.airQualityIndex.toString(),
                  ),
                  _buildDetailItem(
                    context,
                    icon: weather.isDay ? Icons.light_mode : Icons.dark_mode,
                    label: 'Light',
                    value: weather.isDay ? 'Day' : 'Night',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text('$label: $value', style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.secondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
