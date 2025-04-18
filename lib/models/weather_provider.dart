import 'package:flutter/foundation.dart';
import '../models/weather_data.dart';
import '../models/location.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import 'dart:async';
import 'dart:collection';

/// Defines the types of weather forecasts available in the application.
enum ForecastType { hourly, daily }

/// Manages the state of weather data across the application.
///
/// This provider handles location management, weather data fetching,
/// and caching strategies to optimize network requests.
class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  /// Cache management for weather data
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

  /// Optimization to prevent concurrent API operations
  bool _refreshInProgress = false;
  final Queue<VoidCallback> _pendingOperations = Queue<VoidCallback>();

  /// Public getters for state access
  Location? get currentLocation => _currentLocation;
  List<Location> get savedLocations => _savedLocations;
  Map<String, WeatherData> get weatherData => _weatherData;
  Location? get selectedLocation => _selectedLocation;
  ForecastType get forecastType => _forecastType;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Location> get searchResults => _searchResults;

  /// Returns weather data for the currently selected location
  WeatherData? get selectedLocationWeatherData {
    if (_selectedLocation == null) return null;
    return _weatherData[_getLocationKey(_selectedLocation!)];
  }

  /// Creates a unique identifier for a location based on coordinates
  String _getLocationKey(Location location) {
    return '${location.latitude},${location.longitude}';
  }

  /// Determines if cached weather data needs to be refreshed
  bool _isDataStale(String locationKey) {
    if (!_lastUpdateTimes.containsKey(locationKey)) return true;

    final lastUpdate = _lastUpdateTimes[locationKey]!;
    final now = DateTime.now();
    return now.difference(lastUpdate) > _cacheValidDuration;
  }

  /// Initializes the provider by loading current and saved locations
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
      /// Fetch current and saved locations concurrently
      final results = await Future.wait([
        _locationService.getCurrentLocation(),
        _locationService.getSavedLocations(),
      ]);

      _currentLocation = results[0] as Location;
      _savedLocations = results[1] as List<Location>;

      if (kDebugMode) {
        print('WeatherProvider: Current location: ${_currentLocation?.name}');
      }

      /// Default to current location when app starts
      _selectedLocation = _currentLocation;

      /// Consolidate all locations for weather fetching
      final locationsToFetch = [
        if (_currentLocation != null) _currentLocation!,
        ..._savedLocations,
      ];

      /// Prioritize fetching data for the selected location
      if (_selectedLocation != null) {
        await fetchWeatherData(_selectedLocation!);
      }

      /// Fetch remaining locations in background
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

      /// Handle any operations queued during execution
      _processPendingOperations();
    }
  }

  /// Executes operations that were queued during an ongoing operation
  void _processPendingOperations() {
    if (_pendingOperations.isNotEmpty) {
      final operation = _pendingOperations.removeFirst();
      operation();
    }
  }

  /// Fetches weather data for a specific location
  /// Notifies listeners if this is the selected location
  Future<void> fetchWeatherData(Location location) async {
    final locationKey = _getLocationKey(location);

    try {
      /// Use cached data if it's still valid
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

      /// Only notify if this affects currently visible data
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

  /// Fetches weather data for multiple locations concurrently
  Future<void> _fetchWeatherForMultipleLocations(
    List<Location> locations,
  ) async {
    /// Filter to locations that need updates
    final locationsToUpdate =
        locations.where((loc) {
          final key = _getLocationKey(loc);
          return _isDataStale(key);
        }).toList();

    if (locationsToUpdate.isEmpty) return;

    /// Create futures for parallel execution
    final futures = locationsToUpdate.map(
      (location) => _fetchWeatherDataSilently(location),
    );

    /// Execute all fetches concurrently
    await Future.wait(futures);

    /// Update UI once all fetches complete
    notifyListeners();
  }

  /// Fetches weather data without triggering UI updates
  /// Used for batch operations to avoid multiple rebuilds
  Future<void> _fetchWeatherDataSilently(Location location) async {
    final locationKey = _getLocationKey(location);

    try {
      /// Skip if data is already fresh
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

  /// Adds a new location to saved locations
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

  /// Removes a location from saved locations
  Future<void> removeLocation(Location location) async {
    try {
      await _locationService.removeLocation(location);
      _savedLocations = await _locationService.getSavedLocations();

      _weatherData.remove(_getLocationKey(location));
      _lastUpdateTimes.remove(_getLocationKey(location));

      /// Switch to current location if the removed location was selected
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

  /// Sets the active location for displaying weather data
  void selectLocation(Location location) {
    _selectedLocation = location;

    /// Fetch fresh data if needed
    final locationKey = _getLocationKey(location);
    if (_isDataStale(locationKey)) {
      fetchWeatherData(location);
    } else {
      notifyListeners();
    }
  }

  /// Switches between hourly and daily forecast views
  void toggleForecastType() {
    _forecastType =
        _forecastType == ForecastType.daily
            ? ForecastType.hourly
            : ForecastType.daily;
    notifyListeners();
  }

  /// Refreshes weather data for all locations
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
      /// First check if device location has changed
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

          /// Update current location reference
          _currentLocation = freshLocation;

          /// Invalidate cache for this location
          _lastUpdateTimes.remove(_getLocationKey(freshLocation));

          /// Update selected location if it was current location
          if (_selectedLocation?.isCurrent == true) {
            _selectedLocation = freshLocation;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error refreshing current location: $e');
        }
      }

      /// Get updated saved locations list
      _savedLocations = await _locationService.getSavedLocations();

      /// Consolidate all locations to refresh
      final locationsToRefresh = [
        if (_currentLocation != null) _currentLocation!,
        ..._savedLocations.where(
          (loc) =>
              _currentLocation == null ||
              _getLocationKey(loc) != _getLocationKey(_currentLocation!),
        ),
      ];

      /// Prioritize refreshing the selected location
      if (_selectedLocation != null) {
        /// Invalidate cache to force refresh
        _lastUpdateTimes.remove(_getLocationKey(_selectedLocation!));
        await fetchWeatherData(_selectedLocation!);
      }

      /// Refresh remaining locations in parallel
      final otherLocations =
          locationsToRefresh
              .where(
                (loc) =>
                    _selectedLocation == null ||
                    _getLocationKey(loc) != _getLocationKey(_selectedLocation!),
              )
              .toList();

      if (otherLocations.isNotEmpty) {
        /// Invalidate cache for all locations
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

      /// Process queued operations
      _processPendingOperations();
    }
  }

  /// Refreshes weather data only for the currently selected location
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
      /// Check for device location changes
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

          /// Update current location reference
          _currentLocation = freshLocation;

          /// Invalidate cache
          _lastUpdateTimes.remove(_getLocationKey(freshLocation));

          /// Handle if selected location is current location
          if (_selectedLocation!.isCurrent) {
            _selectedLocation = freshLocation;
            await fetchWeatherData(freshLocation);
          } else {
            /// Update current location in background
            fetchWeatherData(freshLocation);

            /// Force refresh of selected location
            _lastUpdateTimes.remove(_getLocationKey(_selectedLocation!));
            await fetchWeatherData(_selectedLocation!);
          }
        } else {
          /// Location hasn't changed, just refresh selected location
          _lastUpdateTimes.remove(_getLocationKey(_selectedLocation!));
          await fetchWeatherData(_selectedLocation!);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error refreshing current location: $e');
        }

        /// Fall back to just refreshing selected location
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

      /// Process queued operations
      _processPendingOperations();
    }
  }

  /// Performs location search based on user query
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

      /// Process queued operations
      _processPendingOperations();
    }
  }

  /// Clears the location search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  /// Updates the loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
  }
}
