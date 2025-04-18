import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_provider.dart';
import '../models/weather_data.dart';
import '../widgets/weather_icon.dart';

/// Detailed forecast screen showing hourly and daily weather predictions.
///
/// Provides a comprehensive view of upcoming weather conditions with
/// the ability to toggle between hourly and daily forecast views.
class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detailed Forecast')),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          final selectedLocation = weatherProvider.selectedLocation;
          final weatherData = weatherProvider.selectedLocationWeatherData;

          /// Display a message when weather data is unavailable.
          if (selectedLocation == null || weatherData == null) {
            return const Center(child: Text('No weather data available'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header with location name, date, current temperature and weather icon.
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Split location name by commas and display each part on a new line.
                        ...selectedLocation.name
                            .split(', ')
                            .map(
                              (part) => Text(
                                part.trim(),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontSize: 20),
                                softWrap: true,
                              ),
                            ),
                        Text(
                          weatherData.current.formattedDate,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: 0.7 * 255),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        WeatherIcon(
                          cloudCover: weatherData.current.cloudCover,
                          rainProbability: weatherData.current.rainfall * 10,
                          isDay: weatherData.current.isDay,
                          size: 36,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${weatherData.current.temperature.toStringAsFixed(1)}°',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              /// Toggle buttons for switching between hourly and daily forecasts.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (weatherProvider.forecastType !=
                              ForecastType.hourly) {
                            weatherProvider.toggleForecastType();
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: const Text('Hourly'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              weatherProvider.forecastType ==
                                      ForecastType.hourly
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer
                                  : null,
                          foregroundColor:
                              weatherProvider.forecastType ==
                                      ForecastType.hourly
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                  : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (weatherProvider.forecastType !=
                              ForecastType.daily) {
                            weatherProvider.toggleForecastType();
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('7 Days'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              weatherProvider.forecastType == ForecastType.daily
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer
                                  : null,
                          foregroundColor:
                              weatherProvider.forecastType == ForecastType.daily
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Display either hourly or daily forecast based on selected type.
              Expanded(
                child:
                    weatherProvider.forecastType == ForecastType.hourly
                        ? _buildHourlyForecast(
                          context,
                          weatherData.hourlyForecast,
                        )
                        : _buildDailyForecast(
                          context,
                          weatherData.dailyForecast,
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds a scrollable list of hourly forecasts.
  ///
  /// Creates a ListView of hourly weather predictions for the next 24 hours.
  Widget _buildHourlyForecast(
    BuildContext context,
    List<HourlyForecast> forecasts,
  ) {
    return ListView.builder(
      itemCount: forecasts.length,
      itemBuilder: (context, index) {
        final forecast = forecasts[index];
        return _buildHourlyForecastItem(context, forecast);
      },
    );
  }

  /// Creates a card for a single hourly forecast entry.
  ///
  /// Displays time, day, temperature, wind speed, cloud cover,
  /// rain probability and a weather icon for the hour.
  Widget _buildHourlyForecastItem(
    BuildContext context,
    HourlyForecast forecast,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            /// Time and day column.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  forecast.formattedTime,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(forecast.formattedDay, style: theme.textTheme.bodyMedium),
              ],
            ),
            const Spacer(),

            /// Weather metrics with icons.
            Row(
              children: [
                _buildInfoColumn(
                  context,
                  icon: Icons.thermostat,
                  value: '${forecast.temperature.toStringAsFixed(1)}°C',
                  label: 'Temp',
                ),
                const SizedBox(width: 16),
                _buildInfoColumn(
                  context,
                  icon: Icons.air,
                  value: '${forecast.windSpeed.toStringAsFixed(1)} mp/h',
                  label: 'Wind',
                ),
                const SizedBox(width: 16),
                _buildInfoColumn(
                  context,
                  icon: Icons.cloud,
                  value: '${forecast.cloudCover}%',
                  label: 'Clouds',
                ),
                const SizedBox(width: 16),
                _buildInfoColumn(
                  context,
                  icon: Icons.water_drop,
                  value: '${forecast.rainProbability.toStringAsFixed(0)}%',
                  label: 'Rain',
                ),
              ],
            ),
            const SizedBox(width: 16),

            /// Weather condition icon.
            WeatherIcon(
              cloudCover: forecast.cloudCover,
              rainProbability: forecast.rainProbability,
              isDay: forecast.isDay,
              size: 36,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a scrollable list of daily forecasts.
  ///
  /// Creates a ListView of daily weather predictions for the next 7 days.
  Widget _buildDailyForecast(
    BuildContext context,
    List<DailyForecast> forecasts,
  ) {
    return ListView.builder(
      itemCount: forecasts.length,
      itemBuilder: (context, index) {
        final forecast = forecasts[index];
        return _buildDailyForecastItem(context, forecast);
      },
    );
  }

  /// Creates a card for a single daily forecast entry.
  ///
  /// Displays the day, date, temperature range, and meteorological data
  /// including wind, cloud cover, precipitation, and UV index.
  Widget _buildDailyForecastItem(BuildContext context, DailyForecast forecast) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                /// Day and date column.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forecast.formattedDay,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      forecast.formattedDate,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
                const Spacer(),

                /// Weather icon based on conditions.
                WeatherIcon(
                  cloudCover: forecast.cloudCover,
                  rainProbability: forecast.rainProbability,
                  isDay: true,
                  size: 40,
                ),
                const SizedBox(width: 16),

                /// Temperature range column.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${forecast.maxTemperature.toStringAsFixed(1)}°C',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${forecast.minTemperature.toStringAsFixed(1)}°C',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// Row of detailed weather metrics.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn(
                  context,
                  icon: Icons.air,
                  value: '${forecast.windSpeed.toStringAsFixed(1)} mp/h',
                  label: 'Wind',
                ),
                _buildInfoColumn(
                  context,
                  icon: Icons.cloud,
                  value: '${forecast.cloudCover}%',
                  label: 'Clouds',
                ),
                _buildInfoColumn(
                  context,
                  icon: Icons.water_drop,
                  value: '${forecast.rainProbability.toStringAsFixed(0)}%',
                  label: 'Rain',
                ),
                _buildInfoColumn(
                  context,
                  icon: Icons.wb_sunny,
                  value: forecast.uvIndex.toStringAsFixed(1),
                  label: 'UV Index',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a column displaying a weather metric with an icon, value and label.
  ///
  /// Used for consistently formatting various weather measurements
  /// throughout the forecast display.
  Widget _buildInfoColumn(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7 * 255),
          ),
        ),
      ],
    );
  }
}
