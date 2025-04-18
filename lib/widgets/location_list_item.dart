import 'package:flutter/material.dart';
import '../models/location.dart';
import '../models/weather_data.dart';
import 'weather_icon.dart';

/// A widget that displays a location with its current weather in a list.
///
/// Presents location name, current temperature, weather condition icons,
/// and provides selection and deletion capabilities.
class LocationListItem extends StatelessWidget {
  /// The location to be displayed.
  final Location location;

  /// Current weather data for this location, if available.
  final CurrentWeather? weather;

  /// Whether this location is currently selected.
  final bool isSelected;

  /// Callback executed when the user taps on this item.
  final VoidCallback onTap;

  /// Optional callback executed when the user tries to delete this location.
  final VoidCallback? onDelete;

  /// Creates a new LocationListItem widget.
  ///
  /// The [location], [isSelected], and [onTap] parameters are required.
  /// Weather data and deletion callback are optional.
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
              /// Display current location indicator if this is the user's current location
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
                    // Split location name into parts and display each on its own line
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

                    /// Display temperature and day/night status if weather data is available
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

              /// Display weather condition icon if weather data is available
              if (weather != null)
                WeatherIcon(
                  cloudCover: weather!.cloudCover,
                  rainProbability: weather!.rainfall * 10,
                  isDay: weather!.isDay,
                  size: 30,
                ),

              /// Display delete button except for current location
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
