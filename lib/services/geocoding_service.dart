import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:neuranotteai/model/summary_model.dart';

/// Exception for geocoding errors
class GeocodingException implements Exception {
  final String message;
  final String? code;

  const GeocodingException(this.message, {this.code});

  @override
  String toString() => 'GeocodingException: $message';
}

/// Configuration for geocoding service
class GeocodingConfig {
  final String apiKey;
  final String? language;
  final String? region;
  final Duration timeout;

  const GeocodingConfig({
    required this.apiKey,
    this.language = 'en',
    this.region,
    this.timeout = const Duration(seconds: 10),
  });
}

/// Result of geocoding operation
class GeocodingResult {
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? placeId;
  final List<AddressComponent> addressComponents;
  final LocationType locationType;
  final GeocodeViewport? viewport;
  final Map<String, dynamic>? rawResponse;

  const GeocodingResult({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.addressComponents = const [],
    this.locationType = LocationType.placeName,
    this.viewport,
    this.rawResponse,
  });

  /// Get city from address components
  String? get city {
    return _getComponent(['locality', 'administrative_area_level_2']);
  }

  /// Get state/province from address components
  String? get state {
    return _getComponent(['administrative_area_level_1']);
  }

  /// Get country from address components
  String? get country {
    return _getComponent(['country']);
  }

  /// Get postal code from address components
  String? get postalCode {
    return _getComponent(['postal_code']);
  }

  /// Get street address from address components
  String? get streetAddress {
    final streetNumber = _getComponent(['street_number']);
    final route = _getComponent(['route']);
    if (streetNumber != null && route != null) {
      return '$streetNumber $route';
    }
    return route;
  }

  String? _getComponent(List<String> types) {
    for (final component in addressComponents) {
      for (final type in types) {
        if (component.types.contains(type)) {
          return component.longName;
        }
      }
    }
    return null;
  }
}

/// Address component from geocoding
class AddressComponent {
  final String longName;
  final String shortName;
  final List<String> types;

