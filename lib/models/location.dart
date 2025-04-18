// Model for handing Location

class Location {
  final String name;
  final double latitude;
  final double longitude;
  final bool isCurrent;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isCurrent = false,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isCurrent: json['isCurrent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'isCurrent': isCurrent,
    };
  }

  @override
  String toString() {
    return ('Location(name: $name, latitude: $latitude, longitude: $longitude, isCurrent: $isCurrent)');
  }
}
