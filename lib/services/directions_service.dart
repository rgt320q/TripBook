import 'dart:convert' as convert;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/services/connectivity_service.dart';
import 'package:uuid/uuid.dart';

enum AppTravelMode { driving, walking }

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

  String? _sessionToken;
  final Uuid _uuid = const Uuid();

  DirectionsService._internal() {
    _sessionToken = _uuid.v4();
  }

  /// All Google Maps data calls go through the Firebase Functions proxy so
  /// the Google Maps API key never leaves the server.
  static const String _functionsBase =
      'https://us-central1-tripbook-68238.cloudfunctions.net';

  Future<String?> _idToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      if (kDebugMode) print('Error getting ID token: $e');
      return null;
    }
  }

  Future<http.Response> _proxyGet(
    String functionName,
    String query,
  ) async {
    final idToken = await _idToken();
    final url = '$_functionsBase/$functionName?$query';
    return http.get(
      Uri.parse(url),
      headers: {if (idToken != null) 'Authorization': 'Bearer $idToken'},
    );
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
      print(
        'DirectionsService: Full route failed, calculating segment by segment...',
      );
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
          print(
            'DirectionsService: Segment $i failed, using straight line fallback',
          );
        }
        containsStraightLines = true;
        legsIsStraight.add(true);
        combinedLegsPoints.add([
          PointLatLng(start.latitude, start.longitude),
          PointLatLng(end.latitude, end.longitude),
        ]);

        totalDistanceMeters += Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
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
      print(
        'DirectionsService: Requesting directions for ${locations.length} points (Mode: $mode):',
      );
      for (int i = 0; i < locations.length; i++) {
        print(
          '  Point $i: ${locations[i].name} (${locations[i].latitude}, ${locations[i].longitude})',
        );
      }
    }
    // Check internet connectivity first
    if (!await ConnectivityService().checkConnection()) {
      return null;
    }

    if (locations.length < 2) return null;

    // All platforms go through the Firebase Functions proxy so the Google
    // Maps API key stays server-side.
    final origin = locations.first;
    final destination = locations.last;
    final waypoints = locations.length > 2
        ? locations
              .sublist(1, locations.length - 1)
              .map((loc) => '${loc.latitude},${loc.longitude}')
              .join('|')
        : '';

    final modeStr = mode.name; // driving, walking

    final query =
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'mode=$modeStr'
        '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}';

    final response = await _proxyGet('getDirections', query);
    if (response.statusCode == 200) {
      return _parseLegacyResponse(convert.jsonDecode(response.body));
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
    if (!await ConnectivityService().checkConnection()) {
      return "Bağlantı hatası - Bilinmeyen Konum";
    }

    try {
      final response = await _proxyGet(
        'getGeocode',
        'latlng=${position.latitude},${position.longitude}&language=tr',
      );
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
            'DirectionsService: getPlaceName failed with status ${response.statusCode}',
          );
          print('Response: ${response.body}');
        }
        return null;
      }

      final responseData = convert.jsonDecode(response.body);
      if ((responseData["results"] as List).isNotEmpty) {
        return responseData["results"][0]["formatted_address"];
      } else {
        return "Bilinmeyen Konum";
      }
    } catch (e) {
      if (kDebugMode) print('Error getting place name: $e');
      return null;
    }
  }

  Future<List<dynamic>> getAutocomplete(String input) async {
    if (input.isEmpty || !await ConnectivityService().checkConnection()) {
      return [];
    }

    try {
      final response = await _proxyGet(
        'getAutocomplete',
        'input=${Uri.encodeComponent(input)}&'
        'sessiontoken=$_sessionToken&'
        'language=tr&'
        'components=country:tr',
      );
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
            'DirectionsService: getAutocomplete failed with status ${response.statusCode}',
          );
          print('Response: ${response.body}');
        }
        return [];
      }

      final responseData = convert.jsonDecode(response.body);
      return responseData['predictions'] ?? [];
    } catch (e) {
      if (kDebugMode) print('Error getting autocomplete: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (!await ConnectivityService().checkConnection()) return null;

    try {
      final response = await _proxyGet(
        'getPlaceDetails',
        'place_id=$placeId&'
        'sessiontoken=$_sessionToken&'
        'language=tr&'
        'fields=geometry',
      );
      _sessionToken = _uuid.v4(); // Reset token
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
            'DirectionsService: getPlaceDetails failed with status ${response.statusCode}',
          );
          print('Response: ${response.body}');
        }
        return null;
      }

      final responseData = convert.jsonDecode(response.body);
      return responseData['result'];
    } catch (e) {
      _sessionToken = _uuid.v4();
      if (kDebugMode) print('Error getting place details: $e');
      return null;
    }
  }
}
