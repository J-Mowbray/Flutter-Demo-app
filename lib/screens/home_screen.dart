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

/// Main screen of the weather application.
///
/// Displays the weather for the currently selected location at the top, followed by
/// an hourly or daily forecast timeline and a list of saved locations below.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    /// Schedule initialisation after the first frame to ensure context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(context), body: _buildBody(context));
  }

  /// Constructs the application bar with title and action buttons.
  ///
  /// Includes refresh and add location buttons for quick access to common actions.
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

  /// Builds the main body of the home screen using Consumer for reactive updates.
  ///
  /// Responds to changes in the WeatherProvider state, displaying appropriate
  /// content based on loading status, errors, and data availability.
  Widget _buildBody(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        /// Show loading indicator when initialising and no location is selected.
        if (weatherProvider.isLoading &&
            weatherProvider.selectedLocation == null) {
          return const Center(child: CircularProgressIndicator());
        }

        /// Show error view when there's an error and no location is selected.
        if (weatherProvider.error != null &&
            weatherProvider.selectedLocation == null) {
          return _buildErrorView(context, weatherProvider);
        }

        final selectedLocation = weatherProvider.selectedLocation;
        final weatherData = weatherProvider.selectedLocationWeatherData;

        /// Show message when no location is selected or weather data is unavailable.
        if (selectedLocation == null || weatherData == null) {
          return const Center(child: Text('No location selected'));
        }

        /// Show main weather view when all data is available.
        return _buildWeatherView(
          context,
          weatherProvider,
          selectedLocation,
          weatherData,
        );
      },
    );
  }

  /// Constructs an error display with details and retry button.
  ///
  /// Provides clear visual feedback about the error and offers
  /// a way to retry the operation that failed.
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

  /// Builds the main weather display when data is successfully loaded.
  ///
  /// Includes a pull-to-refresh mechanism, current weather card, forecast
  /// timeline, and a list of saved locations below.
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
          /// Current weather display for the selected location.
          CurrentWeatherCard(
            weather: weatherData.current,
            locationName: selectedLocation.name,
            onTap: () {
              if (kDebugMode) {
                print(
                  'HomeScreen: Tapped on location - ${selectedLocation.name}',
                );
              }
              weatherProvider.selectLocation(selectedLocation);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForecastScreen()),
              );
            },
          ),
          const SizedBox(height: 16),

          /// Forecast timeline showing hourly or daily predictions.
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

          /// List of saved locations for quick access.
          _buildSavedLocationsList(context, weatherProvider),
        ],
      ),
    );
  }

  /// Builds the saved locations list section.
  ///
  /// Combines current location (if available) with user-saved locations
  /// and displays them in a scrollable list with appropriate controls.
  Widget _buildSavedLocationsList(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) {
    /// Combine current location and saved locations into a single list.
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

        /// Show message when no locations are available.
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
          /// Build list of location items with their current weather.
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

                /// Allow deletion for saved locations but not current location.
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

        /// Show 'Add Location' button if there are fewer than 5 locations.
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

  /// Navigates to the search screen to add new locations.
  void _navigateToSearchScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  /// Displays a confirmation dialog before removing a saved location.
  ///
  /// Ensures the user has an opportunity to cancel an accidental deletion
  /// before the location is permanently removed from their saved list.
  void _confirmDeleteLocation(
    BuildContext context,
    WeatherProvider weatherProvider,
    Location location,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Location', textAlign: TextAlign.center),
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
