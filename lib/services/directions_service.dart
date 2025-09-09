import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

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

  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_API_KEY_HERE';
  String? _sessionToken;
  final Uuid _uuid = const Uuid();

  DirectionsService._internal() {
    _sessionToken = _uuid.v4();
  }

  Future<DirectionsInfo?> getDirections(List<TravelLocation> locations) async {
    if (locations.length < 2) return null;

    final origin = locations.first;
    final destination = locations.last;
    final waypoints = locations.length > 2 
      ? locations.sublist(1, locations.length - 1)
          .map((loc) => '${loc.latitude},${loc.longitude}')
          .join('|')
      : '';

    final url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}'
        '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}&'
        'key=$_apiKey';

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
          final points = PolylinePoints.decodePolyline(step["polyline"]["points"]);
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
        southwest: LatLng(route["bounds"]["southwest"]['lat'], route["bounds"]["southwest"]['lng']),
        northeast: LatLng(route["bounds"]["northeast"]['lat'], route["bounds"]["northeast"]['lng']),
      );

      return DirectionsInfo(
        bounds: bounds,
        legsPoints: legsPoints, // Pass the list of leg paths
        totalDistance: '${totalDistanceKm.toStringAsFixed(1)} km',
        totalDuration: totalDurationText.trim(),
      );
    } else {
      
      return null;
    }
  }

  Future<String?> getPlaceName(LatLng position) async {
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?'
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
      // TODO: Add proper logging for failed API calls
      return null;
    }
  }

  Future<List<dynamic>> getAutocomplete(String input) async {
    if (input.isEmpty) {
      return [];
    }

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey&sessiontoken=$_sessionToken&language=tr&components=country:tr';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = convert.jsonDecode(response.body);
      if (json['predictions'] != null) {
        return json['predictions'];
      }
    }
    return [];
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
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
    return null;
  }
}
