import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/utils/marker_utils.dart' as marker_utils;

class HomeLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const HomeLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<HomeLocationPickerScreen> createState() =>
      _HomeLocationPickerScreenState();
}

class _HomeLocationPickerScreenState extends State<HomeLocationPickerScreen> {
  LatLng? _pickedLocation;
  Marker? _pickedLocationMarker;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialLocation != null && _pickedLocation == null) {
      _pickedLocation = widget.initialLocation;
      _updateMarker(
          widget.initialLocation!, AppLocalizations.of(context)!.homeLocation);
    }
  }

  void _updateMarker(LatLng position, String markerTitle) async {
    final icon = await marker_utils.getHomeMarkerIcon();
    setState(() {
      _pickedLocation = position;
      _pickedLocationMarker = Marker(
        markerId: const MarkerId('pickedLocation'),
        position: position,
        icon: icon,
        infoWindow: InfoWindow(title: markerTitle),
      );
    });
  }

  void _searchLocation() async {
    if (_searchController.text.isEmpty) return;

    try {
      List<Location> locations =
          await locationFromAddress(_searchController.text);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15.0),
        );
        _updateMarker(latLng, _searchController.text);
      }
    } catch (e) {
      // Handle exceptions
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectHomeLocation),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _pickedLocation == null
                ? null
                : () {
                    Navigator.of(context).pop(_pickedLocation);
                  },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target:
                  widget.initialLocation ?? const LatLng(38.9637, 35.2433), // Turkey
              zoom: widget.initialLocation != null ? 15.0 : 5.0,
            ),
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
                _isMapReady = true;
              });
            },
            onTap: (latLng) => _updateMarker(latLng, l10n.homeLocation),
            markers:
                _pickedLocationMarker != null ? {_pickedLocationMarker!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _isMapReady ? _searchLocation : null,
                  ),
                ),
                onSubmitted: _isMapReady ? (_) => _searchLocation() : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}