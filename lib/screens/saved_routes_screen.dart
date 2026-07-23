import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/screens/location_selection_screen.dart';
import 'package:tripbook/services/directions_service.dart';
import 'package:tripbook/services/firestore_service.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _shareRoute(TravelRoute route) async {
    final l10n = AppLocalizations.of(context)!;
    if (route.firestoreId == null) return;

    final String title = route.isShared ? l10n.stopSharing : l10n.shareRoute;
    final String content = route.isShared
        ? l10n.stopSharingConfirmation(route.name)
        : l10n.shareRouteConfirmation(route.name);
    final String confirmAction = route.isShared
        ? l10n.stopSharing
        : l10n.shareRoute;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmAction),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final isCurrentlyShared = route.isShared;
        await _firestoreService.shareRoute(route.firestoreId!, !isCurrentlyShared);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isCurrentlyShared
                    ? l10n.routeNoLongerShared(route.name)
                    : l10n.routeSharedSuccessfully(route.name),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorOccurred(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteRoute(TravelRoute route) async {
    final l10n = AppLocalizations.of(context)!;
    bool deleteConfirmed = false;
    bool deleteLocations = false;

    if (route.communityRouteId != null) {
      // It's a community route, ask about locations
      final result = await showDialog<Map<String, bool>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteRoute),
          content: Text(l10n.deleteRouteConfirmationWithLocations),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop({'confirmed': false}),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop({'confirmed': true, 'deleteLocations': false}),
              child: Text(l10n.deleteRoute),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop({'confirmed': true, 'deleteLocations': true}),
              child: Text('${l10n.deleteRoute} + ${l10n.locationsLabel}'), // TODO: Localize
            ),
          ],
        ),
      );
      if (result != null && result['confirmed'] == true) {
        deleteConfirmed = true;
        deleteLocations = result['deleteLocations'] ?? false;
      }
    } else {
      // It's a regular route
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteRoute),
          content: Text(l10n.deleteRouteConfirmation(route.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.deleteLabel),
            ),
          ],
        ),
      );
      if (confirm == true) {
        deleteConfirmed = true;
      }
    }

    if (deleteConfirmed && route.firestoreId != null) {
      if (deleteLocations && route.locationIds.isNotEmpty) {
        await _firestoreService.deleteLocations(route.locationIds);
      }
      await _firestoreService.deleteRoute(route.firestoreId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.routeDeleted(route.name)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRouteDetailsDialog(TravelRoute route) {
    final l10n = AppLocalizations.of(context)!;
    final parentContext = context; // Ana context'i sakla

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(modalContext).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Gradient Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[600]!,
                      Colors.blue[800]!,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.route,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.routeDetails,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(modalContext).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance and Time Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.straighten,
                              label: l10n.plannedDistance,
                              value: route.totalDistance,
                              color: Colors.blue,
                              isHighlighted: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.access_time,
                              label: l10n.plannedTravelTime,
                              value: route.totalTravelTime,
                              color: Colors.green,
                              isHighlighted: true,
                            ),
                          ),
                        ],
                      ),

                      if (route.actualDistance != null || route.actualDuration != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (route.actualDistance != null)
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.straighten,
                                  label: l10n.actualDistance,
                                  value: route.actualDistance!,
                                  color: Colors.orange,
                                ),
                              ),
                            if (route.actualDistance != null && route.actualDuration != null)
                              const SizedBox(width: 12),
                            if (route.actualDuration != null)
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.timer,
                                  label: l10n.actualTotalTime,
                                  value: route.actualDuration!,
                                  color: Colors.purple,
                                ),
                              ),
                          ],
                        ),
                      ],

                      if (route.totalStopDuration != null || route.totalTripDuration != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (route.totalStopDuration != null)
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.pause_circle,
                                  label: l10n.totalBreakTime,
                                  value: route.totalStopDuration!,
                                  color: Colors.amber,
                                ),
                              ),
                            if (route.totalStopDuration != null && route.totalTripDuration != null)
                              const SizedBox(width: 12),
                            if (route.totalTripDuration != null)
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.schedule,
                                  label: l10n.plannedTotalTime,
                                  value: route.totalTripDuration!,
                                  color: Colors.indigo,
                                ),
                              ),
                          ],
                        ),
                      ],

                      // Needs Section
                      if (route.needs != null && route.needs!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green[200]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.checklist,
                                      color: Colors.green[600],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.needsListTitle,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...route.needs!.map(
                                (need) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green[600],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          need,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Notes Section
                      if (route.notes != null && route.notes!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blue[200]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.note,
                                      color: Colors.blue[600],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.privateNotesTitle,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...route.notes!.map(
                                (note) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[25],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue[100]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note['locationName']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        note['note']!,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Action Buttons
                      const SizedBox(height: 30),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green[400]!,
                              Colors.green[600]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              // Modal'ı kapat
                              Navigator.of(modalContext).pop();

                              try {
                                final userProfile = await _firestoreService
                                    .getUserProfile()
                                    .first;
                                TravelLocation? endLocation;

                                if (userProfile?.homeLocation != null) {
                                  endLocation = TravelLocation(
                                    name: l10n.homeLocation,
                                    geoName:
                                        '${userProfile!.homeLocation!.latitude.toStringAsFixed(4)}, ${userProfile.homeLocation!.longitude.toStringAsFixed(4)}',
                                    latitude: userProfile.homeLocation!.latitude,
                                    longitude: userProfile.homeLocation!.longitude,
                                    firestoreId: 'home_end_location',
                                    userId: userProfile.uid,
                                  );
                                } else {
                                  try {
                                    final position = await Geolocator.getCurrentPosition();
                                    final geoName =
                                        await DirectionsService().getPlaceName(
                                          LatLng(position.latitude, position.longitude),
                                        ) ??
                                        l10n.unknownLocation;
                                    endLocation = TravelLocation(
                                      name: l10n.currentLocation,
                                      geoName: geoName,
                                      latitude: position.latitude,
                                      longitude: position.longitude,
                                      firestoreId: 'end', userId: '',
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(parentContext).showSnackBar(
                                        SnackBar(content: Text(l10n.currentLocationError)),
                                      );
                                    }
                                    return;
                                  }
                                }

                                final allLocations = await _firestoreService.getLocationsByIds(
                                  route.locationIds,
                                );
                                if (!mounted) return;

                                if (allLocations.isEmpty) {
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    SnackBar(content: Text(l10n.noLocationsInRoute)),
                                  );
                                  return;
                                }

                                final result = await Navigator.of(parentContext).push(
                                  MaterialPageRoute(
                                    builder: (context) => LocationSelectionScreen(
                                      initialLocations: allLocations,
                                      endLocation: endLocation,
                                    ),
                                  ),
                                );

                                if (result != null && mounted) {
                                  // LocationSelectionScreen'den dönen sonuç tüm lokasyonları içeriyor
                                  if (result is List<TravelLocation> && result.isNotEmpty) {
                                    // MapScreen'e uygun format ile gönder
                                    final routeData = {
                                      'locations': result,
                                      'endLocation': endLocation,
                                    };
                                    Navigator.of(parentContext).pop(routeData);
                                  } else {
                                    // Beklenmeyen format
                                    Navigator.of(parentContext).pop(result);
                                  }
                                }
                              } catch (e) {
                                // Herhangi bir hata durumunda kullanıcıyı bilgilendir
                                  if (mounted) {
                                    ScaffoldMessenger.of(parentContext).showSnackBar(
                                      SnackBar(content: Text('${l10n.error("")} ${e.toString()}')),
                                    );
                                  }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.directions,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.start,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedRoutes)),
      body: StreamBuilder<List<TravelRoute>>(
        stream: _firestoreService.getRoutes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(l10n.noSavedRoutes));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(l10n.errorOccurred(snapshot.error.toString())),
            );
          }

          final routes = snapshot.data!;
          // Sort routes by creation date, newest first
          routes.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.route_outlined),
                  onTap: () => _showRouteDetailsDialog(route),
                  title: Text(
                    route.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.distanceLabel}: ${route.totalDistance} | ${l10n.durationLabel}: ${route.totalTravelTime}',
                      ),
                      if (route.communityRouteId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            l10n.downloadedFromCommunity,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          route.isShared ? Icons.share : Icons.share_outlined,
                          color: route.isShared ? Colors.green : Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: route.isShared
                            ? l10n.stopSharing
                            : l10n.shareRoute,
                        onPressed: route.communityRouteId != null
                            ? null
                            : () => _shareRoute(route),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        tooltip: l10n.deleteRoute,
                        onPressed: () => _deleteRoute(route),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? color : Colors.grey[200]!,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted ? [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
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
              color: isHighlighted ? color : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
