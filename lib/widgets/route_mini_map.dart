import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/models/travel_route.dart';

class RouteMiniMap extends StatefulWidget {
  final TravelRoute route;

  const RouteMiniMap({super.key, required this.route});

  @override
  State<RouteMiniMap> createState() => _RouteMiniMapState();
}

class _RouteMiniMapState extends State<RouteMiniMap> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  late CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    _setupMap();
  }

  void _setupMap() {
    final locations = widget.route.locations
        ?.map(
          (locMap) =>
              TravelLocation.fromFirestore(locMap['firestoreId'] ?? '', locMap),
        )
        .toList();

    if (locations == null || locations.isEmpty) {
      _initialCameraPosition = const CameraPosition(
        target: LatLng(39.9334, 32.8597), // Ankara
        zoom: 5,
      );
      return;
    }

    for (final loc in locations) {
      _markers.add(
        Marker(
          markerId: MarkerId(loc.firestoreId!),
          position: LatLng(loc.latitude, loc.longitude),
        ),
      );
    }

    _initialCameraPosition = CameraPosition(
      target: LatLng(locations.first.latitude, locations.first.longitude),
      zoom: 14,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _zoomToFitBounds();
  }

  void _zoomToFitBounds() {
    final locations = widget.route.locations;
    if (_mapController == null || locations == null || locations.length < 2)
      return;

    final latLngList = locations
        .map((l) => LatLng(l['latitude'], l['longitude']))
        .toList();
    final bounds = _boundsFromLatLngList(latLngList);

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        height: 150,
        color: Colors.grey[300],
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: _initialCameraPosition,
          markers: _markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
        ),
      ),
    );
  }
}
