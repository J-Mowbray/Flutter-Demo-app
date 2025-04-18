import 'package:flutter/foundation.dart';
import '../models/weather_data.dart';
import '../models/location.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import 'dart:async';
import 'dart:collection';

enum ForecastType { hourly, daily }

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  // Cache time control
  final Map<String, DateTime> _lastUpdateTimes = {};
  final Duration _cacheValidDuration = const Duration(minutes: 15);

  Location? _currentLocation;
  List<Location> _savedLocations = [];
  final Map<String, WeatherData> _weatherData = {};
  Location? _selectedLocation;
  ForecastType _forecastType = ForecastType.daily;
  bool _isLoading = true;
  String? _error;
  List<Location> _searchResults = [];

  // Refresh optimization flags
  bool _refreshInProgress = false;
  final Queue<VoidCallback> _pendingOperations = Queue<VoidCallback>();

  // Getters
  Location? get currentLocation => _currentLocation;
  List<Location> get savedLocations => _savedLocations;
  Map<String, WeatherData> get weatherData => _weatherData;
  Location? get selectedLocation => _selectedLocation;
  ForecastType get forecastType => _forecastType;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Location> get searchResults => _searchResults;

  WeatherData? get selectedLocationWeatherData {
    if (_selectedLocation == null) return null;
    return _weatherData[_getLocationKey(_selectedLocation!)];
  }

  String _getLocationKey(Location location) {
    return '${location.latitude},${location.longitude}';
  }

  // Check if data is stale and needs update
  bool _isDataStale(String locationKey) {
    if (!_lastUpdateTimes.containsKey(locationKey)) return true;

    final lastUpdate = _lastUpdateTimes[locationKey]!;
    final now = DateTime.now();
    return now.difference(lastUpdate) > _cacheValidDuration;
  }

  // Initialize the provider
  Future<void> initialize() async {
    if (_refreshInProgress) {
      _pendingOperations.add(() => initialize());
      return;
    }

    _refreshInProgress = true;
    if (kDebugMode) {
      print('WeatherProvider: Initializing...');
    }
    _setLoading(true);

    try {
      // Get current location and saved locations in parallel
      final results = await Future.wait([
        _locationService.getCurrentLocation(),
        _locationService.getSavedLocations(),
      ]);

      _currentLocation = results[0] as Location;
      _savedLocations = results[1] as List<Location>;

      if (kDebugMode) {
        print('WeatherProvider: Current location: ${_currentLocation?.name}');
      }

      // Set selected location to current location
      _selectedLocation = _currentLocation;

      // Create a list of all locations to fetch weather for
      final locationsToFetch = [
        if (_currentLocation != null) _currentLocation!,
        ..._savedLocations,
      ];

      // Fetch weather data for the selected location first
      if (_selectedLocation != null) {
        await fetchWeatherData(_selectedLocation!);
      }

      // Pre-fetch other locations in background
      final otherLocations =
          locationsToFetch
              .where(
                (loc) =>
                    _selectedLocation == null ||
                    _getLocationKey(loc) != _getLocationKey(_selectedLocation!),
              )
              .toList();

      if (otherLocations.isNotEmpty) {
        _fetchWeatherForMultipleLocations(otherLocations);
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to initialize weather data: $e';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      _setLoading(false);
      _refreshInProgress = false;
      notifyListeners();

      // Process any pending operations
      _processPendingOperations();
    }
  }

  // Process any pending operations in the queue
  void _processPendingOperations() {
    if (_pendingOperations.isNotEmpty) {
      final operation = _pendingOperations.removeFirst();
      operation();
    }
  }

  // Fetch weather data for a location
  Future<void> fetchWeatherData(Location location) async {
    final locationKey = _getLocationKey(location);

    try {
      // Skip fetch if data is recent enough
      if (_weatherData.containsKey(locationKey) && !_isDataStale(locationKey)) {
        if (kDebugMode) {
          print('Using cached data for ${location.name}');
        }
        return;
      }

      if (kDebugMode) {
        print('Fetching weather for ${location.name}');
      }

      WeatherData data = await _weatherService.getCompleteWeatherData(location);

      _weatherData[locationKey] = data;
      _lastUpdateTimes[locationKey] = DateTime.now();

      // If this is the selected location, notify listeners immediately
      if (_selectedLocation != null &&
          _getLocationKey(_selectedLocation!) == locationKey) {
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch weather data for ${location.name}: $e');
      }
    }
  }

  // Helper to fetch weather for multiple locations concurrently
  Future<void> _fetchWeatherForMultipleLocations(
    List<Location> locations,
  ) async {
    // Filter to only locations that need updates
    final locationsToUpdate =
        locations.where((loc) {
          final key = _getLocationKey(loc);
          return _isDataStale(key);
        }).toList();

    if (locationsToUpdate.isEmpty) return;

    // Create a list of futures for concurrent execution
    final futures = locationsToUpdate.map(
      (location) => _fetchWeatherDataSilently(location),
    );

    // Wait for all fetches to complete
    await Future.wait(futures);

    // Notify listeners once at the end for all updates
    notifyListeners();
  }

  // Silent version that doesn't notify listeners (for batch operations)
  Future<void> _fetchWeatherDataSilently(Location location) async {
    final locationKey = _getLocationKey(location);

    try {
      // Skip fetch if data is recent enough
      if (_weatherData.containsKey(locationKey) && !_isDataStale(locationKey)) {
        return;
      }

      WeatherData data = await _weatherService.getCompleteWeatherData(location);
      _weatherData[locationKey] = data;
      _lastUpdateTimes[locationKey] = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch weather for ${location.name}: $e');
      }
    }
  }

  // Add a new location
  Future<void> addLocation(Location location) async {
    try {
      await _locationService.addLocation(location);
      _savedLocations = await _locationService.getSavedLocations();
      await fetchWeatherData(location);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add location: $e';
      notifyListeners();
    }
  }

  // Remove a location
  Future<void> removeLocation(Location location) async {
    try {
      await _locationService.removeLocation(location);
      _savedLocations = await _locationService.getSavedLocations();

      _weatherData.remove(_getLocationKey(location));
      _lastUpdateTimes.remove(_getLocationKey(location));

      // If the removed location was selected, switch to current location
      if (_selectedLocation?.latitude == location.latitude &&
          _selectedLocation?.longitude == location.longitude) {
        _selectedLocation = _currentLocation;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove location: $e';
      notifyListeners();
    }
  }

  // Select a location
  void selectLocation(Location location) {
    _selectedLocation = location;

    // Pre-fetch data if needed
    final locationKey = _getLocationKey(location);
    if (_isDataStale(locationKey)) {
      fetchWeatherData(location);
    } else {
      notifyListeners();
    }
  }

  // Toggle forecast type
  void toggleForecastType() {
    _forecastType =
        _forecastType == ForecastType.daily
            ? ForecastType.hourly
            : ForecastType.daily;
    notifyListeners();
  }

  // Refresh weather data for all locations
  Future<void> refreshAllWeatherData() async {
    if (_refreshInProgress) {
      _pendingOperations.add(() => refreshAllWeatherData());
      return;
    }

    _refreshInProgress = true;
    if (kDebugMode) {
      print('WeatherProvider: refreshAllWeatherData called');
    }

    _setLoading(true);
    notifyListeners();

    try {
      // First, get a fresh current location
      try {
        final freshLocation = await _locationService.getCurrentLocation();
        final currentLocationChanged =
            _currentLocation == null ||
            freshLocation.latitude != _currentLocation!.latitude ||
            freshLocation.longitude != _currentLocation!.longitude;

        if (currentLocationChanged) {
          if (kDebugMode) {
            print('Current location changed: ${freshLocation.name}');
          }

          // Update current location
          _currentLocation = freshLocation;

          // Force refresh by removing cache entry
          _lastUpdateTimes.remove(_getLocationKey(freshLocation));

          // If current location is selected, update it too
          if (_selectedLocation?.isCurrent == true) {
            _selectedLocation = freshLocation;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error refreshing current location: $e');
        }
      }

      // Refresh saved locations list
      _savedLocations = await _locationService.getSavedLocations();

      // Create a list of all locations to refresh
      final locationsToRefresh = [
        if (_currentLocation != null) _currentLocation!,
        ..._savedLocations.where(
          (loc) =>
              _currentLocation == null ||
              _getLocationKey(loc) != _getLocationKey(_currentLocation!),
        ),
      ];

      // Refresh the selected location first for better UX
      if (_selectedLocation != null) {
        // Force refresh by marking as stale
        _lastUpdateTimes.remove(_getLocationKey(_selectedLocation!));
        await fetchWeatherData(_selectedLocation!);
      }

      // Then refresh other locations in parallel
      final otherLocations =
          locationsToRefresh
              .where(
                (loc) =>
                    _selectedLocation == null ||
                    _getLocationKey(loc) != _getLocationKey(_selectedLocation!),
              )
              .toList();

      if (otherLocations.isNotEmpty) {
        // Force refresh by marking all as stale
        for (var location in otherLocations) {
          _lastUpdateTimes.remove(_getLocationKey(location));
        }
        _fetchWeatherForMultipleLocations(otherLocations);
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to refresh weather data: $e';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      _setLoading(false);
      _refreshInProgress = false;
      notifyListeners();

      // Process any pending operations
      _processPendingOperations();
    }
  }

  // Refresh weather data for selected location
  Future<void> refreshSelectedLocationWeatherData() async {
    if (_selectedLocation == null) return;

    if (_refreshInProgress) {
      _pendingOperations.add(() => refreshSelectedLocationWeatherData());
      return;
    }

    _refreshInProgress = true;
    if (kDebugMode) {
      print(
        'WeatherProvider: refreshSelectedLocationWeatherData for ${_selectedLocation!.name}',
      );
    }

    _setLoading(true);
    notifyListeners();

    try {
      // Always try to get a fresh current location first
      try {
        final freshLocation = await _locationService.getCurrentLocation();
        final currentLocationChanged =
            _currentLocation == null ||
            freshLocation.latitude != _currentLocation!.latitude ||
            freshLocation.longitude != _currentLocation!.longitude;

        if (currentLocationChanged) {
          if (kDebugMode) {
            print('Current location changed: ${freshLocation.name}');
          }

          // Update current location
          _currentLocation = freshLocation;

          // Force refresh by removing cache entry
          _lastUpdateTimes.remove(_getLocationKey(freshLocation));

          // If the selected location is the current location, update it
          if (_selectedLocation!.isCurrent) {
            _selectedLocation = freshLocation;
            await fetchWeatherData(freshLocation);
          } else {
            // Update current location in background
            fetchWeatherData(freshLocation);

            // Force refresh selected location
            _lastUpdateTimes.remove(_getLocationKey(_selectedLocation!));
            await fetchWeatherData(_selectedLocation!);
          }
        } else {
          // Location hasn't changed, just refresh selected
          _lastUpdateTimes.remove(_getLocationKey(_selectedLocation!));
          await fetchWeatherData(_selectedLocation!);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error refreshing current location: $e');
        }
        // If getting fresh location fails, just refresh selected
        _lastUpdateTimes.remove(_getLocationKey(_selectedLocation!));
        await fetchWeatherData(_selectedLocation!);
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to refresh weather data: $e';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      _setLoading(false);
      _refreshInProgress = false;
      notifyListeners();

      // Process any pending operations
      _processPendingOperations();
    }
  }

  // Search for locations
  Future<void> searchLocations(String query) async {
    if (_refreshInProgress) {
      _pendingOperations.add(() => searchLocations(query));
      return;
    }

    _refreshInProgress = true;
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _locationService.searchLocation(query);
    } catch (e) {
      _error = 'Failed to search locations: $e';
    } finally {
      _setLoading(false);
      _refreshInProgress = false;
      notifyListeners();

      // Process any pending operations
      _processPendingOperations();
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
  }
}
