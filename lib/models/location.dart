/// Model representing a geographic location for weather data retrieval.
///
/// Contains coordinates, display name, and an indicator if this represents
/// the user's current location. This model is used throughout the application
/// for location-based weather services.
class Location {
  /// Human-readable location name (e.g., "London, United Kingdom")
  final String name;

  /// Geographic latitude coordinate in decimal degrees
  final double latitude;

  /// Geographic longitude coordinate in decimal degrees
  final double longitude;

  /// Indicates if this is the user's current device location
  final bool isCurrent;

  /// Creates a Location instance with required parameters
  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isCurrent = false,
  });

  /// Creates a Location from a JSON object
  ///
  /// Used primarily when restoring saved locations from persistent storage
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isCurrent: json['isCurrent'] ?? false,
    );
  }

  /// Converts this Location to a JSON-compatible map
  ///
  /// Used primarily for persisting location data to storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'isCurrent': isCurrent,
    };
  }

  /// Provides a string representation of this Location
  ///
  /// Useful for debugging and logging purposes
  @override
  String toString() {
    return ('Location(name: $name, latitude: $latitude, longitude: $longitude, isCurrent: $isCurrent)');
  }
}