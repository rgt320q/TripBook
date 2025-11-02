import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'package:tripbook/services/connectivity_service.dart';

import 'package:tripbook/models/travel_location.dart';

class DirectionsInfo {
  final LatLngBounds bounds;
  final List<List<PointLatLng>> legsPoints; // Changed to a list of lists
  final String totalDistance;
  final String totalDuration;

  const DirectionsInfo({
    required this.bounds,
    required this.legsPoints, // Changed
    required this.totalDistance,
    required this.totalDuration,
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
    if (_apiKey.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'FATAL ERROR: GOOGLE_MAPS_API_KEY is not set in the .env file.',
        null,
        fatal: true,
      );
    }
    _sessionToken = _uuid.v4();
  }

  Future<DirectionsInfo?> getDirections(List<TravelLocation> locations) async {
    // Check internet connectivity first
    if (!await ConnectivityService().checkConnection()) {
      return null;
    }
    
    // For web, ensure the Google Maps API key in the Google Cloud Console
    // has HTTP referrers set to allow requests from your domain to prevent CORS errors.

    if (locations.length < 2) return null;

    final origin = locations.first;
    final destination = locations.last;
    final waypoints = locations.length > 2
        ? locations
              .sublist(1, locations.length - 1)
              .map((loc) => '${loc.latitude},${loc.longitude}')
              .join('|')
        : '';

    var url = '';
    if (kIsWeb) {
      // Use the Firebase Function as a proxy on the web to avoid CORS issues.
      // IMPORTANT: Replace YOUR_PROJECT_ID with your actual Firebase project ID.
      const functionUrl = 'https://us-central1-tripbook-68238.cloudfunctions.net/getDirections';
      url = '$functionUrl?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}'
          '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}';
    } else {
      // Use the direct API on mobile.
      url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}'
          '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}&'
          'key=$_apiKey';
    }
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = convert.jsonDecode(response.body);

      if ((json["routes"] as List).isEmpty) return null;

      final route = json["routes"][0];

      // --- Process Legs and Steps for Segmented Polylines ---
      final List<List<PointLatLng>> legsPoints = [];
      int totalDistanceMeters = 0;
      int totalDurationSeconds = 0;

      for (final leg in route["legs"]) {
        totalDistanceMeters += leg["distance"]['value'] as int;
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
      // --- End of Leg Processing ---

      final duration = Duration(seconds: totalDurationSeconds);
      String totalDurationText = '';
      if (duration.inHours > 0) {
        totalDurationText += '${duration.inHours} saat ';
      }
      final remainingMinutes = duration.inMinutes % 60;
      if (remainingMinutes > 0) {
        totalDurationText += '$remainingMinutes dakika';
      }
      if (totalDurationText.isEmpty) totalDurationText = '0 dakika';

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
        legsPoints: legsPoints, // Pass the list of leg paths
        totalDistance: '${totalDistanceKm.toStringAsFixed(1)} km',
        totalDuration: totalDurationText.trim(),
      );
    } else {
      FirebaseCrashlytics.instance.recordError(
        'Failed to get directions',
        null,
        reason: 'API call failed with status code ${response.statusCode}',
      );
      return null;
    }
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
        FirebaseCrashlytics.instance.recordError(
          'Failed to get place name for position: $position',
          null,
          reason: 'API call failed with status code ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        'Error getting place name for position: $position - $e',
        null,
      );
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
      FirebaseCrashlytics.instance.recordError(
        'Error getting autocomplete for input: $input - $e',
        null,
      );
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
      FirebaseCrashlytics.instance.recordError(
        'Error getting place details for place_id: $placeId - $e',
        null,
      );
    }
    return null;
  }
}
