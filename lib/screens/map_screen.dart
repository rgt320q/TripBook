
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tripbook/models/location_group.dart';
import 'package:tripbook/models/reached_location_log.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/screens/reached_locations_screen.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/screens/groups_screen.dart';
import 'package:tripbook/screens/location_selection_screen.dart';
import 'package:tripbook/screens/manage_locations_screen.dart';
import 'package:tripbook/screens/saved_routes_screen.dart';
import 'package:tripbook/screens/profile_screen.dart';
import 'package:tripbook/services/database_service.dart';
import 'package:tripbook/services/directions_service.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tripbook/utils/marker_utils.dart' as marker_utils;

class NeedItem {
  final String name;
  bool isChecked;
  final String locationId;
  final int originalIndex;

  NeedItem({
    required this.name,
    required this.isChecked,
    required this.locationId,
    required this.originalIndex,
  });
}

class MapScreen extends StatefulWidget {
  final TravelLocation? initialLocation;
  const MapScreen({super.key, this.initialLocation});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isSelectingEndpoint = false;
  List<TravelLocation> _locationsForRoute = [];

  MapType _currentMapType = MapType.normal;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _placePredictions = [];
  Marker? _searchResultMarker;
  CameraPosition? _cameraPosition;
  double _currentBearing = 0.0;

  List<TravelLocation> _allLocations = [];
  List<LocationGroup> _allGroups = [];

  // --- Active Route State ---
  List<TravelLocation>? _activeRouteLocations;
  DirectionsInfo? _activeRouteInfo;
  DateTime? _routeStartTime;
  bool _isRouteCompleted = false;
  String? _activeRouteTotalStopDuration;
  String? _activeRouteTotalTripDuration;
  List<String>? _activeRouteNeeds;
  List<Map<String, String>>? _activeRouteNotes;
  final List<LatLng> _userPathHistory = [];
  double _actualDistanceMeters = 0.0;
  // --------------------------
  
  final Map<String, bool> _activeRouteNeedsState = {};
  final Set<String> _visitedWaypoints = {};
  final Set<String> _triggeredWikipediaNotifications = {};
  final Map<String, Timer> _waypointTimers = {};

  final FirestoreService _firestoreService = FirestoreService();
  final DirectionsService _directionsService = DirectionsService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription? _locationsSubscription;
  StreamSubscription? _groupsSubscription;
  StreamSubscription<Position>? _positionStreamSubscription;

