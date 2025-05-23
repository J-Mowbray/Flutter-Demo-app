import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:weather_app/models/location.dart' as app_location;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for handling location-related operations.
///
/// Provides functionality to obtain current device location, geocode coordinates,
/// search for locations, and manage saved location preferences.
class LocationService {
  /// Base URL for Open-Meteo geocoding API.
  static const String geocodingBaseUrl =
      'https://geocoding-api.open-meteo.com/v1';

  /// Formats location components into a consistent display format.
  ///
  /// Joins non-empty location components with commas and newlines.
  String _formatLocationName(List<String> parts) {
    return parts.where((part) => part.isNotEmpty).join(',\n');
  }

  /// Retrieves the user's current device location.
  ///
  /// Handles permission checks and returns a Location object with
  /// coordinates and a human-readable location name.
  Future<app_location.Location> getCurrentLocation() async {
    /// Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    /// Get current position
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    if (kDebugMode) {
      print('Position received: ${position.latitude}, ${position.longitude}');
    }

    /// First try using Open-Meteo API for reverse geocoding
    String locationName = await _getLocationNameFromOpenMeteo(
      position.latitude,
      position.longitude,
    );

    /// If Open-Meteo failed, fall back to platform geocoding
    if (locationName == 'Current Location') {
      locationName = await _getLocationNameFromPlatform(
        position.latitude,
        position.longitude,
      );
    }

    return app_location.Location(
      name: locationName,
      latitude: position.latitude,
      longitude: position.longitude,
      isCurrent: true,
    );
  }

  /// Attempts to get a location name from Open-Meteo's reverse geocoding API.
  ///
  /// Returns a formatted location string on success, or a default string on failure.
  Future<String> _getLocationNameFromOpenMeteo(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        '$geocodingBaseUrl/reverse?latitude=$latitude&longitude=$longitude&language=en',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          print('Open-Meteo reverse geocoding response: $data');
        }

        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];

          /// Extract the location components
          final String name = result['name'] ?? '';
          final String region = result['admin1'] ?? '';
          final String country = result['country'] ?? '';

          /// Build the location string with all available components
          if (name.isNotEmpty) {
            List<String> parts = [name];

            if (region.isNotEmpty) {
              parts.add(region);
            }

            if (country.isNotEmpty) {
              parts.add(country);
            }

            return _formatLocationName(parts);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error with Open-Meteo reverse geocoding: $e');
      }
    }

    return 'Current Location'; // Fallback if API fails
  }

  /// Attempts to get a location name using platform-specific geocoding services.
  ///
  /// Serves as a fallback when the Open-Meteo API is unavailable or fails.
  Future<String> _getLocationNameFromPlatform(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        if (kDebugMode) {
          print('Platform geocoding placemark: $place');
          print('Locality: ${place.locality}');
          print('SubLocality: ${place.subLocality}');
          print('AdministrativeArea: ${place.administrativeArea}');
          print('SubAdministrativeArea: ${place.subAdministrativeArea}');
          print('Country: ${place.country}');
        }

        /// Gather all available location components
        List<String> locationParts = [];

        /// City/Town
        if (place.locality != null && place.locality!.isNotEmpty) {
          locationParts.add(place.locality!);
        } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          locationParts.add(place.subLocality!);
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          locationParts.add(place.subAdministrativeArea!);
        }

        /// Region/State/Province
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          /// Avoid duplication if administrativeArea is the same as locality
          if (locationParts.isEmpty ||
              locationParts[0] != place.administrativeArea) {
            locationParts.add(place.administrativeArea!);
          }
        }

        /// Country
        if (place.country != null && place.country!.isNotEmpty) {
          locationParts.add(place.country!);
        }

        /// Format the location string with all components
        if (locationParts.isNotEmpty) {
          return _formatLocationName(locationParts);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error with platform geocoding: $e');
      }
    }

    return 'Current Location'; // Fallback if geocoding fails
  }

  /// Adds a location to the user's saved locations.
  ///
  /// Persists the location in SharedPreferences for later retrieval.
  /// Avoids duplicating locations with the same coordinates.
  Future<void> addLocation(app_location.Location location) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedLocations = prefs.getStringList('savedLocations') ?? [];

    /// Convert location to JSON string
    String locationJson = jsonEncode(location.toJson());

    /// Check if location already exists
    bool exists = savedLocations.any((item) {
      app_location.Location loc = app_location.Location.fromJson(
        jsonDecode(item),
      );
      return loc.latitude == location.latitude &&
          loc.longitude == location.longitude;
    });

    if (!exists) {
      savedLocations.add(locationJson);
      await prefs.setStringList('savedLocations', savedLocations);
    }
  }

  /// Removes a location from the user's saved locations.
  ///
  /// Deletes the location from SharedPreferences.
  Future<void> removeLocation(app_location.Location location) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedLocations = prefs.getStringList('savedLocations') ?? [];

    savedLocations.removeWhere((item) {
      app_location.Location loc = app_location.Location.fromJson(
        jsonDecode(item),
      );
      return loc.latitude == location.latitude &&
          loc.longitude == location.longitude;
    });

    await prefs.setStringList('savedLocations', savedLocations);
  }

  /// Retrieves all user-saved locations.
  ///
  /// Loads and deserialises locations from SharedPreferences.
  Future<List<app_location.Location>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedLocations = prefs.getStringList('savedLocations') ?? [];

    return savedLocations.map((item) {
      return app_location.Location.fromJson(jsonDecode(item));
    }).toList();
  }

  /// Searches for locations matching the provided query string.
  ///
  /// Uses the Open-Meteo Geocoding API to find locations by name.
  Future<List<app_location.Location>> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      '$geocodingBaseUrl/search?name=$encodedQuery&count=10&language=en',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          return (data['results'] as List).map((item) {
            // Extract the location components
            final String name = item['name'] ?? '';
            final String region = item['admin1'] ?? '';
            final String country = item['country'] ?? '';

            /// Build the location string with all available components
            List<String> parts = [];
            if (name.isNotEmpty) {
              parts.add(name);
            }

            if (region.isNotEmpty) {
              parts.add(region);
            }

            if (country.isNotEmpty) {
              parts.add(country);
            }

            return app_location.Location(
              name: _formatLocationName(parts),
              latitude: item['latitude'],
              longitude: item['longitude'],
            );
          }).toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Geocoding API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error searching location: $e');
      }
      throw Exception('Failed to perform geocoding search: $e');
    }
  }
}
