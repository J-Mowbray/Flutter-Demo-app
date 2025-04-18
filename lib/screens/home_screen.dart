import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/models/weather_data.dart';
import '../models/weather_provider.dart';
import '../models/location.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/forecast_timeline.dart';
import '../widgets/location_list_item.dart';
import 'search_screen.dart';
import 'forecast_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialise weather data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context), // Extracted AppBar
      body: _buildBody(context), // Extracted Body
    );
  }

  // Extracted AppBar Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Weather App'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            Provider.of<WeatherProvider>(
              context,
              listen: false,
            ).refreshAllWeatherData();
          },
          tooltip: 'Refresh weather',
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _navigateToSearchScreen(context),
          tooltip: 'Add location',
        ),
      ],
    );
  }

  // Extracted Body Widget
  Widget _buildBody(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        if (weatherProvider.isLoading &&
            weatherProvider.selectedLocation == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (weatherProvider.error != null &&
            weatherProvider.selectedLocation == null) {
          return _buildErrorView(
            context,
            weatherProvider,
          ); // Extracted Error View
        }

        final selectedLocation = weatherProvider.selectedLocation;
        final weatherData = weatherProvider.selectedLocationWeatherData;

        if (selectedLocation == null || weatherData == null) {
          return const Center(child: Text('No location selected'));
        }

        return _buildWeatherView(
          context,
          weatherProvider,
          selectedLocation,
          weatherData,
        ); // Extracted Weather View
      },
    );
  }

  // Extracted Error View Widget
  Widget _buildErrorView(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading weather data',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(weatherProvider.error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              weatherProvider.initialize();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Extracted Weather View Widget
  Widget _buildWeatherView(
    BuildContext context,
    WeatherProvider weatherProvider,
    Location selectedLocation,
    WeatherData weatherData,
  ) {
    return RefreshIndicator(
      onRefresh: () {
        return weatherProvider.refreshSelectedLocationWeatherData();
      },
      child: ListView(
        children: [
          CurrentWeatherCard(
            weather: weatherData.current,
            locationName: selectedLocation.name,
            onTap: () {
              if (kDebugMode) {
                print(
                  'HomeScreen: Tapped on location - ${selectedLocation.name}',
                );
              } // Print here
              weatherProvider.selectLocation(
                selectedLocation,
              ); // Ensure location is selected
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForecastScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ForecastTimeline(
              hourlyForecasts: weatherData.hourlyForecast,
              dailyForecasts: weatherData.dailyForecast,
              forecastType: weatherProvider.forecastType,
              onToggleForecastType: () {
                weatherProvider.toggleForecastType();
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSavedLocationsList(context, weatherProvider),
        ],
      ),
    );
  }

  // Existing _buildSavedLocationsList (No significant changes needed)
  Widget _buildSavedLocationsList(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) {
    final locations = [
      if (weatherProvider.currentLocation != null)
        weatherProvider.currentLocation!,
      ...weatherProvider.savedLocations,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Locations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (locations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No saved locations',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              final locationKey = '${location.latitude},${location.longitude}';
              final weatherData = weatherProvider.weatherData[locationKey];
              final currentWeather = weatherData?.current;

              return LocationListItem(
                location: location,
                weather: currentWeather,
                isSelected:
                    weatherProvider.selectedLocation?.latitude ==
                        location.latitude &&
                    weatherProvider.selectedLocation?.longitude ==
                        location.longitude,
                onTap: () {
                  weatherProvider.selectLocation(location);
                },
                onDelete:
                    !location.isCurrent
                        ? () => _confirmDeleteLocation(
                          context,
                          weatherProvider,
                          location,
                        )
                        : null,
              );
            },
          ),
        const SizedBox(height: 16),
        if (locations.length < 5)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _navigateToSearchScreen(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Location'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
      ],
    );
  }

  // Navigation Method (No changes needed)
  void _navigateToSearchScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  // Confirmation Dialog (No significant changes needed)
  void _confirmDeleteLocation(
      BuildContext context,
      WeatherProvider weatherProvider,
      Location location,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Location',
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Do you want to remove:'),
            const SizedBox(height: 8),
            Text(
              location.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('from your saved locations?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              weatherProvider.removeLocation(location);
              Navigator.of(context).pop();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}