  bool _isDataSyncInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialLocation == null) {
      _determinePosition();
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataSyncInitialized) {
      _setupDataSync();
      _isDataSyncInitialized = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationsSubscription?.cancel();
    _groupsSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _waypointTimers.forEach((_, timer) => timer.cancel());
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mapController?.setMapStyle('[]');
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (_searchController.text.isNotEmpty) {
        final predictions = await _directionsService.getAutocomplete(_searchController.text);
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

  void _toggleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.satellite;
      } else if (_currentMapType == MapType.satellite) {
        _currentMapType = MapType.terrain;
      } else {
        _currentMapType = MapType.normal;
      }
    });
  }

  void _resetBearing() {
    if (_mapController == null || _cameraPosition == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _cameraPosition!.target,
          zoom: _cameraPosition!.zoom,
          bearing: 0.0,
          tilt: 0.0,
        ),
      ),
    );
  }

  Future<void> _goToInitialLocation() async {
    if (widget.initialLocation == null || _mapController == null) return;
    final location = widget.initialLocation!;
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      if (_mapController != null) {
        await _goToCurrentLocation(isInitial: true);
      }
      await _updateMapElements();
    } catch (e) {
      // Handle error
    }
  }

  void _startLiveLocationTracking() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
    }
    if (_activeRouteLocations == null) {
      final locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
          "TripBook, uygulama arka planda çalışırken konumunuzu takip ediyor.",
          notificationTitle: "TripBook Rota Takibi",
          enableWakeLock: true,
        ),
      );
      _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          _updateMapElements();
        }
      });
    }
  }

  Future<void> _goToCurrentLocation({bool isInitial = false}) async {
    if (_currentPosition == null || _mapController == null) return;

    final cameraUpdate = CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 15.0,
      ),
    );

    await _mapController?.animateCamera(cameraUpdate);

    if (isInitial) {
      _startLiveLocationTracking();
    }
  }

  void _clearRoute() {
    setState(() {
      _polylines.clear();
      _activeRouteLocations = null;
      _activeRouteInfo = null;
      _activeRouteNeedsState.clear();
      _visitedWaypoints.clear();
      _routeStartTime = null;
      _isRouteCompleted = false;
      _activeRouteTotalStopDuration = null;
      _activeRouteTotalTripDuration = null;
      _activeRouteNeeds = null;
      _activeRouteNotes = null;
      _userPathHistory.clear();
      _actualDistanceMeters = 0.0;
    });
    _startLiveLocationTracking();
    _waypointTimers.forEach((key, timer) => timer.cancel());
    _waypointTimers.clear();
    _triggeredWikipediaNotifications.clear();
  }

  void _startRouteTracking(List<TravelLocation> locations) {
    _positionStreamSubscription?.cancel();
    setState(() {
      _activeRouteLocations = locations;
      _routeStartTime = DateTime.now();
      _isRouteCompleted = false;
      _userPathHistory.clear();
      _actualDistanceMeters = 0.0;
      if (_currentPosition != null) {
        _userPathHistory.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
      }
    });

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText:
        "TripBook, uygulama arka planda çalışırken konumunuzu takip ediyor.",
        notificationTitle: "TripBook Rota Takibi",
        enableWakeLock: true,
      ),
    );
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (mounted && !_isRouteCompleted) {
        final newPoint = LatLng(position.latitude, position.longitude);
        if (_userPathHistory.isNotEmpty) {
          final lastPoint = _userPathHistory.last;
          _actualDistanceMeters += Geolocator.distanceBetween(
            lastPoint.latitude, lastPoint.longitude, 
            newPoint.latitude, newPoint.longitude
          );
        }
        setState(() {
          _currentPosition = position;
          _userPathHistory.add(newPoint);
        });
        _updateMapElements();
        _checkAllWaypointsProximity(position);
      }
    });
  }

  void _handleRouteCompletion() {
    if (_routeStartTime == null) return;

    setState(() {
      _isRouteCompleted = true;
    });
    _positionStreamSubscription?.cancel();

    final elapsedDuration = DateTime.now().difference(_routeStartTime!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rota tamamlandı!'), duration: Duration(seconds: 2)),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showRouteCompletionSummary(elapsedDuration);
      }
    });
  }

  void _checkAllWaypointsProximity(Position userPosition) {
    if (_activeRouteLocations == null || FirebaseAuth.instance.currentUser == null || _isRouteCompleted) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    for (final location in _activeRouteLocations!) {
      final distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        location.latitude,
        location.longitude,
      );

      final locationId = location.firestoreId!;
      final isEndpoint = locationId == 'end';

      if (distance < 50 && !_visitedWaypoints.contains(locationId)) {
        if (isEndpoint) {
          final allOtherWaypointsVisited = _activeRouteLocations!
              .where((loc) => loc.firestoreId != 'end')
              .every((loc) => _visitedWaypoints.contains(loc.firestoreId));
          if (!allOtherWaypointsVisited) {
            continue;
          }
        }

        if (mounted) {
          setState(() {
            _visitedWaypoints.add(locationId);
          });
        }

        final allWaypointIds = _activeRouteLocations!.map((loc) => loc.firestoreId!).toSet();
        if (_visitedWaypoints.containsAll(allWaypointIds)) {
          _handleRouteCompletion();
          return; 
        }

        if (!_triggeredWikipediaNotifications.contains(locationId)) {
          _triggeredWikipediaNotifications.add(locationId);
          
          final infoUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(location.geoName)}';
          final title = 'Yakınlardasınız: ${location.name}';
          final summary = "Konum için google araması yapmak için tıklayın!";

          final newLog = ReachedLocationLog(
            locationName: location.name,
            geoName: location.geoName,
            infoUrl: infoUrl,
            timestamp: Timestamp.now(),
            userId: userId,
          );

          _firestoreService.addReachedLocationLog(newLog).then((logId) {
            final payload = logId != null ? 'open_logs_screen:$logId' : 'open_logs_screen';
            _notificationService.showNotification(title, summary, payload: payload);
          });
        }

        if (!_waypointTimers.containsKey(locationId) && (location.estimatedDuration ?? 0) > 0) {
          final timer = Timer(Duration(minutes: location.estimatedDuration!), () {
            _notificationService.showNotification(
              'Süreniz Doldu!',
              '${location.name} konumunda planladığınız süre doldu.'
            );
            _waypointTimers.remove(locationId);
          });
          _waypointTimers[locationId] = timer;
        }
      } else {
        if (_waypointTimers.containsKey(locationId)) {
          _waypointTimers[locationId]!.cancel();
          _waypointTimers.remove(locationId);
        }
      }
    }
  }

  void _setupDataSync() {
    if (FirebaseAuth.instance.currentUser == null) {
      _loadMarkersFromLocalDb();
      return;
    }

    _locationsSubscription = _firestoreService.getLocations().listen((locations) {
      if (mounted) {
        setState(() => _allLocations = locations);
        _updateMapElements();
      }
    }, onError: (error) {
      _loadMarkersFromLocalDb();
    });

    _groupsSubscription = _firestoreService.getGroups().listen((groups) {
      if (mounted) {
        setState(() => _allGroups = groups);
        _updateMapElements();
      }
    });
  }

  Future<void> _updateMapElements() async {
    if (!mounted) return;

    final groupsMap = { for (var group in _allGroups) group.firestoreId!: group };
    final Set<Marker> newMarkers = {};

    if (_currentPosition != null) {
      final icon = await marker_utils.getCurrentLocationMarkerIcon();
      newMarkers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Mevcut Konum'),
          icon: icon,
          zIndex: 2,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    if (_searchResultMarker != null) {
      newMarkers.add(_searchResultMarker!);
    }

    List<TravelLocation> locationsToDisplay = _activeRouteLocations ?? _allLocations;

    for (final loc in locationsToDisplay) {
      final isVisited = _activeRouteLocations != null && _visitedWaypoints.contains(loc.firestoreId);
      final isEndpoint = loc.firestoreId == 'end';

      Color color;
      if (isEndpoint) {
        color = Colors.purpleAccent;
      } else if (isVisited) {
        color = Colors.green;
      } else if (loc.groupId == null) {
        color = Colors.grey;
      } else {
        final group = groupsMap[loc.groupId];
        color = group?.color != null ? Color(group!.color!) : Colors.red;
      }
      
      final icon = await marker_utils.getCustomMarkerIcon(color, isEndpoint: isEndpoint);

      newMarkers.add(
        Marker(
          markerId: MarkerId(loc.firestoreId ?? loc.hashCode.toString()),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(title: loc.name, snippet: loc.description),
          icon: icon,
          onTap: () {
            if (loc.firestoreId != 'end') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageLocationsScreen(
                    initiallyExpandedLocationId: loc.firestoreId,
                  ),
                ),
              );
            }
          },
        ),
      );
    }

    final Set<Polyline> newPolylines = {};
    if (_activeRouteInfo != null && _activeRouteLocations != null) {
      final legs = _activeRouteInfo!.legsPoints;
      final routeWaypoints = [TravelLocation(name: 'Start', geoName: 'Start', latitude: 0, longitude: 0, firestoreId: 'start'), ..._activeRouteLocations!];

      for (int i = 0; i < legs.length; i++) {
        bool isLegVisited = false;
        if (i + 1 < routeWaypoints.length) {
           final destinationWaypointId = routeWaypoints[i+1].firestoreId;
           if (destinationWaypointId != null) {
             isLegVisited = _visitedWaypoints.contains(destinationWaypointId);
           }
        }
        if (i == 0 && _visitedWaypoints.contains(routeWaypoints[1].firestoreId)) {
          isLegVisited = true;
        }

        if (!isLegVisited) { // Only draw legs that have not been visited
          newPolylines.add(Polyline(
            polylineId: PolylineId('route_leg_$i'),
            color: Colors.grey.shade400,
            width: 5,
            points: legs[i].map((p) => LatLng(p.latitude, p.longitude)).toList(),
          ));
        }
      }
    }

    // Add the user's actual path history
    if (_userPathHistory.length > 1) {
      newPolylines.add(Polyline(
        polylineId: const PolylineId('userPath'),
        color: Colors.purpleAccent,
        width: 5,
        points: List.from(_userPathHistory),
      ));
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
        _polylines.clear();
        _polylines.addAll(newPolylines);
      });
    }
  }

  Future<void> _loadMarkersFromLocalDb() async {
    final locations = await DatabaseService.instance.readAllLocations();
    if (mounted) {
      setState(() {
        for (final loc in locations) {
          _markers.add(
            Marker(
              markerId: MarkerId(loc.id.toString()),
              position: LatLng(loc.latitude, loc.longitude),
              infoWindow: InfoWindow(title: loc.name, snippet: loc.description),
              onTap: () {},
            ),
          );
        }
      });
    }
  }

  Future<void> _drawRoute(List<TravelLocation> locations, {TravelLocation? endLocation}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.currentLocationError)),
      );
      return;
    }

    _activeRouteNeedsState.clear();
    _visitedWaypoints.clear();
    _triggeredWikipediaNotifications.clear();

    final userLocation = TravelLocation(
      name: 'Mevcut Konumunuz', // Internal
      geoName: 'Mevcut Konumunuz', // Internal
      description: 'Rota başlangıcı', // Internal
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      firestoreId: 'start',
    );

    var routeLocations = [userLocation, ...locations];
    TravelLocation finalDestination = endLocation ??
        TravelLocation(
          name: 'Bitiş Noktası', // Internal
          geoName: await _directionsService.getPlaceName(LatLng(_currentPosition!.latitude, _currentPosition!.longitude)) ?? l10n.unknownLocation,
          description: 'Rota bitişi', // Internal
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          firestoreId: 'end',
        );
    routeLocations.add(finalDestination);

    final directionsInfo = await _directionsService.getDirections(routeLocations);

    if (directionsInfo != null) {
      setState(() {
        _activeRouteInfo = directionsInfo;
        _activeRouteLocations = [...locations, finalDestination];
      });

      _updateMapElements();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(directionsInfo.bounds, 50),
      );

      _showRouteSummary(directionsInfo, locations);
      _startRouteTracking(locations);
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.drawRouteError)),
       );
    }
  }

  int _parseDuration(String durationString) {
    int totalMinutes = 0;
    final parts = durationString.toLowerCase().split(' ');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].contains('hour') || parts[i].contains('saat')) {
        if (i > 0) {
          totalMinutes += (int.tryParse(parts[i-1]) ?? 0) * 60;
        }
      } else if (parts[i].contains('min') || parts[i].contains('dakika')) {
        if (i > 0) {
          totalMinutes += int.tryParse(parts[i-1]) ?? 0;
        }
      }
    }
    return totalMinutes;
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes < 0) return '0 dakika';
    if (totalMinutes < 60) {
      return '$totalMinutes dakika';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '$hours saat';
    }
    return '$hours saat $minutes dakika';
  }

  String _formatElapsedDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _showSaveRouteDialog(DirectionsInfo info, List<TravelLocation> locations, {
    Duration? actualDuration,
    String? actualDistance,
    String? totalStopDuration,
    String? totalTripDuration,
    List<String>? needs,
    List<Map<String, String>>? notes,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final routeNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.saveRouteDialogTitle),
          content: TextField(
            controller: routeNameController,
            decoration: InputDecoration(hintText: l10n.routeNameHint),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final routeName = routeNameController.text;
                if (routeName.isEmpty) return;

                final existingRoutes = await _firestoreService.getRoutesOnce();
                final conflictingRoute = existingRoutes.firstWhere(
                  (r) => r.name.toLowerCase() == routeName.toLowerCase(),
                  orElse: () => TravelRoute(name: 'dummy', locationIds: [], totalDistance: '', totalTravelTime: ''),
                );

                bool shouldProceed = true;
                if (conflictingRoute.firestoreId != null) {
                  shouldProceed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.confirm),
                          content: Text(l10n.routeExistsError(routeName)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.no)),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.yes)),
                          ],
                        ),
                      ) ??
                      false;
                }

                if (!shouldProceed) return;

                final newRoute = TravelRoute(
                  name: routeName,
                  locationIds: locations.map((l) => l.firestoreId!).toList(),
                  totalTravelTime: info.totalDuration,
                  totalDistance: info.totalDistance,
                  totalStopDuration: totalStopDuration ?? conflictingRoute.totalStopDuration,
                  totalTripDuration: totalTripDuration ?? conflictingRoute.totalTripDuration,
                  needs: needs ?? conflictingRoute.needs,
                  notes: notes ?? conflictingRoute.notes,
                  actualDuration: actualDuration != null ? _formatElapsedDuration(actualDuration) : conflictingRoute.actualDuration,
                  actualDistance: actualDistance ?? conflictingRoute.actualDistance,
                );

                if (conflictingRoute.firestoreId != null) {
                  await _firestoreService.updateRoute(conflictingRoute.firestoreId!, newRoute);
                } else {
                  await _firestoreService.addRoute(newRoute);
                }

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.routeSavedSuccess(routeName)), backgroundColor: Colors.green),
                  );
                  _clearRoute();
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  void _showRouteCompletionSummary(Duration elapsedDuration) {
    final l10n = AppLocalizations.of(context)!;
    final actualDistanceKm = _actualDistanceMeters / 1000.0;
    final actualDistanceString = '${actualDistanceKm.toStringAsFixed(1)} km';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.routeCompletionDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.plannedDistance}: ${_activeRouteInfo?.totalDistance ?? "N/A"}'),
              Text('${l10n.actualDistance}: $actualDistanceString', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${l10n.plannedTotalDuration}: ${_activeRouteTotalTripDuration ?? "N/A"}'),
              Text('${l10n.actualDuration}: ${_formatElapsedDuration(elapsedDuration)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearRoute();
              },
              child: Text(l10n.exit),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSaveRouteDialog(
                  _activeRouteInfo!,
                  _activeRouteLocations!,
                  actualDuration: elapsedDuration,
                  actualDistance: actualDistanceString,
                  totalStopDuration: _activeRouteTotalStopDuration,
                  totalTripDuration: _activeRouteTotalTripDuration,
                  needs: _activeRouteNeeds,
                  notes: _activeRouteNotes,
                );
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  void _showRouteSummary(DirectionsInfo info, List<TravelLocation> locations) {
    final l10n = AppLocalizations.of(context)!;
    final List<NeedItem> allNeeds = [];
    for (var loc in locations) {
      if (loc.needsList != null && loc.firestoreId != null) {
        for (var i = 0; i < loc.needsList!.length; i++) {
          final needMap = loc.needsList![i];
          if (needMap['name'] is String) {
            final needName = needMap['name']!;
            allNeeds.add(NeedItem(
              name: needName,
              isChecked: _activeRouteNeedsState[needName] ?? false,
              locationId: loc.firestoreId!,
              originalIndex: i,
            ));
          }
        }
      }
    }

    final Map<String, NeedItem> consolidatedNeedsMap = {};
    for (final needItem in allNeeds) {
      consolidatedNeedsMap.putIfAbsent(needItem.name, () => needItem);
    }
    final consolidatedNeeds = consolidatedNeedsMap.values.toList();

    final privateNotes = locations
        .where((loc) => loc.notes != null && loc.notes!.isNotEmpty)
        .map((loc) => {'locationName': loc.name, 'note': loc.notes!})
        .toList();

    final totalStopDuration = locations.fold<int>(
      0,
      (total, loc) => total + (loc.estimatedDuration ?? 0),
    );

    final travelDuration = _parseDuration(info.totalDuration);
    final totalTripDuration = travelDuration + totalStopDuration;

    _activeRouteTotalStopDuration = _formatDuration(totalStopDuration);
    _activeRouteTotalTripDuration = _formatDuration(totalTripDuration);
    _activeRouteNeeds = consolidatedNeeds.map((e) => e.name).toList();
    _activeRouteNotes = privateNotes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.routeSummaryTitle, style: Theme.of(context).textTheme.headlineSmall),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.save, color: Colors.blue),
                            tooltip: l10n.saveRouteDialogTitle,
                            onPressed: () {
                              Navigator.pop(context);
                              _showSaveRouteDialog(
                                info, 
                                locations,
                                totalStopDuration: _activeRouteTotalStopDuration,
                                totalTripDuration: _activeRouteTotalTripDuration,
                                needs: _activeRouteNeeds,
                                notes: _activeRouteNotes,
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _launchGoogleMaps(locations);
                            },
                            icon: const Icon(Icons.navigation),
                            label: Text(l10n.startNavigation),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(title: Text('${l10n.estimatedTravelTime}: ${info.totalDuration}')),
                        ListTile(title: Text('${l10n.totalTimeAtStops}: ${_formatDuration(totalStopDuration)}')),
                        ListTile(title: Text('${l10n.totalTripTime}: ${_formatDuration(totalTripDuration)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                        ListTile(title: Text('${l10n.totalDistance}: ${info.totalDistance}')),
                        const Divider(),
                        if (consolidatedNeeds.isNotEmpty)
                          ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text(l10n.needsForTrip, style: Theme.of(context).textTheme.titleLarge),
                            ),
                            ...consolidatedNeeds.map((needItem) {
                              return CheckboxListTile(
                                title: Text(needItem.name),
                                value: needItem.isChecked,
                                onChanged: (bool? newValue) {
                                  if (newValue == null) return;
                                  
                                  setModalState(() {
                                    needItem.isChecked = newValue;
                                    _activeRouteNeedsState[needItem.name] = newValue;
                                  });
                                },
                              );
                            }),
                            const Divider(),
                          ],
                        if (privateNotes.isNotEmpty)
                          ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text(l10n.notesForTrip, style: Theme.of(context).textTheme.titleLarge),
                            ),
                            ...privateNotes.map((note) => ListTile(leading: const Icon(Icons.note), title: Text('${note['locationName']}: ${note['note']}'))),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchGoogleMaps(List<TravelLocation> locations) async {
    final l10n = AppLocalizations.of(context)!;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.currentLocationError)),
      );
      return;
    }
    if (locations.isEmpty) return;

    final origin = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
    final destination = '${locations.last.latitude},${locations.last.longitude}';
    String waypoints = '';

    if (locations.length > 1) {
      waypoints = locations
          .sublist(0, locations.length - 1)
          .map((loc) => '${loc.latitude},${loc.longitude}')
          .join('|');
    }

    String url = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination';
    if (waypoints.isNotEmpty) {
      url += '&waypoints=$waypoints';
    }
    url += '&travelmode=driving';

    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.launchMapsError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final initialCamPos = widget.initialLocation != null
        ? CameraPosition(
            target: LatLng(widget.initialLocation!.latitude,
                widget.initialLocation!.longitude),
            zoom: 15,
          )
        : const CameraPosition(
            target: LatLng(38.9637, 35.2433), // Turkey
            zoom: 5,
          );

    List<Widget> appBarActions = _activeRouteLocations == null
        ? [
            IconButton(
              icon: const Icon(Icons.directions),
              tooltip: l10n.createRoute,
              onPressed: _showRouteCreationDialog,
            ),
            IconButton(
              icon: const Icon(Icons.route_sharp),
              tooltip: l10n.savedRoutes,
              onPressed: () async {
                final List<String>? locationIds = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedRoutesScreen(),
                  ),
                );
                if (!mounted) return;
                if (locationIds != null && locationIds.isNotEmpty) {
                  final locations = await _firestoreService.getLocationsByIds(locationIds);
                  if (locations.length >= 2) {
                    _drawRoute(locations);
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bu rotadaki konumlar bulunamadı veya yetersiz.')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: l10n.reachedLocations,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReachedLocationsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: l10n.manageLocations,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageLocationsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.folder_copy_outlined),
              tooltip: l10n.manageGroups,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroupsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: l10n.profileScreenTitle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            )
          ]
        : [
            if (_activeRouteInfo != null)
              IconButton(
                icon: const Icon(Icons.summarize),
                tooltip: l10n.activeRouteSummary,
                onPressed: () {
                  _showRouteSummary(_activeRouteInfo!, _activeRouteLocations!);
                },
              ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: l10n.reachedLocations,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReachedLocationsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.clearRoute,
              onPressed: _clearRoute,
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: appBarActions,
        backgroundColor: Colors.blue[700],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) async {
              _mapController = controller;
              if (widget.initialLocation != null) {
                await _goToInitialLocation();
              } else if (_currentPosition != null) {
                await _goToCurrentLocation(isInitial: true);
              }
            },
            initialCameraPosition: initialCamPos,
            markers: _markers,
            polylines: _polylines,
            onLongPress: (pos) async {
              if (_isSelectingEndpoint) {
                final geoName = await _directionsService.getPlaceName(pos) ?? l10n.unknownLocation;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.confirmEndpointDialogTitle),
                    content: Text(l10n.confirmEndpointDialogContent(geoName)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.confirm),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final endLocation = TravelLocation(
                    name: 'Seçilen Bitiş Noktası', // Internal name, no need to translate
                    geoName: geoName,
                    latitude: pos.latitude,
                    longitude: pos.longitude,
                    firestoreId: 'end',
                  );
                  final finalRoute = await Navigator.push<List<TravelLocation>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationSelectionScreen(initialLocations: _locationsForRoute, endLocation: endLocation),
                    ),
                  );
                  if (finalRoute != null) {
                    _drawRoute(finalRoute);
                  }
                }
                setState(() {
                  _isSelectingEndpoint = false;
                });
              } else {
                _showAddLocationDialog(pos);
              }
            },
            mapType: _currentMapType,
            compassEnabled: false,
            myLocationButtonEnabled: false, 
            myLocationEnabled: false,
            onCameraMove: (position) {
              _cameraPosition = position;
              setState(() {
                _currentBearing = position.bearing;
              });
            },
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.search, color: Colors.grey),
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
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _placePredictions = [];
                            _searchResultMarker = null;
                            _updateMapElements();
                          });
                        },
                      )
                    ],
                  ),
                ),
                if (_placePredictions.isNotEmpty)
                  Material(
                    elevation: 4.0,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _placePredictions.length,
                        itemBuilder: (context, index) {
                          final prediction = _placePredictions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(prediction['description'] ?? l10n.unknownLocation),
                            onTap: () async {
                              final placeId = prediction['place_id'];
                              if (placeId == null) return;

                              final details = await _directionsService.getPlaceDetails(placeId);
                              if (details == null || !mounted) return;

                              final location = details['geometry']?['location'];
                              if (location == null) return;

                              final lat = location['lat'];
                              final lng = location['lng'];
                              final latLng = LatLng(lat, lng);

                              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

                              setState(() {
                                _searchResultMarker = Marker(
                                  markerId: const MarkerId('searchResult'),
                                  position: latLng,
                                  infoWindow: InfoWindow(title: prediction['description']),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                );
                                _placePredictions = [];
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                                _updateMapElements();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 70,
            right: 15,
            child: FloatingActionButton(
              mini: true,
              onPressed: _toggleMapType,
              tooltip: l10n.mapTypeTooltip,
              backgroundColor: Colors.white,
              child: const Icon(Icons.layers, color: Colors.black),
            ),
          ),
          if (_currentBearing != 0)
            Positioned(
              top: 125,
              right: 15,
              child: FloatingActionButton(
                mini: true,
                onPressed: _resetBearing,
                tooltip: l10n.resetBearingTooltip,
                backgroundColor: Colors.white,
                child: const Icon(Icons.explore_outlined, color: Colors.black),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: () => _goToCurrentLocation(isInitial: false),
          tooltip: l10n.myLocationTooltip,
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }

  List<TravelLocation> _optimizeRouteByProximity(List<TravelLocation> locations, Position startPosition) {
    if (locations.length < 2) return locations;

    List<TravelLocation> remaining = List.from(locations);
    List<TravelLocation> optimized = [];

    LatLng currentPoint = LatLng(startPosition.latitude, startPosition.longitude);

    while (remaining.isNotEmpty) {
      TravelLocation? closest;
      double? minDistance;

      for (final location in remaining) {
        final distance = Geolocator.distanceBetween(
          currentPoint.latitude,
          currentPoint.longitude,
          location.latitude,
          location.longitude,
        );

        if (minDistance == null || distance < minDistance) {
          minDistance = distance;
          closest = location;
        }
      }

      if (closest != null) {
        optimized.add(closest);
        remaining.remove(closest);
        currentPoint = LatLng(closest.latitude, closest.longitude);
      }
    }

    return optimized;
  }

  void _showRouteCreationDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.createRouteDialogTitle),
        content: Text(l10n.createRouteDialogContent),
        actions: [
          TextButton(
            child: Text(l10n.fromGroup),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final result = await Navigator.push<Map<String, String>>(
                context,
                MaterialPageRoute(builder: (context) => const GroupsScreen(isForSelection: true)),
              );

              if (!mounted || result == null || _currentPosition == null) return;

              final selectedGroupId = result['id'];

              if (selectedGroupId != null) {
                final locations = await _firestoreService.getLocationsForGroup(selectedGroupId);
                if (locations.length >= 2) {
                  final optimizedLocations = _optimizeRouteByProximity(locations, _currentPosition!);
                  final endLocationLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
                  final endLocationGeoName = await _directionsService.getPlaceName(endLocationLatLng) ?? l10n.unknownLocation;
                  final endLocation = TravelLocation(name: 'Bitiş', geoName: endLocationGeoName, latitude: endLocationLatLng.latitude, longitude: endLocationLatLng.longitude, firestoreId: 'end');

                  final result = await Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationSelectionScreen(initialLocations: optimizedLocations, endLocation: endLocation),
                    ),
                  );
                  if (result is List<TravelLocation>) {
                    _drawRoute(result);
                  } else if (result == 'change_end_location') {
                    setState(() {
                      _isSelectingEndpoint = true;
                      _locationsForRoute = optimizedLocations;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.selectNewEndpoint)),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.minTwoLocationsError)),
                  );
                }
              }
            },
          ),
          TextButton(
            child: Text(l10n.manualSelection),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final List<TravelLocation>? finalRoute = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
              );

              if (finalRoute != null && finalRoute.length >= 2) {
                _locationsForRoute = finalRoute;
                _promptForEndpoint(finalRoute);
              } else if (finalRoute != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.minTwoLocationsError)),
                );
              }
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _promptForEndpoint(List<TravelLocation> locations) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.endPointDialogTitle),
        content: Text(l10n.endPointDialogContent),
        actions: [
          TextButton(
            child: Text(l10n.selectFromMap),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() {
                _isSelectingEndpoint = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(l10n.selectNewEndpoint)),
              );
            },
          ),
          TextButton(
            child: Text(l10n.continueButton),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _drawRoute(locations);
            },
          ),
        ],
      ),
    );
  }

  void _showAddLocationDialog(LatLng pos) async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final String geoName = await _directionsService.getPlaceName(pos) ?? l10n.unknownLocation;
    
    if (!mounted) return;
    Navigator.of(context).pop();

    final customNameController = TextEditingController(text: geoName);
    final descriptionController = TextEditingController();
    final notesController = TextEditingController();
    final needsController = TextEditingController();
    final durationController = TextEditingController();
    String? selectedGroupId;
    String? selectedGroupName;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.addLocationDialogTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.realLocationNameLabel, style: Theme.of(context).textTheme.bodySmall),
                    Text(geoName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customNameController,
                      decoration: InputDecoration(labelText: l10n.customLocationNameLabel, icon: const Icon(Icons.edit_location_alt)),
                      autofocus: true,
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: l10n.descriptionLabel, icon: const Icon(Icons.description)),
                    ),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(labelText: l10n.notesLabel, icon: const Icon(Icons.note)),
                    ),
                    TextField(
                      controller: durationController,
                      decoration: InputDecoration(labelText: l10n.estimatedDurationLabel, icon: const Icon(Icons.timer)),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: needsController,
                      decoration: InputDecoration(labelText: l10n.needsLabel, icon: const Icon(Icons.list)),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.group),
                      title: Text(selectedGroupName ?? l10n.selectGroupOptionalLabel),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        final result = await Navigator.push<Map<String, String>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GroupsScreen(isForSelection: true),
                          ),
                        );
                        if (result != null && result is Map<String, String>) {
                          setState(() {
                            selectedGroupId = result['id'];
                            selectedGroupName = result['name'];
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (customNameController.text.isNotEmpty) {
                      final needsList = needsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .map((name) => {'name': name, 'checked': false})
                          .toList();
                      final duration = int.tryParse(durationController.text);

                      final newLocation = TravelLocation(
                        name: customNameController.text,
                        geoName: geoName,
                        description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                        latitude: pos.latitude,
                        longitude: pos.longitude,
                        groupId: selectedGroupId,
                        notes: notesController.text.isNotEmpty ? notesController.text : null,
                        needsList: needsList.isNotEmpty ? needsList : null,
                        estimatedDuration: duration,
                      );

                      await _firestoreService.addLocation(newLocation);
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
