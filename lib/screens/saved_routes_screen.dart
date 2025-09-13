import 'package:cloud_firestore/cloud_firestore.dart';
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
    final String confirmAction = route.isShared ? l10n.stopSharing : l10n.shareRoute;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmAction)),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.shareRoute(route.firestoreId!, !route.isShared);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(route.isShared ? l10n.routeNoLongerShared(route.name) : l10n.routeSharedSuccessfully(route.name)),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteRoute(TravelRoute route) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRoute),
        content: Text(l10n.deleteRouteConfirmation(route.name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.deleteLabel)),
        ],
      ),
    );
    if (confirm == true && route.firestoreId != null) {
      await _firestoreService.deleteRoute(route.firestoreId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.routeDeleted(route.name)), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRouteDetailsDialog(TravelRoute route) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(route.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.routeDetailsPlannedDistance(route.totalDistance)),
                if (route.actualDistance != null)
                  Text(l10n.routeDetailsActualDistance(route.actualDistance!)),
                const SizedBox(height: 8),
                Text(l10n.routeDetailsPlannedTravelTime(route.totalTravelTime)),
                if (route.totalStopDuration != null) ...[
                  const SizedBox(height: 4),
                  Text(l10n.routeDetailsPlannedStopTime(route.totalStopDuration!)),
                ],
                if (route.totalTripDuration != null) ...[
                  const SizedBox(height: 4),
                  Text(l10n.routeDetailsPlannedTotalTime(route.totalTripDuration!)),
                ],
                if (route.actualDuration != null && route.actualDuration!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.routeDetailsActualTotalTime(route.actualDuration!),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
                if (route.needs != null && route.needs!.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text(l10n.needsListTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  ...route.needs!.map((need) => Text('  • $need')),
                ],
                if (route.notes != null && route.notes!.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text(l10n.privateNotesTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  ...route.notes!.map((note) => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('  • ${note['locationName']}: ${note['note']}'),
                  )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.directions),
              label: Text(l10n.start),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close details dialog

                final userProfile = await _firestoreService.getUserProfile().first;
                TravelLocation? endLocation;

                if (userProfile?.homeLocation != null) {
                  endLocation = TravelLocation(
                    name: l10n.homeLocation,
                    geoName:
                        '${userProfile!.homeLocation!.latitude.toStringAsFixed(4)}, ${userProfile.homeLocation!.longitude.toStringAsFixed(4)}',
                    latitude: userProfile.homeLocation!.latitude,
                    longitude: userProfile.homeLocation!.longitude,
                    firestoreId: 'home_end_location',
                  );
                } else {
                  try {
                    final position = await Geolocator.getCurrentPosition();
                    final geoName = await DirectionsService().getPlaceName(LatLng(position.latitude, position.longitude)) ?? l10n.unknownLocation;
                    endLocation = TravelLocation(
                      name: l10n.currentLocation,
                      geoName: geoName,
                      latitude: position.latitude,
                      longitude: position.longitude,
                      firestoreId: 'end',
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.currentLocationError)),
                    );
                    return;
                  }
                }

                final allLocations = await _firestoreService.getLocationsByIds(route.locationIds);
                if (!mounted) return;

                if (allLocations.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.noLocationsInRoute)),
                  );
                  return;
                }

                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LocationSelectionScreen(
                      initialLocations: allLocations,
                      endLocation: endLocation,
                    ),
                  ),
                );

                if (result != null && mounted) {
                  Navigator.of(context).pop(result); // Go back to map
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savedRoutes),
      ),
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
            return Center(child: Text(l10n.errorOccurred(snapshot.error.toString())));
          }

          final routes = snapshot.data!;
          // Sort routes by creation date, newest first
          routes.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  onTap: () => _showRouteDetailsDialog(route),
                  title: Text(route.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${l10n.distanceLabel}: ${route.totalDistance} | ${l10n.durationLabel}: ${route.totalTravelTime}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          route.isShared ? Icons.share : Icons.share_outlined,
                          color: route.isShared ? Colors.green : null,
                        ),
                        tooltip: route.isShared ? l10n.stopSharing : l10n.shareRoute,
                        onPressed: () => _shareRoute(route),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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
}
