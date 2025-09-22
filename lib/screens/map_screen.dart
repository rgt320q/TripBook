import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/location_group.dart';
import 'package:tripbook/models/reached_location_log.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/providers/locale_provider.dart';
import 'package:tripbook/screens/community_routes_screen.dart';
import 'package:tripbook/screens/groups_screen.dart';
import 'package:tripbook/screens/location_selection_screen.dart';
import 'package:tripbook/screens/manage_locations_screen.dart';
import 'package:tripbook/screens/profile_screen.dart';
import 'package:tripbook/screens/reached_locations_screen.dart';
import 'package:tripbook/screens/saved_routes_screen.dart';
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
  final bool isChangingEndPoint;
  const MapScreen({
    super.key,
    this.initialLocation,
    this.isChangingEndPoint = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  bool _isLoading = true;

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

  final List<Color> _groupColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  List<TravelLocation> _allLocations = [];
  List<LocationGroup> _allGroups = [];
  GeoPoint? _homeLocation;

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
  bool _isNavigationStarted = false;
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
  StreamSubscription? _profileSubscription;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
    _searchController.addListener(_onSearchChanged);
  }

  Future<LocationGroup?> _showAddNewGroupDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final groupNameController = TextEditingController();
    Color selectedColor = _groupColors.first;
    final formKey = GlobalKey<FormState>();

    return await showDialog<LocationGroup>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.newGroup),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: groupNameController,
                        decoration: InputDecoration(
                          labelText: l10n.groupName,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.locationNameEmptyError;
                          }
                          final invalidChars = RegExp(r'[<>]');
                          if (invalidChars.hasMatch(value)) {
                            return l10n.invalidGroupNameError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.selectGroupColor),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _groupColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newGroup = LocationGroup(
                        name: groupNameController.text.trim(),
                        color: selectedColor.value,
                        createdAt: DateTime.now(),
                        userId: FirebaseAuth.instance.currentUser!.uid,
                      );
                      final docRef = await _firestoreService.addGroup(newGroup);
                      final createdGroup = LocationGroup(
                        firestoreId: docRef.id,
                        name: newGroup.name,
                        color: newGroup.color,
                        createdAt: newGroup.createdAt,
                        userId: newGroup.userId,
                      );
                      Navigator.of(dialogContext).pop(createdGroup);
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

  Future<void> _initializeScreen() async {
    // Load profile and set locale
    final UserProfile? profile = await _firestoreService.getUserProfile().first;
    if (mounted && profile != null) {
      final langCode = profile.languageCode ?? 'tr';
      Provider.of<LocaleProvider>(context, listen: false)
          .setLocale(Locale(langCode));
    }

    // Now determine position and setup data sync
    await _determinePosition();
    _setupDataSync();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationsSubscription?.cancel();
    _groupsSubscription?.cancel();
    _profileSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _waypointTimers.forEach((_, timer) => timer.cancel());
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (_searchController.text.isNotEmpty) {
        final predictions =
            await _directionsService.getAutocomplete(_searchController.text);
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
      if (_mapController != null && widget.initialLocation == null) {
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
      final l10n = AppLocalizations.of(context)!;
      final locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationText: l10n.backgroundLocationNotificationText,
          notificationTitle: l10n.backgroundLocationNotificationTitle,
          enableWakeLock: true,
        ),
      );
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
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
      _isNavigationStarted = false;
    });
    _startLiveLocationTracking();
    _waypointTimers.forEach((key, timer) => timer.cancel());
    _waypointTimers.clear();
    _triggeredWikipediaNotifications.clear();
  }

  void _startRouteTracking() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _routeStartTime = DateTime.now();
      _isRouteCompleted = false;
      _userPathHistory.clear();
      _actualDistanceMeters = 0.0;
      if (_currentPosition != null) {
        _userPathHistory.add(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        );
      }
    });

    final l10n = AppLocalizations.of(context)!;
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationText: l10n.backgroundLocationNotificationText,
        notificationTitle: l10n.backgroundLocationNotificationTitle,
        enableWakeLock: true,
      ),
    );
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (mounted && !_isRouteCompleted) {
        final newPoint = LatLng(position.latitude, position.longitude);
        if (_userPathHistory.isNotEmpty) {
          final lastPoint = _userPathHistory.last;
          _actualDistanceMeters += Geolocator.distanceBetween(
            lastPoint.latitude,
            lastPoint.longitude,
            newPoint.latitude,
            newPoint.longitude,
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
    final l10n = AppLocalizations.of(context)!;
    if (_routeStartTime == null) return;

    setState(() {
      _isRouteCompleted = true;
    });
    _positionStreamSubscription?.cancel();

    final elapsedDuration = DateTime.now().difference(_routeStartTime!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.routeCompleted),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showRouteCompletionSummary(elapsedDuration);
      }
    });
  }

  String? _notificationSound;

  void _checkAllWaypointsProximity(Position userPosition) {
    final l10n = AppLocalizations.of(context)!;
    if (_activeRouteLocations == null ||
        FirebaseAuth.instance.currentUser == null ||
        _isRouteCompleted) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    for (final location in _activeRouteLocations!) {
      final distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        location.latitude,
        location.longitude,
      );

      final locationId = location.firestoreId!;
      final isEndpoint =
          locationId == 'end' || locationId == 'home_end_location';

      if (distance < 50 && !_visitedWaypoints.contains(locationId)) {
        if (isEndpoint) {
          final allOtherWaypointsVisited = _activeRouteLocations!
              .where(
                (loc) =>
                    loc.firestoreId != 'end' &&
                    loc.firestoreId != 'home_end_location',
              )
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

        final allWaypointIds =
            _activeRouteLocations!.map((loc) => loc.firestoreId!).toSet();
        if (_visitedWaypoints.containsAll(allWaypointIds)) {
          _handleRouteCompletion();
          return;
        }

        if (!_triggeredWikipediaNotifications.contains(locationId)) {
          _triggeredWikipediaNotifications.add(locationId);

          final infoUrl =
              'https://www.google.com/search?q=${Uri.encodeComponent(location.geoName)}';
          final title = l10n.nearbyLocationNotificationTitle(location.name);
          final summary = l10n.nearbyLocationNotificationBody;

          final newLog = ReachedLocationLog(
            locationName: location.name,
            geoName: location.geoName,
            infoUrl: infoUrl,
            timestamp: Timestamp.now(),
            userId: userId,
          );

          _firestoreService.addReachedLocationLog(newLog).then((logId) {
            final payload = logId != null
                ? 'open_logs_screen:$logId'
                : 'open_logs_screen';
            _notificationService.showNotification(
              title,
              summary,
              payload: payload,
            );
          });
        }

        if (!_waypointTimers.containsKey(locationId) &&
            (location.estimatedDuration ?? 0) > 0) {
          final timer = Timer(
            Duration(minutes: location.estimatedDuration!),
            () {
              _notificationService.showNotification(
                l10n.timeExpiredNotificationTitle,
                l10n.timeExpiredNotificationBody(location.name),
              );
              _waypointTimers.remove(locationId);
            },
          );
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

    _locationsSubscription = _firestoreService.getLocations().listen(
      (locations) {
        if (mounted) {
          setState(() => _allLocations = locations);
          _updateMapElements();
        }
      },
      onError: (error) {
        _loadMarkersFromLocalDb();
      },
    );

    _groupsSubscription = _firestoreService.getGroups().listen((groups) {
      if (mounted) {
        setState(() => _allGroups = groups);
        _updateMapElements();
      }
    });

    _profileSubscription = _firestoreService.getUserProfile().listen((profile) {
      if (mounted && profile != null) {
        setState(() {
          _homeLocation = profile.homeLocation;
        });
        _updateMapElements();
      }
    });
  }

  Future<void> _updateMapElements() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final groupsMap = {for (var group in _allGroups) group.firestoreId!: group};
    final Set<Marker> newMarkers = {};

    if (_currentPosition != null) {
      final icon = await marker_utils.getCurrentLocationMarkerIcon();
      newMarkers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: InfoWindow(title: l10n.myLocationTooltip),
          icon: icon,
          zIndex: 2,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    if (_homeLocation != null) {
      final icon = await marker_utils.getHomeMarkerIcon();
      newMarkers.add(
        Marker(
          markerId: const MarkerId('homeLocation'),
          position: LatLng(_homeLocation!.latitude, _homeLocation!.longitude),
          infoWindow: InfoWindow(title: l10n.homeLocation),
          icon: icon,
          zIndex: 1,
        ),
      );
    }

    if (_searchResultMarker != null) {
      newMarkers.add(_searchResultMarker!);
    }

    List<TravelLocation> locationsToDisplay =
        _activeRouteLocations ?? _allLocations;

    for (final loc in locationsToDisplay) {
      final isVisited = _activeRouteLocations != null &&
          _visitedWaypoints.contains(loc.firestoreId);
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

      final icon = await marker_utils.getCustomMarkerIcon(
        color,
        isEndpoint: isEndpoint,
      );

      newMarkers.add(
        Marker(
          markerId: MarkerId(loc.firestoreId ?? loc.hashCode.toString()),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(title: loc.name, snippet: loc.description),
          icon: icon,
          zIndex: isEndpoint ? 4 : (isVisited ? 1 : 2),
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
      final routeWaypoints = [
        TravelLocation(
          name: 'Start',
          geoName: 'Start',
          latitude: 0,
          longitude: 0,
          firestoreId: 'start',
          userId: '',
        ),
        ..._activeRouteLocations!,
      ];

      for (int i = 0; i < legs.length; i++) {
        bool isLegVisited = false;
        if (i + 1 < routeWaypoints.length) {
          final destinationWaypointId = routeWaypoints[i + 1].firestoreId;
          if (destinationWaypointId != null) {
            isLegVisited = _visitedWaypoints.contains(destinationWaypointId);
          }
        }
        if (i == 0 &&
            _visitedWaypoints.contains(routeWaypoints[1].firestoreId)) {
          isLegVisited = true;
        }

        if (!isLegVisited) {
          newPolylines.add(
            Polyline(
              polylineId: PolylineId('route_leg_$i'),
              color: Colors.grey.shade400,
              width: 5,
              points: legs[i]
                  .map((p) => LatLng(p.latitude, p.longitude))
                  .toList(),
            ),
          );
        }
      }
    }

    if (_userPathHistory.length > 1) {
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('userPath'),
          color: Colors.purpleAccent,
          width: 5,
          points: List.from(_userPathHistory),
        ),
      );
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

  void _drawRoute(
    List<TravelLocation> locations, {
    TravelLocation? endLocation,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.currentLocationError)));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    _activeRouteNeedsState.clear();
    _visitedWaypoints.clear();
    _triggeredWikipediaNotifications.clear();

    final userLocation = TravelLocation(
      name: l10n.currentLocation,
      geoName: 'Mevcut Konumunuz',
      description: l10n.routeStart,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      firestoreId: 'start',
      userId: '',
    );

    TravelLocation finalDestination;
    List<TravelLocation> waypoints = List.from(locations);

    if (endLocation != null) {
      finalDestination = endLocation;
      waypoints.removeWhere(
        (loc) => loc.firestoreId == endLocation.firestoreId,
      );
    } else if (waypoints.isNotEmpty) {
      finalDestination = waypoints.removeLast();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.minOneLocationError)));
      return;
    }

    finalDestination = TravelLocation(
      name: finalDestination.name,
      geoName: finalDestination.geoName,
      description: finalDestination.description,
      latitude: finalDestination.latitude,
      longitude: finalDestination.longitude,
      firestoreId: 'end',
      id: finalDestination.id,
      groupId: finalDestination.groupId,
      notes: finalDestination.notes,
      needsList: finalDestination.needsList,
      estimatedDuration: finalDestination.estimatedDuration,
      createdAt: finalDestination.createdAt,
      isImported: finalDestination.isImported,
      userId: '',
    );

    var routeLocationsForApi = [userLocation, ...waypoints, finalDestination];
    final directionsInfo =
        await _directionsService.getDirections(routeLocationsForApi);

    if (directionsInfo != null) {
      final activeRouteLocations = [...waypoints, finalDestination];
      setState(() {
        _activeRouteInfo = directionsInfo;
        _activeRouteLocations = activeRouteLocations;
      });

      _updateMapElements();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(directionsInfo.bounds, 50),
      );

      _showRouteSummary(directionsInfo, activeRouteLocations);
      _startRouteTracking();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.drawRouteError)));
    }
  }

  int _parseDuration(String durationString) {
    int totalMinutes = 0;
    final parts = durationString.toLowerCase().split(' ');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].contains('hour') || parts[i].contains('saat')) {
        if (i > 0) {
          totalMinutes += (int.tryParse(parts[i - 1]) ?? 0) * 60;
        }
      } else if (parts[i].contains('min') || parts[i].contains('dakika')) {
        if (i > 0) {
          totalMinutes += int.tryParse(parts[i - 1]) ?? 0;
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

  void _showSaveRouteDialog(
    DirectionsInfo info,
    List<TravelLocation> locations, {
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
                final l10n = AppLocalizations.of(context)!;
                final routeName = routeNameController.text.trim();
                if (routeName.isEmpty) return;

                final invalidChars = RegExp(r'[<>]');
                if (invalidChars.hasMatch(routeName)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.routeNameInvalidCharsError),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }

                final existingRoutes = await _firestoreService.getRoutesOnce();
                final conflictingRoute = existingRoutes.firstWhere(
                  (r) => r.name.toLowerCase() == routeName.toLowerCase(),
                  orElse: () => TravelRoute(
                    name: 'dummy',
                    locationIds: [],
                    totalDistance: '',
                    totalTravelTime: '',
                  ),
                );

                bool shouldProceed = true;
                if (conflictingRoute.firestoreId != null) {
                  shouldProceed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.confirm),
                          content: Text(l10n.routeExistsError(routeName)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.no),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.yes),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                }

                if (!shouldProceed || !mounted) return;

                final newRoute = TravelRoute(
                  name: routeName,
                  locationIds: locations.map((l) => l.firestoreId!).toList(),
                  totalTravelTime: info.totalDuration,
                  totalDistance: info.totalDistance,
                  totalStopDuration:
                      totalStopDuration ?? conflictingRoute.totalStopDuration,
                  totalTripDuration:
                      totalTripDuration ?? conflictingRoute.totalTripDuration,
                  needs: needs ?? conflictingRoute.needs,
                  notes: notes ?? conflictingRoute.notes,
                  actualDuration: actualDuration != null
                      ? _formatElapsedDuration(actualDuration)
                      : conflictingRoute.actualDuration,
                  actualDistance:
                      actualDistance ?? conflictingRoute.actualDistance,
                );

                if (conflictingRoute.firestoreId != null) {
                  await _firestoreService.updateRoute(
                    conflictingRoute.firestoreId!,
                    newRoute,
                  );
                } else {
                  await _firestoreService.addRoute(newRoute);
                }

                if (!mounted) return;

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.routeSavedSuccess(routeName)),
                    backgroundColor: Colors.green,
                  ),
                );
                _clearRoute();
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
    final actualDistanceString =
        l10n.distanceKm(actualDistanceKm.toStringAsFixed(1));

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
              Text(
                '${l10n.plannedDistance}: ${_activeRouteInfo?.totalDistance ?? l10n.notAvailable}',
              ),
              Text(
                '${l10n.actualDistance}: $actualDistanceString',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.plannedTotalDuration}: ${_activeRouteTotalTripDuration ?? l10n.notAvailable}',
              ),
              Text(
                '${l10n.actualDuration}: ${_formatElapsedDuration(elapsedDuration)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
            allNeeds.add(
              NeedItem(
                name: needName,
                isChecked: _activeRouteNeedsState[needName] ?? false,
                locationId: loc.firestoreId!,
                originalIndex: i,
              ),
            );
          }
        }
      }
    }

    final Map<String, NeedItem> consolidatedNeedsMap = {};
    for (final needItem in allNeeds) {
      consolidatedNeedsMap.putIfAbsent(needItem.name, () => needItem);
    }
    final consolidatedNeeds = consolidatedNeedsMap.values.toList();

    final locationsWithInfo = locations
        .where((loc) =>
            (loc.notes != null && loc.notes!.isNotEmpty) ||
            (loc.estimatedDuration != null && loc.estimatedDuration! > 0))
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
    _activeRouteNotes = locations
        .where((loc) => loc.notes != null && loc.notes!.isNotEmpty)
        .map((loc) => {'locationName': loc.name, 'note': loc.notes!})
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: StatefulBuilder(
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
                        Text(
                          l10n.routeSummaryTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (!_isNavigationStarted)
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
                                    totalStopDuration:
                                        _activeRouteTotalStopDuration,
                                    totalTripDuration:
                                        _activeRouteTotalTripDuration,
                                    needs: _activeRouteNeeds,
                                    notes: _activeRouteNotes,
                                  );
                                },
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isNavigationStarted = true;
                                  });
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
                          ListTile(
                            title: Text(
                              '${l10n.estimatedTravelTime}: ${info.totalDuration}',
                            ),
                          ),
                          ListTile(
                            title: Text(
                              '${l10n.totalTimeAtStops}: ${_formatDuration(totalStopDuration)}',
                            ),
                          ),
                          ListTile(
                            title: Text(
                              '${l10n.totalTripTime}: ${_formatDuration(totalTripDuration)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              '${l10n.totalDistance}: ${info.totalDistance}',
                            ),
                          ),
                          const Divider(),
                          if (consolidatedNeeds.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Text(
                                l10n.needsForTrip,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            ...consolidatedNeeds.map((needItem) {
                              return CheckboxListTile(
                                title: Text(needItem.name),
                                value: needItem.isChecked,
                                onChanged: (bool? newValue) {
                                  if (newValue == null) return;

                                  setModalState(() {
                                    needItem.isChecked = newValue;
                                    _activeRouteNeedsState[needItem.name] =
                                        newValue;
                                  });
                                },
                              );
                            }),
                            const Divider(),
                          ],
                          if (locationsWithInfo.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Text(
                                l10n.notesForTrip,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            ...locationsWithInfo.map((loc) {
                              return ListTile(
                                leading: const Icon(Icons.note_alt_outlined),
                                title: Text(loc.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (loc.notes != null &&
                                        loc.notes!.isNotEmpty)
                                      Text(loc.notes!),
                                    if (loc.estimatedDuration != null &&
                                        loc.estimatedDuration! > 0)
                                      Text(
                                        '${l10n.estimatedDurationLabel}: ${_formatDuration(loc.estimatedDuration!)}',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _launchGoogleMaps(List<TravelLocation> locations) async {
    final l10n = AppLocalizations.of(context)!;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.currentLocationError)));
      return;
    }
    if (locations.isEmpty) return;

    final origin =
        '${_currentPosition!.latitude},${_currentPosition!.longitude}';
    final destination =
        '${locations.last.latitude},${locations.last.longitude}';
    String waypoints = '';

    if (locations.length > 1) {
      waypoints = locations
          .sublist(0, locations.length - 1)
          .map((loc) => '${loc.latitude},${loc.longitude}')
          .join('|');
    }

    String url =
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination';
    if (waypoints.isNotEmpty) {
      url += '&waypoints=$waypoints';
    }
    url += '&travelmode=driving';

    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.launchMapsError)));
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 70,
                child: Image.asset(
                  'assets/icon/icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.email),
                title: const SelectableText("cetin.omer@outlook.com.tr"),
                onTap: () async {
                  final Uri uri =
                      Uri.parse("mailto:cetin.omer@outlook.com.tr");
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const SelectableText("https://github.com/rgt320q"),
                onTap: () async {
                  final Uri uri = Uri.parse("https://github.com/rgt320q");
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    if (widget.isChangingEndPoint) {
      final Set<Marker> endPointMarkers = {};
      if (widget.initialLocation != null) {
        endPointMarkers.add(
          Marker(
            markerId: const MarkerId('initial-endpoint'),
            position: LatLng(
              widget.initialLocation!.latitude,
              widget.initialLocation!.longitude,
            ),
            infoWindow: InfoWindow(title: l10n.currentEndpoint),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueMagenta,
            ),
          ),
        );
      }
      if (_searchResultMarker != null) {
        endPointMarkers.add(_searchResultMarker!);
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.selectEndpointTitle),
          leading: IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.initialLocation?.latitude ??
                      _currentPosition?.latitude ??
                      38.9637,
                  widget.initialLocation?.longitude ??
                      _currentPosition?.longitude ??
                      35.2433,
                ),
                zoom: widget.initialLocation != null ? 15 : 5,
              ),
              markers: endPointMarkers,
              onLongPress: (pos) async {
                final geoName = await _directionsService.getPlaceName(pos) ??
                    l10n.unknownLocation;
                final newEndPoint = TravelLocation(
                  name: geoName,
                  geoName: geoName,
                  latitude: pos.latitude,
                  longitude: pos.longitude,
                  firestoreId: 'end',
                  userId: '',
                );
                Navigator.of(context).pop(newEndPoint);
              },
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
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
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_placePredictions.isNotEmpty)
                    Material(
                      elevation: 4.0,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10),
                      ),
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
                              title: Text(
                                prediction['description'] ??
                                    l10n.unknownLocation,
                              ),
                              onTap: () async {
                                final placeId = prediction['place_id'];
                                if (placeId == null) return;

                                final details = await _directionsService
                                    .getPlaceDetails(placeId);
                                if (details == null || !mounted) return;

                                final location =
                                    details['geometry']?['location'];
                                if (location == null) return;

                                final lat = location['lat'];
                                final lng = location['lng'];
                                final latLng = LatLng(lat, lng);

                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(latLng, 15),
                                );

                                setState(() {
                                  _searchResultMarker = Marker(
                                    markerId:
                                        const MarkerId('searchResult'),
                                    position: latLng,
                                    infoWindow: InfoWindow(
                                      title: prediction['description'],
                                    ),
                                    icon:
                                        BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueAzure,
                                    ),
                                  );
                                  _placePredictions = [];
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
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
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90.0),
          child: FloatingActionButton(
            heroTag: 'myLocationFabEndPoint',
            onPressed: () => _goToCurrentLocation(isInitial: false),
            tooltip: l10n.myLocationTooltip,
            child: const Icon(Icons.my_location),
          ),
        ),
      );
    }

    final initialCamPos = widget.initialLocation != null
        ? CameraPosition(
            target: LatLng(
              widget.initialLocation!.latitude,
              widget.initialLocation!.longitude,
            ),
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
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedRoutesScreen(),
                  ),
                );
                if (!mounted) return;
                if (result is List<TravelLocation> && result.isNotEmpty) {
                  if (result.length >= 2) {
                    _drawRoute(result);
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.locationsNotFoundOrInsufficient),
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.public),
              tooltip: l10n.communityRoutes,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunityRoutesScreen(),
                  ),
                );
                if (result is List<TravelLocation>) {
                  _drawRoute(result);
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
                      builder: (context) => const GroupsScreen()),
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
            ),
          ]
        : [
            if (_activeRouteInfo != null)
              IconButton(
                icon: const Icon(Icons.summarize),
                tooltip: l10n.activeRouteSummary,
                onPressed: () {
                  _showRouteSummary(
                      _activeRouteInfo!, _activeRouteLocations!);
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
        title: GestureDetector(
          onTap: _showAboutDialog,
          child: SizedBox(
            height: 50,
            child: Image.asset(
              'assets/icon/icon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
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
                final geoName =
                    await _directionsService.getPlaceName(pos) ??
                        l10n.unknownLocation;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.confirmEndpointDialogTitle),
                    content:
                        Text(l10n.confirmEndpointDialogContent(geoName)),
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
                    name: l10n.selectedEndpoint,
                    geoName: geoName,
                    latitude: pos.latitude,
                    longitude: pos.longitude,
                    firestoreId: 'end',
                    userId: '',
                  );
                  final result = await Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationSelectionScreen(
                        initialLocations: _locationsForRoute,
                        endLocation: endLocation,
                      ),
                    ),
                  );
                  if (result is List<TravelLocation>) {
                    _drawRoute(result);
                  } else if (result == 'change_end_location') {
                    setState(() {
                      _isSelectingEndpoint = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.selectNewEndpoint)),
                    );
                  }
                }
                setState(() {
                  _isSelectingEndpoint = false;
                });
              } else {
                final geoName = await _directionsService.getPlaceName(pos) ??
                    l10n.unknownLocation;
                _showAddLocationDialog(pos, geoName);
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
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (_placePredictions.isNotEmpty)
                  Material(
                    elevation: 4.0,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
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
                            title: Text(
                              prediction['description'] ??
                                  l10n.unknownLocation,
                            ),
                            onTap: () async {
                              final placeId = prediction['place_id'];
                              if (placeId == null) return;

                              final details = await _directionsService
                                  .getPlaceDetails(placeId);
                              if (details == null || !mounted) return;

                              final location =
                                  details['geometry']?['location'];
                              if (location == null) return;

                              final lat = location['lat'];
                              final lng = location['lng'];
                              final latLng = LatLng(lat, lng);

                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(latLng, 15),
                              );

                              setState(() {
                                _searchResultMarker = Marker(
                                  markerId:
                                      const MarkerId('searchResult'),
                                  position: latLng,
                                  infoWindow: InfoWindow(
                                    title: prediction['description'],
                                  ),
                                  icon:
                                      BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueAzure,
                                  ),
                                );
                                _placePredictions = [];
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
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
              heroTag: 'mapTypeFab', // Unique tag
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
                heroTag: 'resetBearingFab', // Unique tag
                mini: true,
                onPressed: _resetBearing,
                tooltip: l10n.resetBearingTooltip,
                backgroundColor: Colors.white,
                child:
                    const Icon(Icons.explore_outlined, color: Colors.black),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          heroTag: 'myLocationFab', // Unique tag
          onPressed: () => _goToCurrentLocation(isInitial: false),
          tooltip: l10n.myLocationTooltip,
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }

  List<TravelLocation> _optimizeRouteByProximity(
    List<TravelLocation> locations,
    Position startPosition,
  ) {
    if (locations.length < 2) return locations;

    List<TravelLocation> remaining = List.from(locations);
    List<TravelLocation> optimized = [];

    LatLng currentPoint = LatLng(
      startPosition.latitude,
      startPosition.longitude,
    );

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

  void _showRouteCreationDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final userProfile = await _firestoreService.getUserProfile().first;
    TravelLocation? homeEndLocation;

    if (userProfile?.homeLocation != null) {
      homeEndLocation = TravelLocation(
        name: l10n.homeLocation,
        geoName:
            '${userProfile!.homeLocation!.latitude.toStringAsFixed(4)}, ${userProfile.homeLocation!.longitude.toStringAsFixed(4)}',
        latitude: userProfile.homeLocation!.latitude,
        longitude: userProfile.homeLocation!.longitude,
        firestoreId: 'home_end_location',
        userId: userProfile.uid,
      );
    }

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
                MaterialPageRoute(
                  builder: (context) =>
                      const GroupsScreen(isForSelection: true),
                ),
              );

              if (!mounted || result == null) return;

              final selectedGroupId = result['id'];

              if (selectedGroupId != null) {
                final locations =
                    await _firestoreService.getLocationsForGroup(
                  selectedGroupId,
                );
                if (locations.isNotEmpty) {
                  if (_currentPosition == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.currentLocationError)),
                    );
                    return;
                  }
                  final optimizedLocations = _optimizeRouteByProximity(
                    locations,
                    _currentPosition!,
                  );
                  final defaultEndLocationGeoName =
                      await _directionsService.getPlaceName(
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                          ) ??
                          l10n.unknownLocation;
                  final defaultEndLocation = TravelLocation(
                    name: l10n.endPoint,
                    geoName: defaultEndLocationGeoName,
                    description: l10n.routeEnd,
                    latitude: _currentPosition!.latitude,
                    longitude: _currentPosition!.longitude,
                    firestoreId: 'end',
                    userId: '',
                  );

                  final result = await Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationSelectionScreen(
                        initialLocations: optimizedLocations,
                        endLocation: homeEndLocation ?? defaultEndLocation,
                      ),
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
              final List<TravelLocation>? selectedLocations =
                  await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ManageLocationsScreen(isForSelection: true),
                ),
              );
              if (selectedLocations != null && selectedLocations.isNotEmpty) {
                if (_currentPosition == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.currentLocationError)),
                  );
                  return;
                }
                final optimizedLocations = _optimizeRouteByProximity(
                  selectedLocations,
                  _currentPosition!,
                );
                final defaultEndLocationGeoName =
                    await _directionsService.getPlaceName(
                          LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                        ) ??
                        l10n.unknownLocation;
                final defaultEndLocation = TravelLocation(
                  name: l10n.endPoint,
                  geoName: defaultEndLocationGeoName,
                  description: l10n.routeEnd,
                  latitude: _currentPosition!.latitude,
                  longitude: _currentPosition!.longitude,
                  firestoreId: 'end',
                  userId: '',
                );

                final result = await Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationSelectionScreen(
                      initialLocations: optimizedLocations,
                      endLocation: homeEndLocation ?? defaultEndLocation,
                    ),
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
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddLocationDialog(LatLng pos, String geoName) {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: geoName);
    final descriptionController = TextEditingController();
    final notesController = TextEditingController();
    final needsController = TextEditingController();
    final durationController = TextEditingController();
    String? selectedGroupId;
    List<LocationGroup> dialogGroups = List.from(_allGroups);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.addLocationDialogTitle),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.googleMapsNameLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(geoName),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: l10n.customLocationNameLabel,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.locationNameEmptyError;
                          }
                          final invalidChars = RegExp(r'[<>]');
                          if (invalidChars.hasMatch(value)) {
                            return l10n.locationNameInvalidCharsError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: l10n.descriptionLabel,
                        ),
                        validator: (value) {
                          if (value == null) return null;
                          final invalidChars = RegExp(r'[<>]');
                          if (invalidChars.hasMatch(value)) {
                            return l10n.descriptionInvalidCharsError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: l10n.notesLabel,
                        ),
                        validator: (value) {
                          if (value == null) return null;
                          final invalidChars = RegExp(r'[<>]');
                          if (invalidChars.hasMatch(value)) {
                            return l10n.notesInvalidCharsError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: needsController,
                        decoration: InputDecoration(
                          labelText: l10n.needsLabel,
                          hintText: l10n.needsHint,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: l10n.estimatedDurationLabel,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedGroupId,
                        decoration: InputDecoration(
                          labelText: l10n.groupLabel,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(l10n.groupNone),
                          ),
                          ...dialogGroups.map((group) {
                            return DropdownMenuItem<String>(
                              value: group.firestoreId,
                              child: Text(group.name),
                            );
                          }),
                          DropdownMenuItem<String>(
                            value: 'add_new_group',
                            child: Text(l10n.addNewGroup),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == 'add_new_group') {
                            final newGroup = await _showAddNewGroupDialog(context);
                            if (newGroup != null) {
                              setState(() {
                                dialogGroups.add(newGroup);
                                _allGroups.add(newGroup);
                                selectedGroupId = newGroup.firestoreId;
                              });
                            }
                          } else {
                            setState(() {
                              selectedGroupId = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      final needsList = needsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .map((name) => {'name': name, 'checked': false})
                          .toList();

                      final newLocation = TravelLocation(
                        name: nameController.text.trim(),
                        geoName: geoName,
                        description: descriptionController.text.trim(),
                        latitude: pos.latitude,
                        longitude: pos.longitude,
                        notes: notesController.text.trim(),
                        needsList: needsList,
                        estimatedDuration:
                            int.tryParse(durationController.text),
                        groupId: selectedGroupId,
                        userId: user.uid,
                        createdAt: DateTime.now(),
                      );

                      await _firestoreService.addLocation(newLocation);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(l10n.add),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != null &&
        widget.initialLocation != oldWidget.initialLocation) {
      _goToInitialLocation();
    }
  }
}