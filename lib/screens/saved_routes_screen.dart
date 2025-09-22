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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(route.name, style: theme.textTheme.headlineSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(l10n.plannedDistance),
                  subtitle: Text(route.totalDistance),
                ),
                if (route.actualDistance != null)
                  ListTile(
                    title: Text(l10n.actualDistance),
                    subtitle: Text(route.actualDistance!),
                  ),
                const Divider(),
                ListTile(
                  title: Text(l10n.plannedTravelTime),
                  subtitle: Text(route.totalTravelTime),
                ),
                if (route.totalStopDuration != null)
                  ListTile(
                    title: Text(l10n.totalBreakTime),
                    subtitle: Text(route.totalStopDuration!),
                  ),
                if (route.totalTripDuration != null)
                  ListTile(
                    title: Text(l10n.plannedTotalTime),
                    subtitle: Text(route.totalTripDuration!),
                  ),
                if (route.actualDuration != null &&
                    route.actualDuration!.isNotEmpty)
                  ListTile(
                    title: Text(l10n.actualTotalTime),
                    subtitle: Text(route.actualDuration!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                if (route.needs != null && route.needs!.isNotEmpty) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(l10n.needsListTitle, style: theme.textTheme.titleLarge),
                  ),
                  ...route.needs!.map((need) => ListTile(leading: const Icon(Icons.check_box_outline_blank), title: Text(need))),
                ],
                if (route.notes != null && route.notes!.isNotEmpty) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(l10n.privateNotesTitle, style: theme.textTheme.titleLarge),
                  ),
                  ...route.notes!.map(
                    (note) => ListTile(
                      leading: const Icon(Icons.note),
                      title: Text(note['locationName']!),
                      subtitle: Text(note['note']!),
                    ),
                  ),
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
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.currentLocationError)),
                    );
                    return;
                  }
                }

                final allLocations = await _firestoreService.getLocationsByIds(
                  route.locationIds,
                );
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
}
