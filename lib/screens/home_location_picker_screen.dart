import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/services/connectivity_service.dart';
import 'package:tripbook/services/directions_service.dart';
import 'package:tripbook/utils/marker_utils.dart' as marker_utils;
import 'package:tripbook/widgets/long_press_indicator.dart';

class HomeLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const HomeLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<HomeLocationPickerScreen> createState() =>
      _HomeLocationPickerScreenState();
}

class _HomeLocationPickerScreenState extends State<HomeLocationPickerScreen>
    with SingleTickerProviderStateMixin {
  LatLng? _pickedLocation;
  Marker? _pickedLocationMarker;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final DirectionsService _directionsService = DirectionsService();
  Timer? _debounce;
  List<dynamic> _placePredictions = [];
  late AnimationController _longPressController;
  Offset? _longPressPosition;
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _searchController.addListener(_onSearchChanged);
    _longPressController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _onLongPressCompleted();
          }
        });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _longPressController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
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
        widget.initialLocation!,
        AppLocalizations.of(context)!.homeLocation,
      );
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

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (_searchController.text.isNotEmpty) {
        final predictions = await _directionsService.getAutocomplete(
          _searchController.text,
        );
        if (mounted) {
          setState(() {
            _placePredictions = predictions;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _placePredictions = [];
          });
        }
      }
    });
  }

  Future<void> _selectPrediction(dynamic prediction) async {
    final placeId = prediction['place_id'];
    if (placeId == null) return;

    final l10n = AppLocalizations.of(context)!;

    if (!await ConnectivityService().checkConnection() && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noInternetForOperation),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final details = await _directionsService.getPlaceDetails(placeId);
    if (details == null || !mounted) return;

    final location = details['geometry']?['location'];
    if (location == null) return;

    final latLng = LatLng(location['lat'], location['lng']);

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15.0));

    final description = prediction['description'] ?? l10n.unknownLocation;
    _updateMarker(latLng, description);

    setState(() {
      _placePredictions = [];
    });
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _placePredictions = [];
    });
  }

  Future<void> _onLongPressCompleted() async {
    if (_longPressPosition == null || _mapController == null) return;
    final Offset pos = _longPressPosition!;
    // On device platform views (Android/iOS) the map coordinates are in
    // physical pixels; convert the Flutter logical position accordingly.
    final double scale = kIsWeb ? 1.0 : MediaQuery.of(context).devicePixelRatio;
    final LatLng latLng = await _mapController!.getLatLng(
      ScreenCoordinate(
        x: (pos.dx * scale).round(),
        y: (pos.dy * scale).round(),
      ),
    );
    if (!mounted) return;
    _updateMarker(latLng, AppLocalizations.of(context)!.homeLocation);
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _longPressPosition = event.localPosition;
      _isLongPressing = true;
    });
    _longPressController.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isLongPressing) {
      setState(() {
        _isLongPressing = false;
        _longPressPosition = null;
      });
      _longPressController.reset();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isLongPressing && _longPressPosition != null) {
      final distance = (event.localPosition - _longPressPosition!).distance;
      if (distance > 20) {
        setState(() {
          _isLongPressing = false;
          _longPressPosition = null;
        });
        _longPressController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
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
          Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerMove: _onPointerMove,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target:
                    widget.initialLocation ??
                    const LatLng(38.9637, 35.2433), // Turkey
                zoom: widget.initialLocation != null ? 15.0 : 5.0,
              ),
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                });
              },
              onTap: (latLng) => _updateMarker(latLng, l10n.homeLocation),
              markers: _pickedLocationMarker != null
                  ? {_pickedLocationMarker!}
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          if (_isLongPressing && _longPressPosition != null)
            Positioned(
              left: _longPressPosition!.dx - 40,
              top: _longPressPosition!.dy - 40,
              child: AnimatedBuilder(
                animation: _longPressController,
                builder: (context, child) {
                  return LongPressIndicator(
                    progress: _longPressController.value,
                  );
                },
              ),
            ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: colorScheme.surface,
                  elevation: 2.0,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                    bottom: Radius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.search,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: l10n.searchHint,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: _clearSearch,
                      ),
                    ],
                  ),
                ),
                if (_placePredictions.isNotEmpty)
                  Material(
                    color: colorScheme.surface,
                    elevation: 4.0,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _placePredictions.length,
                        itemBuilder: (context, index) {
                          final prediction = _placePredictions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(
                              prediction['description'] ??
                                  l10n.unknownLocation,
                            ),
                            onTap: () => _selectPrediction(prediction),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
