import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import 'weather_icon.dart';
import '../models/weather_provider.dart';

class ForecastTimeline extends StatelessWidget {
  final List<HourlyForecast> hourlyForecasts;
  final List<DailyForecast> dailyForecasts;
  final ForecastType forecastType;
  final VoidCallback onToggleForecastType;

  const ForecastTimeline({
    super.key,
    required this.hourlyForecasts,
    required this.dailyForecasts,
    required this.forecastType,
    required this.onToggleForecastType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child:
              forecastType == ForecastType.hourly
                  ? _buildHourlyTimeline(context)
                  : _buildDailyTimeline(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Forecast at A Glance',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        TextButton.icon(
          onPressed: onToggleForecastType,
          icon: Icon(
            forecastType == ForecastType.hourly
                ? Icons.calendar_today
                : Icons.access_time,
          ),
          label: Text(
            forecastType == ForecastType.hourly ? 'Show 7-Day' : 'Show Hourly',
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyTimeline(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: hourlyForecasts.length,
      itemBuilder: (context, index) {
        final forecast = hourlyForecasts[index];
        return _buildHourlyItem(context, forecast);
      },
    );
  }

  Widget _buildDailyTimeline(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: dailyForecasts.length,
      itemBuilder: (context, index) {
        final forecast = dailyForecasts[index];
        return _buildDailyItem(context, forecast);
      },
    );
  }

  Widget _buildHourlyItem(BuildContext context, HourlyForecast forecast) {
    final theme = Theme.of(context);

    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            forecast.formattedTime,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          WeatherIcon(
            cloudCover: forecast.cloudCover,
            rainProbability: forecast.rainProbability,
            isDay: forecast.isDay,
          ),
          const SizedBox(height: 8),
          Text(
            '${forecast.temperature.toStringAsFixed(1)}°C',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop,
                size: 12,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${forecast.rainProbability.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyItem(BuildContext context, DailyForecast forecast) {
    final theme = Theme.of(context);

    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            forecast.formattedDay,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(forecast.formattedDate, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          WeatherIcon(
            cloudCover: forecast.cloudCover,
            rainProbability: forecast.rainProbability,
            isDay: true, // Showing day icon for daily forecast
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${forecast.minTemperature.toStringAsFixed(0)}°C',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(' / '),
              Text(
                '${forecast.maxTemperature.toStringAsFixed(0)}°C',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop,
                size: 12,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${forecast.rainProbability.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
