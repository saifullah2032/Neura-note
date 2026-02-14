import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Exception thrown when location operations fail
class LocationException implements Exception {
  final String message;
  final String? code;

  const LocationException(this.message, [this.code]);

  @override
  String toString() => 'LocationException: $message (code: $code)';
}

/// Location permission status
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unknown,
}

/// Service responsible for handling location operations
class LocationService {
  final GeolocatorPlatform _geolocator;
  
  StreamSubscription<Position>? _positionSubscription;
  final StreamController<Position> _positionController = 
      StreamController<Position>.broadcast();

  LocationService({
    GeolocatorPlatform? geolocator,
  }) : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  /// Stream of position updates
  Stream<Position> get positionStream => _positionController.stream;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await _geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermissionStatus> checkPermission() async {
    try {
      // Check if service is enabled
      final serviceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      // Check permission
      final permission = await _geolocator.checkPermission();
      return _mapPermission(permission);
    } catch (e) {
      return LocationPermissionStatus.unknown;
    }
  }

  /// Request location permission
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      // Check if service is enabled first
      final serviceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      // Check current permission
      LocationPermission permission = await _geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await _geolocator.requestPermission();
      }

      return _mapPermission(permission);
    } catch (e) {
      throw LocationException('Failed to request permission: $e');
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await _geolocator.openLocationSettings();
  }

  /// Open app settings (for permission settings)
  Future<bool> openAppSettings() async {
    return await _geolocator.openAppSettings();
  }

  /// Get current position
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Verify permission
      final permissionStatus = await checkPermission();
      if (permissionStatus != LocationPermissionStatus.granted) {
        throw LocationException(
          'Location permission not granted',
          'permission_denied',
        );
      }

      return await _geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );
    } catch (e) {
      if (e is LocationException) rethrow;
      throw LocationException('Failed to get current position: $e');
    }
  }

  /// Get last known position (faster, may be stale)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await _geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Start listening to position updates
  Future<void> startPositionUpdates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
  }) async {
    // Stop any existing subscription
    await stopPositionUpdates();

    try {
      final permissionStatus = await checkPermission();
      if (permissionStatus != LocationPermissionStatus.granted) {
        throw LocationException(
          'Location permission not granted',
          'permission_denied',
        );
      }

      final settings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );

      _positionSubscription = _geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (position) => _positionController.add(position),
        onError: (error) => _positionController.addError(error),
      );
    } catch (e) {
      throw LocationException('Failed to start position updates: $e');
    }
  }

  /// Stop listening to position updates
  Future<void> stopPositionUpdates() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Calculate distance between two coordinates (in meters)
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return _geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two coordinates (in degrees)
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return _geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Get address from coordinates (reverse geocoding)
  Future<List<Placemark>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      return await placemarkFromCoordinates(latitude, longitude);
    } catch (e) {
      throw LocationException('Failed to get address: $e');
    }
  }

  /// Get coordinates from address (forward geocoding)
  Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      throw LocationException('Failed to geocode address: $e');
    }
  }

  /// Format a placemark to readable address string
  String formatAddress(Placemark placemark) {
    final parts = <String>[];
    
    if (placemark.street?.isNotEmpty == true) {
      parts.add(placemark.street!);
    }
    if (placemark.subLocality?.isNotEmpty == true) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.postalCode?.isNotEmpty == true) {
      parts.add(placemark.postalCode!);
    }
    if (placemark.country?.isNotEmpty == true) {
      parts.add(placemark.country!);
    }
    
    return parts.join(', ');
  }

  /// Check if coordinates are within a radius of a target
  bool isWithinRadius({
    required double currentLatitude,
    required double currentLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double radiusInMeters,
  }) {
    final distance = calculateDistance(
      currentLatitude,
      currentLongitude,
      targetLatitude,
      targetLongitude,
    );
    return distance <= radiusInMeters;
  }

  /// Map Geolocator permission to our enum
  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unknown;
    }
  }

  /// Dispose resources
  void dispose() {
    _positionSubscription?.cancel();
    _positionController.close();
  }
}

/// Extension for Position to add utility methods
extension PositionExtension on Position {
  /// Convert position to simple map
  Map<String, double> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'speed': speed,
    };
  }
}
