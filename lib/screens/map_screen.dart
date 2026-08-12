import 'dart:async';
import 'dart:math' show min, max;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/location_group.dart';
import 'package:tripbook/models/reached_location_log.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/providers/locale_provider.dart';
import 'package:tripbook/screens/community_routes_screen.dart';
import 'package:tripbook/screens/groups_screen.dart';
import 'package:tripbook/screens/location_selection_screen.dart';
import 'package:tripbook/screens/manage_locations_screen.dart';
import 'package:tripbook/screens/profile_screen.dart';
import 'package:tripbook/screens/reached_locations_screen.dart';
import 'package:tripbook/screens/saved_routes_screen.dart';
import 'package:tripbook/services/connectivity_service.dart';
import 'package:tripbook/services/database_service.dart';
import 'package:tripbook/services/directions_service.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/services/notification_service.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:tripbook/utils/brand_colors.dart';
import 'package:tripbook/utils/marker_utils.dart' as marker_utils;
import 'package:tripbook/widgets/duration_selector.dart';
import 'package:tripbook/widgets/loading_overlay.dart';
import 'package:tripbook/widgets/long_press_indicator.dart';
import 'package:tripbook/widgets/multi_group_selector.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _MapScreenState extends State<MapScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _showApiKeyWarning = false;
  bool _isMapInitialized = false;
  bool _isAnyModalOpen = false;

  late AnimationController _longPressController;
  Offset? _longPressPosition;
  bool _isLongPressing = false;
  DateTime? _suppressMarkerTapUntil;

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
  bool _isMapRotated = false;

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
  bool _isNeedsListConsolidated = false;
  AppTravelMode _selectedTravelMode = AppTravelMode.driving;
  int _lastNotifiedStageIndex = -1;
  // --------------------------

  final Map<String, bool> _activeRouteNeedsState = {};
  final Set<String> _visitedWaypoints = {};
  final Set<String> _triggeredWikipediaNotifications = {};
  final Map<String, Timer> _waypointTimers = {};
  Timer? _mapUpdateDebounce;

  // Icon cache for performance
  BitmapDescriptor? _currentLocationIcon;
  BitmapDescriptor? _homeLocationIcon;
  final Map<String, BitmapDescriptor> _markerIconCache = {};

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
    if (kIsWeb) {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _showApiKeyWarning = true;
        });
      }
    }
    WidgetsBinding.instance.addObserver(this);

    _longPressController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _onLongPressCompleted();
          }
        });

    _initializeScreen();
    _searchController.addListener(_onSearchChanged);
  }

  Future<LocationGroup?> _showAddNewGroupDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final groupNameController = TextEditingController();
    Color selectedColor = _groupColors.first;
    final formKey = GlobalKey<FormState>();

    setState(() => _isAnyModalOpen = true);
    final result = await showDialog<LocationGroup>(
      context: context,
      builder: (dialogContext) {
        return PointerInterceptor(
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                scrollable: true,
                title: Text(l10n.newGroup),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: groupNameController,
                        decoration: InputDecoration(labelText: l10n.groupName),
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
                          // ignore: deprecated_member_use
                          color: selectedColor.value,
                          createdAt: DateTime.now(),
                          userId: FirebaseAuth.instance.currentUser!.uid,
                        );
                        final docRef = await _firestoreService.addGroup(
                          newGroup,
                        );
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
          ),
        );
      },
    ).whenComplete(() => setState(() => _isAnyModalOpen = false));
    return result;
  }

  Future<void> _initializeScreen() async {
    try {
      // Profil verisini 5 saniyeden fazla bekleme (Hanging koruması)
      final profile = await _firestoreService.getUserProfile().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );

      if (mounted && profile != null) {
        final langCode = profile.languageCode ?? 'tr';
        Provider.of<LocaleProvider>(
          context,
          listen: false,
        ).setLocale(Locale(langCode));
      }
    } catch (e) {
      if (kDebugMode) print('Profile load error: $e');
    }

    try {
      // Konum tespitini 10 saniye ile sınırla (Web'de bazen çok uzun sürüyor)
      await _determinePosition().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) print('Position determination timed out');
        },
      );
    } catch (e) {
      if (kDebugMode) print('Initial position error: $e');
    }

    _setupDataSync();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _mapController != null) {
      // Uygulama foreground'a döndüğünde haritayı refresh et
      _refreshMapAfterResume();
    }
  }

  Future<void> _refreshMapAfterResume() async {
    // Kısa bir delay ile haritayı refresh et
    await Future.delayed(const Duration(milliseconds: 300));
    if (_mapController != null && mounted) {
      try {
        // Mevcut kamera pozisyonunu al ve yeniden set et
        if (_cameraPosition != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(_cameraPosition!),
          );
        } else {
          // Eğer kamera pozisyonu yoksa hafif bir zoom yaparak refresh et
          final currentPos = await _mapController!.getLatLng(
            const ScreenCoordinate(x: 0, y: 0),
          );
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              currentPos,
              await _mapController!.getZoomLevel(),
            ),
          );
        }

        // Markerları ve polylineları güncelle
        _updateMapElements();
      } catch (e) {
        // Hata durumunda log
        if (kDebugMode) {
          print('Map refresh error after resume: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _longPressController.dispose();
    WidgetsBinding.instance.removeObserver(this);

    // Map controller referansını temizle (widget kendi dispose'unu yapar)
    _mapController = null;
    _isMapInitialized = false;

    _locationsSubscription?.cancel();
    _groupsSubscription?.cancel();
    _profileSubscription?.cancel();
    _positionStreamSubscription?.cancel();

    // Safely dispose all timers
    for (final timer in _waypointTimers.values) {
      timer.cancel();
    }
    _waypointTimers.clear();

    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _mapUpdateDebounce?.cancel();

    super.dispose();
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

  void _toggleMapType() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    setState(() => _isAnyModalOpen = true);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.mapTypeTooltip,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _mapTypeOption(sheetContext, MapType.normal, l10n.mapTypeNormal),
              _mapTypeOption(
                sheetContext,
                MapType.satellite,
                l10n.mapTypeSatellite,
              ),
              _mapTypeOption(
                sheetContext,
                MapType.terrain,
                l10n.mapTypeTerrain,
              ),
              _mapTypeOption(sheetContext, MapType.hybrid, l10n.mapTypeHybrid),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _isAnyModalOpen = false);
    });
  }

  Widget _mapTypeOption(BuildContext sheetContext, MapType type, String label) {
    final selected = _currentMapType == type;
    return ListTile(
      leading: _MapTypePreview(type: type),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: Theme.of(sheetContext).primaryColor)
          : null,
      onTap: () {
        Navigator.of(sheetContext).pop();
        if (selected) return;
        setState(() => _currentMapType = type);
      },
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
        ),
      ),
    );
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
      // Log error for debugging
      if (kDebugMode) {
        print('Location error: $e');
      }

      // Show user-friendly error message
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.currentLocationError),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: l10n.save, // Retry yerine save kullanıyoruz
              onPressed: () => _determinePosition(),
            ),
          ),
        );
      }
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
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            if (mounted) {
              setState(() {
                _currentPosition = position;
              });
              // Debounced map update to reduce performance impact
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
      _isNeedsListConsolidated = false; // Reset the consolidation state
    });
    _startLiveLocationTracking();

    // Efficiently cancel and clear all timers
    for (final timer in _waypointTimers.values) {
      timer.cancel();
    }
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
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
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
          },
        );
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

  void _checkAllWaypointsProximity(Position userPosition) {
    final l10n = AppLocalizations.of(context)!;
    if (_activeRouteLocations == null ||
        FirebaseAuth.instance.currentUser == null ||
        _isRouteCompleted) {
      return;
    }

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
          _checkStageTransition(
            location,
            _activeRouteLocations!.indexOf(location),
          );
        }

        final allWaypointIds = _activeRouteLocations!
            .map((loc) => loc.firestoreId!)
            .toSet();
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
        if (mounted && _allLocations != locations) {
          setState(() => _allLocations = locations);
          _updateMapElements();
        }
      },
      onError: (error) {
        // Log error for debugging
        if (kDebugMode) {
          print('Locations stream error: $error');
        }

        // Fall back to local database
        _loadMarkersFromLocalDb();

        // Show error to user
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.connectionLost),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
    );

    _groupsSubscription = _firestoreService.getGroups().listen(
      (groups) {
        if (mounted && _allGroups != groups) {
          setState(() => _allGroups = groups);
          _updateMapElements();
        }
      },
      onError: (error) {
        // Log error for debugging
        if (kDebugMode) {
          print('Groups stream error: $error');
        }

        // Show error to user
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.groupsSyncFailed),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
    );

    _profileSubscription = _firestoreService.getUserProfile().listen(
      (profile) {
        if (mounted && profile != null) {
          setState(() {
            _homeLocation = profile.homeLocation;
          });
          _updateMapElements();
        }
      },
      onError: (error) {
        // Log error for debugging
        if (kDebugMode) {
          print('Profile stream error: $error');
        }

        // Show error to user
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profileSyncFailed),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
    );
  }

  void _scheduleMapUpdate() {
    _mapUpdateDebounce?.cancel();
    _mapUpdateDebounce = Timer(const Duration(milliseconds: 100), () {
      _updateMapElementsInternal();
    });
  }

  Future<void> _updateMapElements() async {
    _scheduleMapUpdate();
  }

  List<LatLng> _decimatePoints(List<LatLng> points, {int maxPoints = 500}) {
    if (points.length <= maxPoints) return points;
    final step = points.length / maxPoints;
    final result = <LatLng>[];
    for (int i = 0; i < maxPoints; i++) {
      result.add(points[(i * step).floor()]);
    }
    result.add(points.last);
    return result;
  }

  Future<void> _updateMapElementsInternal() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final groupsMap = {for (var group in _allGroups) group.firestoreId!: group};
    final Set<Marker> newMarkers = {};

    if (_currentPosition != null) {
      _currentLocationIcon ??= await marker_utils
          .getCurrentLocationMarkerIcon();
      newMarkers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: InfoWindow(title: l10n.myLocationTooltip),
          icon: _currentLocationIcon!,
          // ignore: deprecated_member_use
          zIndex: 2,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    if (_homeLocation != null) {
      _homeLocationIcon ??= await marker_utils.getHomeMarkerIcon();
      newMarkers.add(
        Marker(
          markerId: const MarkerId('homeLocation'),
          position: LatLng(_homeLocation!.latitude, _homeLocation!.longitude),
          infoWindow: InfoWindow(title: l10n.homeLocation),
          icon: _homeLocationIcon!,
          // ignore: deprecated_member_use
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
      final isVisited =
          _activeRouteLocations != null &&
          _visitedWaypoints.contains(loc.firestoreId);
      final isEndpoint = loc.firestoreId == 'end';

      Color color;
      if (isEndpoint) {
        color = Colors.purpleAccent;
      } else if (isVisited) {
        color = Colors.green;
      } else if (loc.groupIds.isEmpty) {
        color = Colors.grey;
      } else {
        final group = groupsMap[loc.groupIds.first];
        color = group?.color != null ? Color(group!.color!) : Colors.red;
      }

      // Create cache key for icon
      final iconKey = '${color.value}_${isEndpoint ? 'endpoint' : 'normal'}';

      BitmapDescriptor icon;
      if (_markerIconCache.containsKey(iconKey)) {
        icon = _markerIconCache[iconKey]!;
      } else {
        icon = await marker_utils.getCustomMarkerIcon(
          color,
          isEndpoint: isEndpoint,
        );
        _markerIconCache[iconKey] = icon;
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(loc.firestoreId ?? loc.hashCode.toString()),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(title: loc.name, snippet: loc.description),
          icon: icon,
          // ignore: deprecated_member_use
          zIndex: isEndpoint ? 4 : (isVisited ? 1 : 2),
          onTap: () {
            if (_isSuppressedMarkerTap()) return;
            if (loc.firestoreId != 'end') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageLocationsScreen(
                    initiallyExpandedLocationId: loc.firestoreId,
                    isReadOnly: _activeRouteLocations != null,
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
          name: l10n.startLabel,
          geoName: l10n.startLabel,
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
          // Decimate the path so long trips don't rebuild a huge polyline
          // (or blow up the native map) on every position update.
          points: _decimatePoints(_userPathHistory),
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

    await ConnectivityService().executeWithConnectivityCheck(context, () async {
      if (_currentPosition == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.currentLocationError)));
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      _activeRouteNeedsState.clear();
      _visitedWaypoints.clear();
      _triggeredWikipediaNotifications.clear();
      _isNeedsListConsolidated = false; // Reset for new route
      _lastNotifiedStageIndex = -1; // Reset staged navigation

      final userLocation = TravelLocation(
        name: l10n.currentLocation,
        geoName: l10n.currentLocation,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.minOneLocationError)));
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
        groupIds: finalDestination.groupIds,
        notes: finalDestination.notes,
        needsList: finalDestination.needsList,
        estimatedDuration: finalDestination.estimatedDuration,
        createdAt: finalDestination.createdAt,
        isImported: finalDestination.isImported,
        userId: '',
      );

      var routeLocationsForApi = [userLocation, ...waypoints, finalDestination];
      DirectionsInfo? directionsInfo;

      if (mounted) LoadingOverlay.show(context);

      try {
        directionsInfo = await _directionsService.getHybridDirections(
          routeLocationsForApi,
          mode: _selectedTravelMode,
        );
      } catch (e) {
        if (kDebugMode) print('Route calculation error: $e');
      } finally {
        if (mounted) LoadingOverlay.hide(context);
      }

      if (directionsInfo == null && kIsWeb) {
        // On web, if Directions API is skipped, create a dummy DirectionsInfo
        // to allow saving the route with partial data.
        double minLat = routeLocationsForApi.map((e) => e.latitude).reduce(min);
        double maxLat = routeLocationsForApi.map((e) => e.latitude).reduce(max);
        double minLng = routeLocationsForApi
            .map((e) => e.longitude)
            .reduce(min);
        double maxLng = routeLocationsForApi
            .map((e) => e.longitude)
            .reduce(max);

        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
        directionsInfo = DirectionsInfo(
          bounds: bounds,
          legsPoints: [], // No polylines for web
          totalDistance: l10n.notAvailable,
          totalDuration: l10n.notAvailable,
          duration: Duration.zero,
          distanceValue: 0.0,
          containsStraightLines: true,
          legsIsStraight: List.filled(routeLocationsForApi.length - 1, true),
        );
      }

      if (directionsInfo != null) {
        final activeRouteLocations = [...waypoints, finalDestination];
        setState(() {
          _activeRouteInfo = directionsInfo;
          _activeRouteLocations = activeRouteLocations;
        });

        _updateMapElements();

        // Safely animate camera to bounds
        if (!kIsWeb && _mapController != null) {
          try {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(directionsInfo.bounds, 50),
            );
          } catch (e) {
            if (kDebugMode) print('Camera animation error: $e');
            // Fallback to current position if bounds fail
            if (_currentPosition != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                ),
              );
            }
          }
        }

        _showRouteSummary(directionsInfo, activeRouteLocations);
        _startRouteTracking();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.drawRouteError)));
        }
      }
    });
  }

  String _formatDuration(int totalMinutes) {
    final l10n = AppLocalizations.of(context)!;
    if (totalMinutes < 0) return '0 ${l10n.minutes}';
    if (totalMinutes < 60) {
      return '$totalMinutes ${l10n.minutes}';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '$hours ${l10n.hours}';
    }
    return '$hours ${l10n.hours} $minutes ${l10n.minutes}';
  }

  String _formatElapsedDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? color : colorScheme.outlineVariant,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? color : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
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
    setState(() => _isAnyModalOpen = true);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
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
                if (conflictingRoute.firestoreId != null && mounted) {
                  shouldProceed =
                      await showDialog<bool>(
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
                  locationIds: locations
                      .where(
                        (l) =>
                            l.firestoreId != null && l.firestoreId!.isNotEmpty,
                      )
                      .map((l) => l.firestoreId!)
                      .toList(),
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

                try {
                  if (conflictingRoute.firestoreId != null) {
                    await _firestoreService.updateRoute(
                      conflictingRoute.firestoreId!,
                      newRoute,
                    );
                  } else {
                    await _firestoreService.addRoute(newRoute);
                  }

                  if (!mounted) return;

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.routeSavedSuccess(routeName)),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  _clearRoute();
                } catch (e) {
                  // Log error for debugging
                  if (kDebugMode) {
                    print('Route save error: $e');
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.failedToSaveRoute),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        action: SnackBarAction(
                          label: l10n.save,
                          onPressed: () {
                            // Re-show the save dialog
                            _showSaveRouteDialog(
                              _activeRouteInfo!,
                              _activeRouteLocations!,
                              actualDuration: actualDuration,
                              actualDistance: actualDistance,
                              totalStopDuration: totalStopDuration,
                              totalTripDuration: totalTripDuration,
                              needs: needs,
                              notes: notes,
                            );
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    ).whenComplete(() => setState(() => _isAnyModalOpen = false));
  }

  void _showRouteCompletionSummary(Duration elapsedDuration) {
    final l10n = AppLocalizations.of(context)!;
    final actualDistanceKm = _actualDistanceMeters / 1000.0;
    final actualDistanceString = l10n.distanceKm(
      actualDistanceKm.toStringAsFixed(1),
    );

    setState(() => _isAnyModalOpen = true);
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
    ).whenComplete(() => setState(() => _isAnyModalOpen = false));
  }

  void _showRouteSummary(DirectionsInfo info, List<TravelLocation> locations) {
    final locationsWithInfo = locations
        .where(
          (loc) =>
              (loc.notes != null && loc.notes!.isNotEmpty) ||
              (loc.estimatedDuration != null && loc.estimatedDuration! > 0),
        )
        .toList();

    final totalStopDuration = locations.fold<int>(
      0,
      (total, loc) => total + (loc.estimatedDuration ?? 0),
    );

    final travelDuration = info.duration.inMinutes;
    final totalTripDuration = travelDuration + totalStopDuration;

    _activeRouteTotalStopDuration = _formatDuration(totalStopDuration);
    _activeRouteTotalTripDuration = _formatDuration(totalTripDuration);

    // Consolidate needs for saving
    final groupedNeedsForSaving = <String>{};
    String normalize(String name) {
      if (name.isEmpty) return '';
      final trimmed = name.trim();
      if (trimmed.isEmpty) return '';
      return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
    }

    for (var location in locations) {
      if (location.needsList != null) {
        for (var need in location.needsList!) {
          final normalizedName = normalize(need['name'] as String? ?? '');
          if (normalizedName.isNotEmpty) {
            groupedNeedsForSaving.add(normalizedName);
          }
        }
      }
    }
    _activeRouteNeeds = groupedNeedsForSaving.toList();

    _activeRouteNotes = locations
        .where((loc) => loc.notes != null && loc.notes!.isNotEmpty)
        .map((loc) => {'locationName': loc.name, 'note': loc.notes!})
        .toList();

    setState(() => _isAnyModalOpen = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final l10n = AppLocalizations.of(modalContext)!;
        final colorScheme = Theme.of(modalContext).colorScheme;
        return PointerInterceptor(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: kIsWeb ? 600 : double.infinity,
                maxHeight: MediaQuery.of(modalContext).size.height * 0.85,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setModalState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                brandButtonBlue(Theme.of(context).brightness),
                                brandGradientEndBlue(
                                  Theme.of(context).brightness,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Icon and Action Buttons
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.route_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!_isNavigationStarted) ...[
                                    // Action buttons wrapped in a Row to prevent vertical overlap
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Travel Mode Selector
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: PopupMenuButton<AppTravelMode>(
                                            icon: Icon(
                                              _selectedTravelMode ==
                                                      AppTravelMode.driving
                                                  ? Icons.drive_eta
                                                  : _selectedTravelMode ==
                                                        AppTravelMode.walking
                                                  ? Icons.directions_walk
                                                  : Icons.directions_bus,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            tooltip: l10n.change,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 40,
                                            ),
                                            onSelected: (AppTravelMode mode) {
                                              setState(() {
                                                _selectedTravelMode = mode;
                                              });
                                              Navigator.pop(context);
                                              _drawRoute(locations);
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: AppTravelMode.driving,
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.drive_eta,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(l10n.modeDriving),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: AppTravelMode.walking,
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.directions_walk,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(l10n.modeWalking),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.bookmark_outline,
                                              color: Colors.white,
                                              size: 20,
                                            ),
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
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent[700],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () {
                                                setState(() {
                                                  _isNavigationStarted = true;
                                                });
                                                Navigator.pop(context);
                                                _launchGoogleMaps(locations);
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.navigation_rounded,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      l10n.startNavigation,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Middle Area: The "Hybrid Route" text in its own thin row
                              if (info.containsStraightLines)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      l10n.hybridRouteTitle(
                                        _selectedTravelMode ==
                                                AppTravelMode.driving
                                            ? l10n.modeDriving
                                            : l10n.modeWalking,
                                      ),
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              // Main Title and Chips Area
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.routeSummaryTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (info.containsStraightLines) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[400]!
                                                .withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.auto_fix_high,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                l10n.noRoadAccessWarning,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '${locations.length} ${l10n.locationsLabel}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Content
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Route Stats Cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.access_time,
                                        label: l10n.estimatedTravelTime,
                                        value: _formatDuration(
                                          info.duration.inMinutes,
                                        ),
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.straighten,
                                        label: l10n.totalDistance,
                                        value: info.totalDistance,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.pause_circle,
                                        label: l10n.totalTimeAtStops,
                                        value: _formatDuration(
                                          totalStopDuration,
                                        ),
                                        color: Colors.purple,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: info.containsStraightLines
                                            ? Icons.priority_high
                                            : Icons.schedule,
                                        label: l10n.totalTripTime,
                                        value: _formatDuration(
                                          totalTripDuration,
                                        ),
                                        color: info.containsStraightLines
                                            ? Colors.orange
                                            : Colors.green,
                                        isHighlighted: true,
                                      ),
                                    ),
                                  ],
                                ),

                                if (info.containsStraightLines) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.orange.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            l10n.approximateDurationWarning,
                                            style: TextStyle(
                                              color: Colors.orange[900],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // Needs Section
                                Builder(
                                  builder: (context) {
                                    final allRawNeeds = locations
                                        .expand((loc) => loc.needsList ?? [])
                                        .toList();

                                    if (allRawNeeds.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blue[200]!,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.shopping_cart,
                                                  color: Colors.blue[600],
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    l10n.needsForTrip,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.blue[800],
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      onTap: () {
                                                        setModalState(() {
                                                          _activeRouteNeedsState
                                                              .clear();
                                                          _isNeedsListConsolidated =
                                                              !_isNeedsListConsolidated;
                                                        });
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6,
                                                            ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              _isNeedsListConsolidated
                                                                  ? Icons
                                                                        .expand_more
                                                                  : Icons
                                                                        .compress,
                                                              size: 16,
                                                              color: Colors
                                                                  .blue[700],
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              _isNeedsListConsolidated
                                                                  ? l10n.expand
                                                                  : l10n.consolidate,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .blue[700],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            if (_isNeedsListConsolidated)
                                              ..._buildConsolidatedNeeds(
                                                locations,
                                                setModalState,
                                              )
                                            else
                                              ..._buildRawNeeds(
                                                locations,
                                                setModalState,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Notes Section
                                if (locationsWithInfo.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.amber[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.note_alt,
                                              color: Colors.amber[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.notesForTrip,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.amber[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ...locationsWithInfo.map((loc) {
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.amber[200]!,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      color: Colors.amber[700],
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        loc.name,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (loc.notes != null &&
                                                    loc.notes!.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    loc.notes!,
                                                    style: TextStyle(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                                if (loc.estimatedDuration !=
                                                        null &&
                                                    loc.estimatedDuration! >
                                                        0) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.schedule,
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${l10n.estimatedDurationLabel}: ${_formatDuration(loc.estimatedDuration!)}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color: colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() => setState(() => _isAnyModalOpen = false));
  }

  List<Widget> _buildRawNeeds(
    List<TravelLocation> locations,
    StateSetter setModalState,
  ) {
    final List<Widget> rawNeedsWidgets = [];
    int rawIndex = 0;

    for (var location in locations) {
      if (location.needsList != null) {
        for (var need in location.needsList!) {
          final String rawNeedName = need['name'] as String? ?? '';
          final String uniqueKey = 'raw_$rawIndex';

          rawNeedsWidgets.add(
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(rawNeedName),
              value: _activeRouteNeedsState[uniqueKey] ?? false,
              onChanged: (bool? newValue) {
                setModalState(() {
                  _activeRouteNeedsState[uniqueKey] = newValue ?? false;
                });
              },
            ),
          );
          rawIndex++;
        }
      }
    }
    return rawNeedsWidgets;
  }

  List<Widget> _buildConsolidatedNeeds(
    List<TravelLocation> locations,
    StateSetter setModalState,
  ) {
    String normalize(String name) {
      if (name.isEmpty) return '';
      final trimmed = name.trim();
      if (trimmed.isEmpty) return '';
      return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
    }

    final groupedNeeds = <String, List<Map<String, dynamic>>>{};

    for (var location in locations) {
      if (location.needsList != null) {
        for (var need in location.needsList!) {
          final normalizedName = normalize(need['name'] as String? ?? '');
          if (normalizedName.isNotEmpty) {
            (groupedNeeds[normalizedName] ??= []).add(need);
          }
        }
      }
    }

    if (groupedNeeds.isEmpty) {
      return [const SizedBox.shrink()];
    }

    final sortedKeys = groupedNeeds.keys.toList()..sort();

    return sortedKeys.map((key) {
      final needs = groupedNeeds[key]!;
      final bool isChecked = needs.every(
        (n) => _activeRouteNeedsState[normalize(n['name'] ?? '')] == true,
      );

      return CheckboxListTile(
        title: Text(key),
        value: isChecked,
        onChanged: (bool? newValue) {
          if (newValue == null) return;
          setModalState(() {
            for (var need in needs) {
              _activeRouteNeedsState[normalize(need['name'] ?? '')] = newValue;
            }
          });
        },
      );
    }).toList();
  }

  Future<void> _launchGoogleMaps(List<TravelLocation> locations) async {
    final l10n = AppLocalizations.of(context)!;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.currentLocationError)));
      return;
    }
    if (locations.isEmpty || _activeRouteInfo == null) return;

    // Find the current stage (the next sequence of driveable legs)
    final legsIsStraight = _activeRouteInfo!.legsIsStraight;

    // Waypoints are locations[0...N-1].
    // leg[0] is currentPosition -> locations[0]
    // leg[i] is locations[i-1] -> locations[i]

    int firstUnvisitedIndex = -1;
    for (int i = 0; i < locations.length; i++) {
      if (!_visitedWaypoints.contains(locations[i].firestoreId)) {
        firstUnvisitedIndex = i;
        break;
      }
    }

    if (firstUnvisitedIndex == -1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.routeCompleted)));
      return;
    }

    // Check if the current leg is straight
    if (legsIsStraight.isNotEmpty &&
        firstUnvisitedIndex < legsIsStraight.length &&
        legsIsStraight[firstUnvisitedIndex]) {
      _showStageInfoDialog(
        title: l10n.navigationNotAvailableTitle,
        message: l10n.navigationNotAvailableMessage,
      );
      return;
    }

    // Construct the stage: from current position to the last driveable waypoint before a straight leg
    List<TravelLocation> stageWaypoints = [];
    for (int i = firstUnvisitedIndex; i < locations.length; i++) {
      if (i < legsIsStraight.length && legsIsStraight[i]) {
        break; // Stop before the straight leg
      }
      stageWaypoints.add(locations[i]);
    }

    if (stageWaypoints.isEmpty) return;

    final origin =
        '${_currentPosition!.latitude},${_currentPosition!.longitude}';
    final destination =
        '${stageWaypoints.last.latitude},${stageWaypoints.last.longitude}';
    String waypointsParam = '';

    if (stageWaypoints.length > 1) {
      waypointsParam = stageWaypoints
          .sublist(0, stageWaypoints.length - 1)
          .map((loc) => '${loc.latitude},${loc.longitude}')
          .join('|');
    }

    String url =
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination';
    if (waypointsParam.isNotEmpty) {
      url += '&waypoints=$waypointsParam';
    }
    url += '&travelmode=${_selectedTravelMode.name}';

    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.launchMapsError)));
      }
    }
  }

  void _showStageInfoDialog({required String title, required String message}) {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isAnyModalOpen = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    ).whenComplete(() => setState(() => _isAnyModalOpen = false));
  }

  void _checkStageTransition(TravelLocation reachedLocation, int reachedIndex) {
    if (_activeRouteInfo == null || _activeRouteLocations == null) return;
    final l10n = AppLocalizations.of(context)!;
    final legsIsStraight = _activeRouteInfo!.legsIsStraight;
    final locations = _activeRouteLocations!;

    // Case A: Just reached a point that is the entry to a straight-line transition
    // i.e., leg[reachedIndex + 1] is straight
    if (reachedIndex + 1 < legsIsStraight.length &&
        legsIsStraight[reachedIndex + 1]) {
      if (_lastNotifiedStageIndex != reachedIndex) {
        _lastNotifiedStageIndex = reachedIndex;
        _notificationService.showNotification(
          l10n.reachedCheckpoint,
          l10n.reachedCheckpointMessage(reachedLocation.name),
        );
        _showStageInfoDialog(
          title: l10n.stageCompletedTitle,
          message: l10n.stageCompletedMessage(reachedLocation.name),
        );
      }
    }

    // Case B: Just reached a point that is the end of a straight-line transition
    // i.e., leg[reachedIndex] was straight and leg[reachedIndex + 1] is road (or it's the last point)
    // Actually, if we just reached it, and it was a straight leg, we might want to start Google Maps for the NEXT segment.
    if (reachedIndex < legsIsStraight.length && legsIsStraight[reachedIndex]) {
      // We just finished a straight leg. If there's a road leg coming up, prompt for navigation.
      if (reachedIndex + 1 < legsIsStraight.length &&
          !legsIsStraight[reachedIndex + 1]) {
        _showNextStagePrompt();
      } else if (reachedIndex + 1 == locations.length) {
        // reached the very last point via straight leg, route completion handled elsewhere
      }
    }
  }

  void _showNextStagePrompt() {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isAnyModalOpen = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.nextStageReadyTitle),
        content: Text(l10n.nextStageReadyMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.later),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchGoogleMaps(_activeRouteLocations!);
            },
            child: Text(l10n.startNavigation),
          ),
        ],
      ),
    ).whenComplete(() => setState(() => _isAnyModalOpen = false));
  }

  void _onLongPressCompleted() async {
    if (_longPressPosition == null ||
        _mapController == null ||
        _activeRouteLocations != null)
      return;

    final Offset pos = _longPressPosition!;
    // On device platform views (Android/iOS) the map coordinates are in
    // physical pixels; convert the Flutter logical position accordingly.
    final double scale = kIsWeb ? 1.0 : MediaQuery.of(context).devicePixelRatio;

    final connectivityResult = await ConnectivityService().checkConnection();
    if (!connectivityResult && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noInternetForOperation),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLongPressing = false;
        _longPressPosition = null;
      });
      _longPressController.reset();
      return;
    }

    setState(() {
      _isLongPressing = false;
      _longPressPosition = null;
    });
    _longPressController.reset();

    // Ekran koordinatını LatLng'e çevir
    final LatLng latLng = await _mapController!.getLatLng(
      ScreenCoordinate(
        x: (pos.dx * scale).round(),
        y: (pos.dy * scale).round(),
      ),
    );

    if (widget.isChangingEndPoint) {
      if (mounted) LoadingOverlay.show(context);
      final geoName =
          await _directionsService.getPlaceName(latLng) ??
          AppLocalizations.of(context)!.unknownLocation;
      if (mounted) {
        LoadingOverlay.hide(context);
        final newEndPoint = TravelLocation(
          name: geoName,
          geoName: geoName,
          latitude: latLng.latitude,
          longitude: latLng.longitude,
          firestoreId: 'end',
          userId: '',
        );
        Navigator.of(context).pop(newEndPoint);
      }
      return;
    }

    if (_isSelectingEndpoint) {
      _handleEndpointSelection(latLng);
    } else {
      final savedLocation = await _markerAtScreenPosition(pos);
      if (savedLocation != null) {
        _openLocationDetails(savedLocation);
        return;
      }

      if (mounted) LoadingOverlay.show(context);
      final geoName =
          await _directionsService.getPlaceName(latLng) ??
          AppLocalizations.of(context)!.unknownLocation;
      if (mounted) {
        LoadingOverlay.hide(context);
        _showAddLocationDialog(latLng, geoName);
      }
    }
  }

  Future<TravelLocation?> _markerAtScreenPosition(Offset pos) async {
    const double hitRadiusPx = 56;
    final double scale = kIsWeb ? 1.0 : MediaQuery.of(context).devicePixelRatio;
    TravelLocation? nearest;
    double nearestDistance = double.infinity;
    for (final loc in _allLocations) {
      final screen = await _mapController!.getScreenCoordinate(
        LatLng(loc.latitude, loc.longitude),
      );
      final markerLogical = Offset(screen.x / scale, screen.y / scale);
      final distance = (markerLogical - pos).distance;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = loc;
      }
    }
    if (nearest != null && nearestDistance <= hitRadiusPx) {
      return nearest;
    }
    return null;
  }

  void _openLocationDetails(TravelLocation loc) {
    if (!mounted) return;
    _suppressMarkerTapUntil = DateTime.now().add(
      const Duration(milliseconds: 900),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageLocationsScreen(
          initiallyExpandedLocationId: loc.firestoreId,
          isReadOnly: _activeRouteLocations != null,
        ),
      ),
    );
  }

  bool _isSuppressedMarkerTap() {
    if (_suppressMarkerTapUntil != null &&
        DateTime.now().isBefore(_suppressMarkerTapUntil!)) {
      _suppressMarkerTapUntil = null;
      return true;
    }
    return false;
  }

  void _handleEndpointSelection(LatLng pos) async {
    final l10n = AppLocalizations.of(context)!;
    if (mounted) LoadingOverlay.show(context);
    final geoName =
        await _directionsService.getPlaceName(pos) ?? l10n.unknownLocation;
    if (mounted) LoadingOverlay.hide(context);

    if (!mounted) return;

    setState(() => _isAnyModalOpen = true);
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
    ).whenComplete(() => setState(() => _isAnyModalOpen = false));

    if (confirmed == true && mounted) {
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
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.selectNewEndpoint)));
        }
      }
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activeRouteLocations != null) return;

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

  void _showAboutDialog() {
    setState(() => _isAnyModalOpen = true);
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
                child: Image.asset('assets/icon/icon.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.email),
                title: const SelectableText("cetin.omer@outlook.com.tr"),
                onTap: () async {
                  final Uri uri = Uri.parse("mailto:cetin.omer@outlook.com.tr");
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
    ).whenComplete(() => setState(() => _isAnyModalOpen = false));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
          title: Text(
            l10n.selectEndpointTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Map layer with listener
            Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerMove: _onPointerMove,
              child: GoogleMap(
                key: const ValueKey('endpoint_google_map'),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  _isMapInitialized = true;
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
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                myLocationEnabled: true,
                scrollGesturesEnabled: !_isAnyModalOpen,
                zoomGesturesEnabled: !_isAnyModalOpen,
                rotateGesturesEnabled: !_isAnyModalOpen,
                tiltGesturesEnabled: !_isAnyModalOpen,
              ),
            ),

            // Long press indicator
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

            // Overlay wrapped in PointerInterceptor
            Positioned(
              top: 10,
              left: 15,
              right: 15,
              child: PointerInterceptor(
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: colorScheme.surface,
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

                                  if (!await ConnectivityService()
                                          .checkConnection() &&
                                      mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.noInternetForOperation,
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

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
                                      markerId: const MarkerId('searchResult'),
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
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'myLocationFabEndPoint',
              onPressed: () => _goToCurrentLocation(isInitial: false),
              tooltip: l10n.myLocationTooltip,
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.my_location, size: 24),
            ),
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

                if (result is Map<String, dynamic>) {
                  final locations =
                      result['locations'] as List<TravelLocation>?;
                  final endLocation = result['endLocation'] as TravelLocation?;
                  final waypoints =
                      result['waypoints'] as List<TravelLocation>?;

                  if (locations != null && endLocation != null) {
                    _drawRoute(locations, endLocation: endLocation);
                  } else if (waypoints != null && endLocation != null) {
                    _drawRoute(waypoints, endLocation: endLocation);
                  } else if (waypoints != null && waypoints.isNotEmpty) {
                    _drawRoute(waypoints);
                  } else if (locations != null && locations.isNotEmpty) {
                    _drawRoute(locations);
                  }
                } else if (result is List<TravelLocation> &&
                    result.isNotEmpty) {
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
                final connectivityResult = await ConnectivityService()
                    .checkConnection();
                if (!connectivityResult && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.noInternetForOperation),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (!mounted) return;
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
                  MaterialPageRoute(builder: (context) => const GroupsScreen()),
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
        title: GestureDetector(
          onTap: _showAboutDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Image.asset(
                    'assets/icon/icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'TripBook',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: appBarActions.map((action) {
          if (action is IconButton) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: action.icon,
                  onPressed: action.onPressed,
                  tooltip: action.tooltip,
                  color: Colors.white,
                ),
              ),
            );
          }
          return action;
        }).toList(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                brandAppBarBlue(Theme.of(context).brightness),
                Colors.blue[900]!,
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerMove: _onPointerMove,
            child: GoogleMap(
              key: const ValueKey('google_map'),
              onMapCreated: (GoogleMapController controller) async {
                _mapController = controller;
                _isMapInitialized = true;
                if (widget.initialLocation != null) {
                  await _goToInitialLocation();
                } else if (_currentPosition != null) {
                  await _goToCurrentLocation(isInitial: true);
                }
              },
              initialCameraPosition: initialCamPos,
              markers: _markers,
              polylines: _polylines,
              mapType: _currentMapType,
              compassEnabled: false,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              scrollGesturesEnabled: !_isAnyModalOpen,
              zoomGesturesEnabled: !_isAnyModalOpen,
              rotateGesturesEnabled: !_isAnyModalOpen,
              tiltGesturesEnabled: !_isAnyModalOpen,
              onCameraMove: (position) {
                _cameraPosition = position;
                // Only rebuild when the "rotated" state actually flips (i.e.
                // the reset-bearing FAB appears/disappears). Panning and
                // zooming keep bearing unchanged, so no rebuild is needed.
                final rotated = position.bearing != 0;
                if (rotated != _isMapRotated) {
                  _isMapRotated = rotated;
                  setState(() {
                    _currentBearing = position.bearing;
                  });
                } else {
                  _currentBearing = position.bearing;
                }
              },
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
          if (_showApiKeyWarning)
            PointerInterceptor(
              child: Positioned.fill(
                child: Container(
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        l10n.apiKeyWarning,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: PointerInterceptor(
              child: Column(
                children: [
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.search,
                            color: colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.searchHint,
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _placePredictions = [];
                                _searchResultMarker = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_placePredictions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemCount: _placePredictions.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: colorScheme.outlineVariant,
                              indent: 56,
                            ),
                            itemBuilder: (context, index) {
                              final prediction = _placePredictions[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
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
                                        markerId: const MarkerId(
                                          'search_result',
                                        ),
                                        position: latLng,
                                        infoWindow: InfoWindow(
                                          title:
                                              prediction['description'] ??
                                              l10n.unknownLocation,
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
                                    _updateMapElements();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            prediction['description'] ??
                                                l10n.unknownLocation,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: colorScheme.onSurfaceVariant,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 70,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: l10n.resetBearingTooltip,
                    child: InkWell(
                      onTap: _resetBearing,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: AnimatedRotation(
                          turns: _currentBearing / 360,
                          duration: const Duration(milliseconds: 250),
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: _MapCompass(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 12, endIndent: 12),
                  _buildMapControlButton(
                    icon: Icons.layers,
                    tooltip: l10n.mapTypeTooltip,
                    onPressed: _toggleMapType,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 146.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: 'myLocationFab',
            onPressed: () => _goToCurrentLocation(isInitial: false),
            tooltip: l10n.myLocationTooltip,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.my_location, size: 24),
          ),
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

  Widget _buildRouteOptionCard(
    BuildContext context, {
    required IconData icon,
    required List<Color> gradient,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
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

    setState(() => _isAnyModalOpen = true);
    showDialog(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return Dialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        brandButtonBlue(Theme.of(dialogContext).brightness),
                        brandGradientEndBlue(
                          Theme.of(dialogContext).brightness,
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.alt_route,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.createRouteDialogTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.createRouteDialogContent,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildRouteOptionCard(
                  dialogContext,
                  icon: Icons.folder_copy_outlined,
                  gradient: [Colors.blue.shade600, Colors.blue.shade800],
                  title: l10n.fromGroup,
                  description: l10n.fromGroupDescription,
                  onTap: () async {
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
                      if (mounted) LoadingOverlay.show(context);
                      try {
                        final locations = await _firestoreService
                            .getLocationsForGroup(selectedGroupId);
                        if (locations.isNotEmpty) {
                          if (_currentPosition == null) {
                            if (mounted) LoadingOverlay.hide(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.currentLocationError),
                              ),
                            );
                            return;
                          }

                          // Respect the group's internal order (manual or createdAt)
                          final orderedLocations = locations;

                          String defaultEndLocationGeoName;
                          try {
                            defaultEndLocationGeoName =
                                await _directionsService.getPlaceName(
                                  LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                ) ??
                                l10n.unknownLocation;
                          } catch (e) {
                            defaultEndLocationGeoName = l10n.unknownLocation;
                          }
                          final defaultEndLocation = TravelLocation(
                            name: l10n.endPoint,
                            geoName: defaultEndLocationGeoName,
                            description: l10n.routeEnd,
                            latitude: _currentPosition!.latitude,
                            longitude: _currentPosition!.longitude,
                            firestoreId: 'end',
                            userId: '',
                          );

                          if (mounted) LoadingOverlay.hide(context);

                          final result = await Navigator.push<dynamic>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationSelectionScreen(
                                initialLocations: orderedLocations,
                                endLocation:
                                    homeEndLocation ?? defaultEndLocation,
                                fallbackEndLocation: homeEndLocation != null
                                    ? defaultEndLocation
                                    : null,
                              ),
                            ),
                          );
                          if (result is List<TravelLocation>) {
                            _drawRoute(result);
                          } else if (result == 'change_end_location') {
                            setState(() {
                              _isSelectingEndpoint = true;
                              _locationsForRoute = orderedLocations;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.selectNewEndpoint)),
                            );
                          }
                        } else {
                          if (mounted) LoadingOverlay.hide(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.minTwoLocationsError)),
                          );
                        }
                      } catch (e) {
                        if (mounted) LoadingOverlay.hide(context);
                        rethrow;
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildRouteOptionCard(
                  dialogContext,
                  icon: Icons.touch_app_outlined,
                  gradient: [Colors.teal.shade600, Colors.teal.shade800],
                  title: l10n.manualSelection,
                  description: l10n.manualSelectionDescription,
                  onTap: () async {
                    Navigator.of(dialogContext).pop();
                    final List<TravelLocation>? selectedLocations =
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageLocationsScreen(
                              isForSelection: true,
                            ),
                          ),
                        );
                    if (selectedLocations != null &&
                        selectedLocations.isNotEmpty) {
                      if (mounted) LoadingOverlay.show(context);
                      try {
                        if (_currentPosition == null) {
                          if (mounted) LoadingOverlay.hide(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.currentLocationError)),
                          );
                          return;
                        }
                        final optimizedLocations = _optimizeRouteByProximity(
                          selectedLocations,
                          _currentPosition!,
                        );
                        String defaultEndLocationGeoName;
                        try {
                          defaultEndLocationGeoName =
                              await _directionsService.getPlaceName(
                                LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                              ) ??
                              l10n.unknownLocation;
                        } catch (e) {
                          defaultEndLocationGeoName = l10n.unknownLocation;
                        }
                        final defaultEndLocation = TravelLocation(
                          name: l10n.endPoint,
                          geoName: defaultEndLocationGeoName,
                          description: l10n.routeEnd,
                          latitude: _currentPosition!.latitude,
                          longitude: _currentPosition!.longitude,
                          firestoreId: 'end',
                          userId: '',
                        );

                        if (mounted) LoadingOverlay.hide(context);

                        final result = await Navigator.push<dynamic>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationSelectionScreen(
                              initialLocations: optimizedLocations,
                              endLocation:
                                  homeEndLocation ?? defaultEndLocation,
                              fallbackEndLocation: homeEndLocation != null
                                  ? defaultEndLocation
                                  : null,
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
                      } catch (e) {
                        if (mounted) LoadingOverlay.hide(context);
                        rethrow;
                      }
                    }
                  },
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => setState(() => _isAnyModalOpen = false));
  }

  void _showAddLocationDialog(LatLng pos, String geoName) {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: geoName);
    final descriptionController = TextEditingController();
    final notesController = TextEditingController();
    final needsController = TextEditingController();
    int? selectedDuration;
    List<String> selectedGroupIds = [];
    List<LocationGroup> dialogGroups = {
      for (var g in _allGroups) g.firestoreId: g,
    }.values.toList();

    setState(() => _isAnyModalOpen = true);
    showDialog(
      context: context,
      builder: (context) {
        return PointerInterceptor(
          child: StatefulBuilder(
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
                        DurationSelector(
                          onChanged: (value) => selectedDuration = value,
                        ),
                        const SizedBox(height: 16),
                        MultiGroupSelector(
                          selectedGroupIds: selectedGroupIds,
                          allGroups: dialogGroups,
                          onChanged: (ids) {
                            setState(() {
                              selectedGroupIds = ids;
                            });
                          },
                          onAddNewGroup: () async {
                            final newGroup = await _showAddNewGroupDialog(
                              context,
                            );
                            if (newGroup != null) {
                              setState(() {
                                if (!_allGroups.any(
                                  (g) => g.firestoreId == newGroup.firestoreId,
                                )) {
                                  _allGroups.add(newGroup);
                                }
                                if (!dialogGroups.any(
                                  (g) => g.firestoreId == newGroup.firestoreId,
                                )) {
                                  dialogGroups.add(newGroup);
                                }
                              });
                            }
                            return newGroup;
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
                          estimatedDuration: selectedDuration,
                          groupIds: selectedGroupIds,
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
          ),
        );
      },
    ).whenComplete(() => setState(() => _isAnyModalOpen = false));
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

class _MapCompass extends StatelessWidget {
  const _MapCompass();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CompassPainter());
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius - 0.5,
      Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // North (red) half
    final northPath = Path()
      ..moveTo(center.dx, center.dy - radius + 1)
      ..lineTo(center.dx - 5, center.dy)
      ..lineTo(center.dx + 5, center.dy)
      ..close();
    canvas.drawPath(northPath, Paint()..color = const Color(0xFFE53935));

    // South (grey) half
    final southPath = Path()
      ..moveTo(center.dx, center.dy + radius - 1)
      ..lineTo(center.dx - 5, center.dy)
      ..lineTo(center.dx + 5, center.dy)
      ..close();
    canvas.drawPath(southPath, Paint()..color = Colors.grey[500]!);

    // "N" label
    final painter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - radius + 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) => false;
}

class _MapTypePreview extends StatelessWidget {
  final MapType type;
  const _MapTypePreview({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: CustomPaint(painter: _MapTypePreviewPainter(type: type)),
    );
  }
}

class _MapTypePreviewPainter extends CustomPainter {
  final MapType type;
  _MapTypePreviewPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (type) {
      case MapType.normal:
        canvas.drawColor(const Color(0xFFE8E3D8), BlendMode.src);
        _drawRoad(
          canvas,
          Offset(0, h * 0.4),
          Offset(w, h * 0.35),
          2.2,
          Colors.white,
        );
        _drawRoad(
          canvas,
          Offset(w * 0.25, 0),
          Offset(w * 0.3, h),
          1.6,
          Colors.white,
        );
        _drawRoad(
          canvas,
          Offset(0, h * 0.75),
          Offset(w, h * 0.7),
          1.4,
          const Color(0xFFFFD98A),
        );
        _drawPark(
          canvas,
          Rect.fromLTWH(w * 0.62, h * 0.1, w * 0.28, h * 0.2),
          const Color(0xFFA8D5A2),
        );
        _drawPark(
          canvas,
          Rect.fromLTWH(w * 0.12, h * 0.72, w * 0.2, h * 0.22),
          const Color(0xFF9FD49E),
        );
      case MapType.satellite:
        canvas.drawColor(const Color(0xFF3E5A38), BlendMode.src);
        _drawPark(
          canvas,
          Rect.fromLTWH(0, h * 0.45, w, h * 0.55),
          const Color(0xFF2F4A2E),
        );
        _drawPark(
          canvas,
          Rect.fromLTWH(0, 0, w * 0.5, h * 0.3),
          const Color(0xFF354F2F),
        );
        _drawWater(
          canvas,
          Rect.fromLTWH(w * 0.6, h * 0.65, w * 0.4, h * 0.35),
          const Color(0xFF2E4A63),
        );
        _drawRoad(
          canvas,
          Offset(0, h * 0.5),
          Offset(w, h * 0.45),
          2,
          const Color(0xFF8A8A80),
        );
      case MapType.terrain:
        canvas.drawColor(const Color(0xFFEDE6D4), BlendMode.src);
        _drawPark(
          canvas,
          Rect.fromLTWH(0, 0, w, h * 0.3),
          const Color(0xFFBCD9A8),
        );
        _drawPark(
          canvas,
          Rect.fromLTWH(w * 0.5, h * 0.2, w * 0.5, h * 0.35),
          const Color(0xFFB5D4A0),
        );
        _drawContour(
          canvas,
          Offset(w * 0.5, h * 0.85),
          18,
          const Color(0xFFCBB894),
        );
        _drawContour(
          canvas,
          Offset(w * 0.55, h * 0.85),
          13,
          const Color(0xFFC2AE8A),
        );
        _drawRoad(
          canvas,
          Offset(0, h * 0.6),
          Offset(w, h * 0.55),
          1.6,
          Colors.white,
        );
      case MapType.hybrid:
        canvas.drawColor(const Color(0xFF3E5A38), BlendMode.src);
        _drawWater(
          canvas,
          Rect.fromLTWH(w * 0.6, h * 0.6, w * 0.4, h * 0.4),
          const Color(0xFF2E4A63),
        );
        _drawRoad(
          canvas,
          Offset(0, h * 0.5),
          Offset(w, h * 0.45),
          2.2,
          Colors.white,
        );
        _drawLabel(canvas, Offset(w * 0.18, h * 0.15), 'AŞ');
        _drawLabel(canvas, Offset(w * 0.42, h * 0.32), 'Lnk');
      case MapType.none:
        canvas.drawColor(Colors.grey[300]!, BlendMode.src);
    }
  }

  void _drawRoad(Canvas canvas, Offset a, Offset b, double width, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a, b, paint);
  }

  void _drawPark(Canvas canvas, Rect rect, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()..color = color,
    );
  }

  void _drawWater(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(rect, Paint()..color = color);
  }

  void _drawContour(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawLabel(Canvas canvas, Offset offset, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MapTypePreviewPainter oldDelegate) {
    return oldDelegate.type != type;
  }
}
