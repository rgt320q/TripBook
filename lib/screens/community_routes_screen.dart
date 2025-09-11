import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/screens/location_selection_screen.dart';
import 'package:tripbook/services/directions_service.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/widgets/route_mini_map.dart';

// Helper class to hold a route and its author's name
class CommunityRouteItem {
  final TravelRoute route;
  final String authorName;

  CommunityRouteItem({required this.route, required this.authorName});
}

class CommunityRoutesScreen extends StatefulWidget {
  const CommunityRoutesScreen({super.key});

  @override
  State<CommunityRoutesScreen> createState() => _CommunityRoutesScreenState();
}

class _CommunityRoutesScreenState extends State<CommunityRoutesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<CommunityRouteItem>> _communityRoutesStream;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _communityRoutesStream =
        _firestoreService.getCommunityRoutes().asyncMap((routes) async {
      if (routes.isEmpty) return <CommunityRouteItem>[];

      final userIds =
          routes.map((r) => r.sharedBy).whereType<String>().toSet().toList();

      if (userIds.isEmpty) {
        return routes
            .map((route) =>
                CommunityRouteItem(route: route, authorName: 'Bilinmiyor'))
            .toList();
      }

      final profiles = await _firestoreService.getUsersProfilesByIds(userIds);

      return routes.map((route) {
        final authorName = profiles[route.sharedBy]?.name ?? 'Bilinmiyor';
        return CommunityRouteItem(route: route, authorName: authorName);
      }).toList();
    });
  }

  Future<void> _handleRouteTap(TravelRoute route) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rotayı İndir'),
        content: Text(
            "'${route.name}' rotasını ve tüm konumlarını kendi rotalarınıza kaydetmek istiyor musunuz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('İndir ve Görüntüle')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isDownloading = true;
      });

      try {
        List<String> newLocationIds = [];
        if (route.locations != null && route.locations!.isNotEmpty) {
          final locationsToImport = route.locations!
              .map((locMap) => TravelLocation.fromFirestore(
                  locMap['firestoreId'] ?? '', locMap))
              .map((loc) => TravelLocation(
                    name: loc.name,
                    geoName: loc.geoName,
                    description: loc.description,
                    latitude: loc.latitude,
                    longitude: loc.longitude,
                    notes: loc.notes,
                    needsList: loc.needsList,
                    estimatedDuration: loc.estimatedDuration,
                    isImported: true, // Mark as imported
                  ))
              .toList();

          newLocationIds = await _firestoreService.addLocations(locationsToImport);
        }

        final newRoute = route.copyWith(
          locationIds:
              newLocationIds.isNotEmpty ? newLocationIds : route.locationIds,
          isShared: false,
          sharedBy: null,
          averageRating: 0.0,
          ratingCount: 0,
          commentCount: 0,
          locations: [], // Clear locations when saving to user's own routes
        );

        final newRouteRef = await _firestoreService.addRoute(newRoute);
        final newRouteSnapshot = await newRouteRef.get();
        final newRouteData = newRouteSnapshot.data();

        if (mounted && newRouteData != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("'${route.name}' rotası başarıyla kaydedildi!"),
              backgroundColor: Colors.green,
            ),
          );
          _showRouteDetailsDialog(newRouteData);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rota indirilirken bir hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
        }
      }
    }
  }

  void _showRouteDetailsDialog(TravelRoute route) {
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
                Text('Planlanan Mesafe: ${route.totalDistance}'),
                if (route.actualDistance != null)
                  Text('Gerçekleşen Mesafe: ${route.actualDistance}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Planlanan Yol Süresi: ${route.totalTravelTime}'),
                if (route.totalStopDuration != null) ...[
                  const SizedBox(height: 4),
                  Text('Planlanan Mola Süresi: ${route.totalStopDuration}'),
                ],
                if (route.totalTripDuration != null) ...[
                  const SizedBox(height: 4),
                  Text('Planlanan Toplam Süre: ${route.totalTripDuration}'),
                ],
                if (route.actualDuration != null &&
                    route.actualDuration!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Gerçekleşen Toplam Süre: ${route.actualDuration}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
                if (route.needs != null && route.needs!.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text('İhtiyaç Listesi:',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  ...route.needs!.map((need) => Text('  • $need')).toList(),
                ],
                if (route.notes != null && route.notes!.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text('Özel Notlar:',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  ...route.notes!
                      .map((note) => Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                                '  • ${note['locationName']}: ${note['note']}'),
                          ))
                      .toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Kapat'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.directions),
              label: const Text('Başlat'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close details dialog

                final l10n = AppLocalizations.of(context)!;
                final userProfile = await _firestoreService.getUserProfile().first;
                TravelLocation? endLocation;

                if (userProfile?.homeLocation != null) {
                  endLocation = TravelLocation(
                    name: l10n.homeLocation,
                    geoName: '${userProfile!.homeLocation!.latitude.toStringAsFixed(4)}, ${userProfile.homeLocation!.longitude.toStringAsFixed(4)}',
                    latitude: userProfile.homeLocation!.latitude,
                    longitude: userProfile.homeLocation!.longitude,
                    firestoreId: 'home_end_location',
                  );
                } else {
                  try {
                    final position = await Geolocator.getCurrentPosition();
                    final geoName = await DirectionsService().getPlaceName(
                            LatLng(position.latitude, position.longitude)) ??
                        l10n.unknownLocation;
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

                final allLocations =
                    await _firestoreService.getLocationsByIds(route.locationIds);
                if (!mounted) return;

                if (allLocations.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bu rotada konum bulunamadı.')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topluluk Rotaları'),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<CommunityRouteItem>>(
            stream: _communityRoutesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('Henüz paylaşılmış bir rota bulunmuyor.'));
              }

              final items = snapshot.data!;

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final route = item.route;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _handleRouteTap(route),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (route.locations != null &&
                              route.locations!.isNotEmpty)
                            RouteMiniMap(route: route),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(route.name,
                                    style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                Text(
                                    'Mesafe: ${route.totalDistance} | Süre: ${route.totalTravelTime}'),
                                const SizedBox(height: 4),
                                Text(
                                  'Paylaşan: ${item.authorName}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontStyle: FontStyle.italic),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${route.averageRating.toStringAsFixed(1)} (${route.ratingCount} oy)',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.comment_outlined,
                                        color: Colors.grey, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${route.commentCount} yorum',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isDownloading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Rota indiriliyor...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
