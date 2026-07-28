import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'package:tripbook/services/connectivity_service.dart';

import 'package:tripbook/models/travel_location.dart';

enum AppTravelMode {
  driving,
  walking,
}

class DirectionsInfo {
  final LatLngBounds bounds;
  final List<List<PointLatLng>> legsPoints;
  final String totalDistance;
  final String totalDuration;
  final Duration duration;
  final bool containsStraightLines;
  final List<bool> legsIsStraight;
  final double distanceValue; // Distance in meters

  const DirectionsInfo({
    required this.bounds,
    required this.legsPoints,
    required this.totalDistance,
    required this.totalDuration,
    required this.duration,
    required this.distanceValue,
    this.containsStraightLines = false,
    this.legsIsStraight = const [],
  });
}

class DirectionsService {
  static final DirectionsService _instance = DirectionsService._internal();

  factory DirectionsService() {
    return _instance;
  }

  late final String _apiKey;
  String? _sessionToken;
  final Uuid _uuid = const Uuid();

  DirectionsService._internal() {
    _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (kDebugMode) {
      final keyDisplay = _apiKey.length > 10 
          ? '${_apiKey.substring(0, 5)}...${_apiKey.substring(_apiKey.length - 6)}' 
          : 'TOO SHORT';
      print('DirectionsService: API Key loaded: $keyDisplay');
    }
    if (_apiKey.isEmpty) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          'FATAL ERROR: GOOGLE_MAPS_API_KEY is not set in the .env file.',
          null,
          fatal: true,
        );
      }
    }
    _sessionToken = _uuid.v4();
  }

  Future<DirectionsInfo?> getHybridDirections(
    List<TravelLocation> locations, {
    AppTravelMode mode = AppTravelMode.driving,
  }) async {
    if (locations.length < 2) return null;

    // 1. Try full route first (most efficient)
    final fullRoute = await getDirections(locations, mode: mode);
    if (fullRoute != null) return fullRoute;

    // 2. If full route fails, calculate segment by segment
    if (kDebugMode) {
      print('DirectionsService: Full route failed, calculating segment by segment...');
    }

    List<List<PointLatLng>> combinedLegsPoints = [];
    double totalDistanceMeters = 0;
    int totalDurationSeconds = 0;
    bool containsStraightLines = false;
    List<bool> legsIsStraight = [];
    
    // Initialize bounds with the first valid location
    final firstLoc = locations.first;
    double minLat = firstLoc.latitude;
    double minLng = firstLoc.longitude;
    double maxLat = firstLoc.latitude;
    double maxLng = firstLoc.longitude;

    void updateBounds(double lat, double lng) {
      if (lat == 0.0 && lng == 0.0) return; // Skip invalid points
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    // Ensure initial point is in bounds
    updateBounds(minLat, minLng);

    for (int i = 0; i < locations.length - 1; i++) {
      final start = locations[i];
      final end = locations[i + 1];
      
      final segmentInfo = await getDirections([start, end], mode: mode);
      
      if (segmentInfo != null) {
        combinedLegsPoints.addAll(segmentInfo.legsPoints);
        totalDistanceMeters += segmentInfo.distanceValue;
        totalDurationSeconds += segmentInfo.duration.inSeconds;
        legsIsStraight.add(false);

        // If a segment itself was already straight (e.g. from recursive call)
        if (segmentInfo.containsStraightLines) {
          containsStraightLines = true;
          // Note: In segment-by-segment mode, getDirections usually returns 
          // either full road or full straight if it failed.
        }

        // Include all path points in bounds
        for (var leg in segmentInfo.legsPoints) {
          for (var point in leg) {
            updateBounds(point.latitude, point.longitude);
          }
        }
      } else {
        if (kDebugMode) {
          print('DirectionsService: Segment $i failed, using straight line fallback');
        }
        containsStraightLines = true;
        legsIsStraight.add(true);
        combinedLegsPoints.add([
          PointLatLng(start.latitude, start.longitude),
          PointLatLng(end.latitude, end.longitude),
        ]);
        
        totalDistanceMeters += Geolocator.distanceBetween(
          start.latitude, start.longitude, end.latitude, end.longitude
        );
        // Update bounds with segment points
        updateBounds(start.latitude, start.longitude);
        updateBounds(end.latitude, end.longitude);
      }
    }

    final duration = Duration(seconds: totalDurationSeconds);
    String totalDurationText = '';
    if (duration.inHours > 0) {
      totalDurationText += '${duration.inHours} h ';
    }
    final remainingMinutes = duration.inMinutes % 60;
    if (remainingMinutes > 0 || totalDurationText.isEmpty) {
      totalDurationText += '$remainingMinutes m';
    }

    return DirectionsInfo(
      bounds: LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      legsPoints: combinedLegsPoints,
      totalDistance: '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km',
      totalDuration: totalDurationText.trim(),
      duration: duration,
      distanceValue: totalDistanceMeters,
      containsStraightLines: containsStraightLines,
      legsIsStraight: legsIsStraight,
    );
  }

  Future<DirectionsInfo?> getDirections(
    List<TravelLocation> locations, {
    AppTravelMode mode = AppTravelMode.driving,
  }) async {
    if (kDebugMode) {
      print('DirectionsService: Requesting directions for ${locations.length} points (Mode: $mode):');
      for (int i = 0; i < locations.length; i++) {
        print('  Point $i: ${locations[i].name} (${locations[i].latitude}, ${locations[i].longitude})');
      }
    }
    // Check internet connectivity first
    if (!await ConnectivityService().checkConnection()) {
      return null;
    }

    if (locations.length < 2) return null;

    if (kIsWeb) {
      // Use the Firebase Function as a proxy on the web to avoid CORS issues.
      final origin = locations.first;
      final destination = locations.last;
      final waypoints = locations.length > 2
          ? locations
              .sublist(1, locations.length - 1)
              .map((loc) => '${loc.latitude},${loc.longitude}')
              .join('|')
          : '';

      final modeStr = mode.name; // driving, walking, transit

      const functionUrl =
          'https://us-central1-tripbook-68238.cloudfunctions.net/getDirections';
      final url = '$functionUrl?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'mode=$modeStr'
          '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}';

      // SECURITY: Get Firebase ID Token to authorize the Cloud Function call
      String? idToken;
      try {
        idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (e) {
        if (kDebugMode) print('Error getting ID token: $e');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
      );
      if (response.statusCode == 200) {
        return _parseLegacyResponse(convert.jsonDecode(response.body));
      }
      return null;
    } else {
      // Try modern Google Routes API v2 first
      final directionsInfo = await _getDirectionsV2(locations, mode: mode);
      if (directionsInfo != null) return directionsInfo;

      // Fallback to legacy Directions API
      if (kDebugMode) {
        print('DirectionsService: Falling back to legacy Directions API');
      }
      return await _getDirectionsLegacy(locations, mode: mode);
    }
  }

  Future<DirectionsInfo?> _getDirectionsV2(
    List<TravelLocation> locations, {
    required AppTravelMode mode,
  }) async {
    const url = 'https://routes.googleapis.com/directions/v2:computeRoutes';

    final origin = locations.first;
    final destination = locations.last;
    final intermediates = locations.length > 2
        ? locations.sublist(1, locations.length - 1).map((loc) => {
              "location": {
                "latLng": {"latitude": loc.latitude, "longitude": loc.longitude}
              }
            }).toList()
        : [];

    final String v2Mode;
    switch (mode) {
      case AppTravelMode.driving:
        v2Mode = "DRIVE";
        break;
      case AppTravelMode.walking:
        v2Mode = "WALK";
        break;
    }

    final body = {
      "origin": {
        "location": {
          "latLng": {"latitude": origin.latitude, "longitude": origin.longitude}
        }
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": destination.latitude,
            "longitude": destination.longitude
          }
        }
      },
      if (intermediates.isNotEmpty) "intermediates": intermediates,
      "travelMode": v2Mode,
      "routingPreference": "TRAFFIC_UNAWARE",
      "polylineQuality": "OVERVIEW",
      "computeAlternativeRoutes": false,
      "languageCode": "tr-TR",
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'routes.duration,routes.distanceMeters,routes.polyline,routes.viewport,routes.legs.polyline',
        },
        body: convert.jsonEncode(body),
      );

      if (kDebugMode) {
        print('Routes API v2 Response Status: ${response.statusCode}');
        print('Routes API v2 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final json = convert.jsonDecode(response.body);
        if ((json["routes"] as List?)?.isEmpty ?? true) return null;

        final route = json["routes"][0];

        // Process Distance and Duration
        final double totalDistanceMeters = (route['distanceMeters'] as num?)?.toDouble() ?? 0.0;
        final String durationStr = route['duration'] ?? '0s';
        final int totalDurationSeconds =
            int.parse(durationStr.replaceAll('s', ''));

        final duration = Duration(seconds: totalDurationSeconds);
        String totalDurationText = '';
        if (duration.inHours > 0) {
          totalDurationText += '${duration.inHours} h ';
        }
        final remainingMinutes = duration.inMinutes % 60;
        if (remainingMinutes > 0) {
          totalDurationText += '$remainingMinutes m';
        }
        if (totalDurationText.isEmpty) totalDurationText = '0 m';

        final double totalDistanceKm = totalDistanceMeters / 1000.0;

        // Process Bounds (Viewport)
        final viewport = route['viewport'];
        if (viewport == null) return null;
        
        final bounds = LatLngBounds(
          southwest: LatLng(
            viewport['low']['latitude'],
            viewport['low']['longitude'],
          ),
          northeast: LatLng(
            viewport['high']['latitude'],
            viewport['high']['longitude'],
          ),
        );

        // Process Legs Points
        final List<List<PointLatLng>> legsPoints = [];
        final List legs = route['legs'] ?? [];
        for (final leg in legs) {
          final String? encodedPolyline = leg['polyline']?['encodedPolyline'];
          if (encodedPolyline != null) {
            legsPoints.add(PolylinePoints.decodePolyline(encodedPolyline));
          }
        }

        return DirectionsInfo(
          bounds: bounds,
          legsPoints: legsPoints,
          totalDistance: '${totalDistanceKm.toStringAsFixed(1)} km',
          totalDuration: totalDurationText.trim(),
          duration: duration,
          distanceValue: totalDistanceMeters,
          containsStraightLines: false,
          legsIsStraight: List.filled(legs.length, false),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error in _getDirectionsV2: $e');
    }
    return null;
  }

  Future<DirectionsInfo?> _getDirectionsLegacy(
    List<TravelLocation> locations, {
    required AppTravelMode mode,
  }) async {
    final origin = locations.first;
    final destination = locations.last;
    final waypoints = locations.length > 2
        ? locations
            .sublist(1, locations.length - 1)
            .map((loc) => '${loc.latitude},${loc.longitude}')
            .join('|')
        : '';

    final url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        '${waypoints.isNotEmpty ? 'waypoints=$waypoints&' : ''}'
        'mode=${mode.name}&'
        'language=tr&'
        'key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (kDebugMode) {
        print('Legacy Directions API Response Status: ${response.statusCode}');
        print('Legacy Directions API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return _parseLegacyResponse(convert.jsonDecode(response.body));
      }
    } catch (e) {
      if (kDebugMode) print('Error in _getDirectionsLegacy: $e');
    }
    return null;
  }



  DirectionsInfo? _parseLegacyResponse(dynamic json) {
    if ((json["routes"] as List).isEmpty) return null;

    final route = json["routes"][0];

    final List<List<PointLatLng>> legsPoints = [];
    double totalDistanceMeters = 0;
    int totalDurationSeconds = 0;

    for (final leg in route["legs"]) {
      totalDistanceMeters += (leg["distance"]['value'] as num).toDouble();
      totalDurationSeconds += leg["duration"]['value'] as int;

      List<PointLatLng> legPath = [];
      for (final step in leg["steps"]) {
        final points = PolylinePoints.decodePolyline(
          step["polyline"]["points"],
        );
        legPath.addAll(points);
      }
      legsPoints.add(legPath);
    }

    final duration = Duration(seconds: totalDurationSeconds);
    String totalDurationText = '';
    if (duration.inHours > 0) {
      totalDurationText += '${duration.inHours} h ';
    }
    final remainingMinutes = duration.inMinutes % 60;
    if (remainingMinutes > 0) {
      totalDurationText += '$remainingMinutes m';
    }
    if (totalDurationText.isEmpty) totalDurationText = '0 m';

    final double totalDistanceKm = totalDistanceMeters / 1000.0;

    final bounds = LatLngBounds(
      southwest: LatLng(
        route["bounds"]["southwest"]['lat'],
        route["bounds"]["southwest"]['lng'],
      ),
      northeast: LatLng(
        route["bounds"]["northeast"]['lat'],
        route["bounds"]["northeast"]['lng'],
      ),
    );

    return DirectionsInfo(
      bounds: bounds,
      legsPoints: legsPoints,
      totalDistance: '${totalDistanceKm.toStringAsFixed(1)} km',
      totalDuration: totalDurationText.trim(),
      duration: duration,
      distanceValue: totalDistanceMeters,
      containsStraightLines: false,
      legsIsStraight: List.filled(route["legs"].length, false),
    );
  }

  Future<String?> getPlaceName(LatLng position) async {
    // Check internet connectivity first
    if (!await ConnectivityService().checkConnection()) {
      return "Bağlantı hatası - Bilinmeyen Konum";
    }
    
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?'
          'latlng=${position.latitude},${position.longitude}&'
          'key=$_apiKey&'
          'language=tr';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = convert.jsonDecode(response.body);

        if ((json["results"] as List).isNotEmpty) {
          return json["results"][0]["formatted_address"];
        } else {
          return "Bilinmeyen Konum";
        }
      } else {
        if (!kIsWeb) {
          FirebaseCrashlytics.instance.recordError(
            'Failed to get place name for position: $position',
            null,
            reason: 'API call failed with status code ${response.statusCode}',
          );
        }
        return null;
      }
    } catch (e) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          'Error getting place name for position: $position - $e',
          null,
        );
      }
      return null;
    }
  }

  Future<List<dynamic>> getAutocomplete(String input) async {
    if (input.isEmpty) {
      return [];
    }

    // Check internet connectivity first
    if (!await ConnectivityService().checkConnection()) {
      return [];
    }

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey&sessiontoken=$_sessionToken&language=tr&components=country:tr';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = convert.jsonDecode(response.body);
        if (json['predictions'] != null) {
          return json['predictions'];
        }
      }
    } catch (e) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          'Error getting autocomplete for input: $input - $e',
          null,
        );
      }
    }
    return [];
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    // Check internet connectivity first
    if (!await ConnectivityService().checkConnection()) {
      return null;
    }
    
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey&sessiontoken=$_sessionToken&language=tr&fields=geometry';

      final response = await http.get(Uri.parse(url));

      // Reset session token after use
      _sessionToken = _uuid.v4();

      if (response.statusCode == 200) {
        final json = convert.jsonDecode(response.body);
        if (json['result'] != null) {
          return json['result'];
        }
      }
    } catch (e) {
      // Reset session token even on error
      _sessionToken = _uuid.v4();
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          'Error getting place details for place_id: $placeId - $e',
          null,
        );
      }
    }
    return null;
  }
}
