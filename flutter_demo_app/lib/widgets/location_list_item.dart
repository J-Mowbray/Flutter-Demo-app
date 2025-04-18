import 'package:flutter/material.dart';
import '../models/location.dart';
import '../models/weather_data.dart';
import 'weather_icon.dart';

class LocationListItem extends StatelessWidget {
  final Location location;
  final CurrentWeather? weather;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const LocationListItem({
    super.key,
    required this.location,
    this.weather,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color:
          isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              if (location.isCurrent)
                Icon(
                  Icons.my_location,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...location.name
                        .split(', ')
                        .map(
                          (part) => Text(
                            part.trim(), // Remove extra spaces
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color:
                                  isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            softWrap: true, // Allow wrapping
                          ),
                        ),
                    if (weather != null)
                      Text(
                        '${weather!.temperature.toStringAsFixed(1)}°C | ${weather!.isDay ? 'Day' : 'Night'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (weather != null)
                WeatherIcon(
                  cloudCover: weather!.cloudCover,
                  rainProbability: weather!.rainfall * 10,
                  isDay: weather!.isDay,
                  size: 30,
                ),
              if (onDelete != null && !location.isCurrent)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Remove location',
                  color:
                      isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