  const AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['long_name'] as String? ?? '',
      shortName: json['short_name'] as String? ?? '',
      types: (json['types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Viewport bounds for geocoding result
class GeocodeViewport {
  final double northeastLat;
  final double northeastLng;
  final double southwestLat;
  final double southwestLng;

  const GeocodeViewport({
    required this.northeastLat,
    required this.northeastLng,
    required this.southwestLat,
    required this.southwestLng,
  });

  factory GeocodeViewport.fromJson(Map<String, dynamic> json) {
    final northeast = json['northeast'] as Map<String, dynamic>?;
    final southwest = json['southwest'] as Map<String, dynamic>?;
    
    return GeocodeViewport(
      northeastLat: (northeast?['lat'] as num?)?.toDouble() ?? 0,
      northeastLng: (northeast?['lng'] as num?)?.toDouble() ?? 0,
      southwestLat: (southwest?['lat'] as num?)?.toDouble() ?? 0,
      southwestLng: (southwest?['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Result of place search
class PlaceSearchResult {
  final String placeId;
  final String name;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? userRatingsTotal;
  final List<String> types;
  final bool openNow;
  final Map<String, dynamic>? rawResponse;

  const PlaceSearchResult({
    required this.placeId,
    required this.name,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.rating,
    this.userRatingsTotal,
    this.types = const [],
    this.openNow = false,
    this.rawResponse,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final openingHours = json['opening_hours'] as Map<String, dynamic>?;

    return PlaceSearchResult(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      formattedAddress: json['formatted_address'] as String? ??
          json['vicinity'] as String?,
      latitude: (location?['lat'] as num?)?.toDouble(),
      longitude: (location?['lng'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      types: (json['types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      openNow: openingHours?['open_now'] as bool? ?? false,
      rawResponse: json,
    );
  }
}

/// Service for geocoding addresses and locations
class GeocodingService {
  final HttpClient _client;
  final GeocodingConfig _config;

  static const String _baseUrl = 'maps.googleapis.com';

  GeocodingService({required GeocodingConfig config, HttpClient? client})
      : _config = config,
        _client = client ?? HttpClient() {
    _client.connectionTimeout = _config.timeout;
  }

  /// Geocode an address to coordinates
  Future<GeocodingResult?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;

    try {
      final queryParams = {
        'address': address,
        'key': _config.apiKey,
        if (_config.language != null) 'language': _config.language!,
        if (_config.region != null) 'region': _config.region!,
      };

      final uri = Uri.https(_baseUrl, '/maps/api/geocode/json', queryParams);
      final response = await _makeRequest(uri);

      final results = response['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return null;
      }

      return _parseGeocodingResult(results.first as Map<String, dynamic>);
    } catch (e) {
      if (e is GeocodingException) rethrow;
      throw GeocodingException('Geocoding failed: $e');
    }
  }

  /// Reverse geocode coordinates to address
  Future<GeocodingResult?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final queryParams = {
        'latlng': '$latitude,$longitude',
        'key': _config.apiKey,
        if (_config.language != null) 'language': _config.language!,
      };

      final uri = Uri.https(_baseUrl, '/maps/api/geocode/json', queryParams);
      final response = await _makeRequest(uri);

      final results = response['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return null;
      }

      return _parseGeocodingResult(results.first as Map<String, dynamic>);
    } catch (e) {
      if (e is GeocodingException) rethrow;
      throw GeocodingException('Reverse geocoding failed: $e');
    }
  }

  /// Search for places by text query
  Future<List<PlaceSearchResult>> searchPlaces(
    String query, {
    double? nearLatitude,
    double? nearLongitude,
    int? radiusMeters,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final queryParams = {
        'query': query,
        'key': _config.apiKey,
        if (_config.language != null) 'language': _config.language!,
        if (nearLatitude != null && nearLongitude != null)
          'location': '$nearLatitude,$nearLongitude',
        if (radiusMeters != null) 'radius': radiusMeters.toString(),
      };

      final uri = Uri.https(_baseUrl, '/maps/api/place/textsearch/json', queryParams);
      final response = await _makeRequest(uri);

      final results = response['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return [];
      }

      return results
          .map((r) => PlaceSearchResult.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is GeocodingException) rethrow;
      throw GeocodingException('Place search failed: $e');
    }
  }

  /// Search for nearby places
  Future<List<PlaceSearchResult>> searchNearby({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String? type,
    String? keyword,
  }) async {
    try {
      final queryParams = {
        'location': '$latitude,$longitude',
        'radius': radiusMeters.toString(),
        'key': _config.apiKey,
        if (_config.language != null) 'language': _config.language!,
        if (type != null) 'type': type,
        if (keyword != null) 'keyword': keyword,
      };

      final uri = Uri.https(_baseUrl, '/maps/api/place/nearbysearch/json', queryParams);
      final response = await _makeRequest(uri);

      final results = response['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return [];
      }

      return results
          .map((r) => PlaceSearchResult.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is GeocodingException) rethrow;
      throw GeocodingException('Nearby search failed: $e');
    }
  }

  /// Get place details by place ID
  Future<PlaceSearchResult?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;

    try {
      final queryParams = {
        'place_id': placeId,
        'key': _config.apiKey,
        if (_config.language != null) 'language': _config.language!,
        'fields': 'name,formatted_address,geometry,rating,user_ratings_total,types,opening_hours',
      };

      final uri = Uri.https(_baseUrl, '/maps/api/place/details/json', queryParams);
      final response = await _makeRequest(uri);

      final result = response['result'] as Map<String, dynamic>?;
      if (result == null) {
        return null;
      }

      return PlaceSearchResult.fromJson(result);
    } catch (e) {
      if (e is GeocodingException) rethrow;
      throw GeocodingException('Get place details failed: $e');
    }
  }

  /// Resolve a LocationEntity to coordinates
  Future<LocationEntity> resolveLocation(LocationEntity location) async {
    if (location.hasCoordinates) {
      // Already has coordinates, optionally reverse geocode for address
      if (location.resolvedAddress == null) {
        final result = await reverseGeocode(
          latitude: location.latitude!,
          longitude: location.longitude!,
        );
        if (result != null) {
          return LocationEntity(
            originalText: location.originalText,
            resolvedAddress: result.formattedAddress,
            latitude: location.latitude,
            longitude: location.longitude,
            type: location.type,
            confidence: location.confidence,
          );
        }
      }
      return location;
    }

    // Try to geocode the location text
    final geocodeResult = await geocodeAddress(location.originalText);
    if (geocodeResult != null) {
      return LocationEntity(
        originalText: location.originalText,
        resolvedAddress: geocodeResult.formattedAddress,
        latitude: geocodeResult.latitude,
        longitude: geocodeResult.longitude,
        type: location.type,
        confidence: location.confidence,
      );
    }

    // Try place search if geocoding fails
    final places = await searchPlaces(location.originalText);
    if (places.isNotEmpty) {
      final place = places.first;
      return LocationEntity(
        originalText: location.originalText,
        resolvedAddress: place.formattedAddress,
        latitude: place.latitude,
        longitude: place.longitude,
        type: location.type,
        confidence: location.confidence,
      );
    }

    // Return original location if resolution fails
    return location;
  }

  /// Resolve multiple locations in batch
  Future<List<LocationEntity>> resolveLocations(List<LocationEntity> locations) async {
    final results = <LocationEntity>[];
    
    for (final location in locations) {
      try {
        final resolved = await resolveLocation(location);
        results.add(resolved);
      } catch (_) {
        // Keep original location on error
        results.add(location);
      }
    }
    
    return results;
  }

  /// Parse geocoding result from API response
  GeocodingResult _parseGeocodingResult(Map<String, dynamic> result) {
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final viewport = geometry?['viewport'] as Map<String, dynamic>?;
    final locationType = geometry?['location_type'] as String?;

    return GeocodingResult(
      formattedAddress: result['formatted_address'] as String? ?? '',
      latitude: (location?['lat'] as num?)?.toDouble() ?? 0,
      longitude: (location?['lng'] as num?)?.toDouble() ?? 0,
      placeId: result['place_id'] as String?,
      addressComponents: (result['address_components'] as List<dynamic>?)
              ?.map((c) => AddressComponent.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      locationType: _parseLocationType(locationType),
      viewport: viewport != null ? GeocodeViewport.fromJson(viewport) : null,
      rawResponse: result,
    );
  }

  /// Parse location type from API response
  LocationType _parseLocationType(String? type) {
    switch (type) {
      case 'ROOFTOP':
        return LocationType.address;
      case 'RANGE_INTERPOLATED':
        return LocationType.address;
      case 'GEOMETRIC_CENTER':
        return LocationType.landmark;
      case 'APPROXIMATE':
        return LocationType.city;
      default:
        return LocationType.placeName;
    }
  }

  /// Make HTTP request to Google Maps API
  Future<Map<String, dynamic>> _makeRequest(Uri uri) async {
    try {
      final request = await _client.getUrl(uri);
      final response = await request.close().timeout(_config.timeout);
      final body = await _readResponse(response);

      if (response.statusCode != 200) {
        throw GeocodingException(
          'Request failed with status ${response.statusCode}',
          code: 'http_${response.statusCode}',
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final status = json['status'] as String?;

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        final errorMessage = json['error_message'] as String? ?? 'Unknown error';
        throw GeocodingException(errorMessage, code: status);
      }

      return json;
    } on TimeoutException {
      throw const GeocodingException('Request timed out', code: 'timeout');
    } on SocketException catch (e) {
      throw GeocodingException('Network error: ${e.message}', code: 'network_error');
    }
  }

  /// Read response body
  Future<String> _readResponse(HttpClientResponse response) async {
    final completer = Completer<String>();
    final contents = StringBuffer();

    response.transform(utf8.decoder).listen(
      (data) => contents.write(data),
      onDone: () => completer.complete(contents.toString()),
      onError: (error) => completer.completeError(error),
    );

    return completer.future;
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Calculate distance between two coordinates (Haversine formula)
double calculateDistance({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadiusKm = 6371.0;
  
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  
  return earthRadiusKm * c;
}

double _toRadians(double degrees) {
  return degrees * (3.141592653589793 / 180);
}
