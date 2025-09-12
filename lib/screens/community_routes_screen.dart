import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tripbook/l10n/app_localizations.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/providers/community_routes_provider.dart';
import 'package:tripbook/screens/location_selection_screen.dart';
import 'package:tripbook/services/directions_service.dart';
import 'package:tripbook/services/firestore_service.dart';
import 'package:tripbook/widgets/route_mini_map.dart';

class CommunityRoutesScreen extends StatefulWidget {
  const CommunityRoutesScreen({super.key});

  @override
  State<CommunityRoutesScreen> createState() => _CommunityRoutesScreenState();
}

class _CommunityRoutesScreenState extends State<CommunityRoutesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isDownloading = false;
  bool _hideDownloaded = false;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to fetch the data after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // We set listen to false because we don't need to rebuild this widget
      // when the provider notifies listeners, that's handled by the Consumer.
      Provider.of<CommunityRoutesProvider>(context, listen: false)
          .fetchRoutes();
    });
  }

  Future<void> _handleRouteTap(
      TravelRoute route, CommunityRoutesProvider provider) async {
    if (route.firestoreId == null) return;

    final existingRoute =
        await _firestoreService.getDownloadedCommunityRoute(route.firestoreId!);

    bool shouldProceed = false;

    if (existingRoute != null) {
      final confirmOverwrite = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(child: Text('Uyarı: Rota Zaten Mevcut')),
            ],
          ),
          content: const Text(
              'Bu rotayı daha önce indirdiniz. Mevcut sürümün üzerine yazmak istiyor musunuz?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Üzerine Yaz')),
          ],
        ),
      );
      if (confirmOverwrite == true) {
        shouldProceed = true;
      }
    } else {
      final confirmDownload = await showDialog<bool>(
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
      if (confirmDownload == true) {
        shouldProceed = true;
      }
    }

    if (!shouldProceed) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      List<String> newLocationIds = [];
      if (route.locations != null && route.locations!.isNotEmpty) {
        final locationsToImport = route.locations!
            .map((locMap) =>
                TravelLocation.fromFirestore(locMap['firestoreId'] ?? '', locMap))
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

      final newRouteData = route.copyWith(
        locationIds:
            newLocationIds.isNotEmpty ? newLocationIds : route.locationIds,
        isShared: false,
        sharedBy: null,
        averageRating: 0.0,
        ratingCount: 0,
        commentCount: 0,
        locations: [], // Clear locations when saving to user's own routes
        communityRouteId: route.firestoreId, // Set the original community route ID
      );

      if (existingRoute != null && existingRoute.firestoreId != null) {
        // Update existing route
        await _firestoreService.updateRoute(
            existingRoute.firestoreId!, newRouteData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("'${route.name}' rotası başarıyla güncellendi!"),
              backgroundColor: Colors.green,
            ),
          );
          _showRouteDetailsDialog(
              newRouteData.copyWith(firestoreId: existingRoute.firestoreId));
        }
      } else {
        // Add as new route
        final newRouteRef = await _firestoreService.addRoute(newRouteData);
        final newRouteSnapshot = await newRouteRef.get();
        final addedRouteData = newRouteSnapshot.data();

        if (mounted && addedRouteData != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("'${route.name}' rotası başarıyla kaydedildi!"),
              backgroundColor: Colors.green,
            ),
          );
          _showRouteDetailsDialog(addedRouteData);
        }
      }
      // After download/update, refresh the list in the provider
      await provider.fetchRoutes();
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
                  ...route.needs!.map((need) => Text('  • $need')),
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
                      ,
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
                    geoName:
                        '${userProfile!.homeLocation!.latitude.toStringAsFixed(4)}, ${userProfile.homeLocation!.longitude.toStringAsFixed(4)}',
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
        actions: [
          IconButton(
            icon: Icon(_hideDownloaded ? Icons.visibility_off : Icons.visibility),
            tooltip: _hideDownloaded
                ? 'İndirilenleri Göster'
                : 'İndirilenleri Gizle',
            onPressed: () {
              setState(() {
                _hideDownloaded = !_hideDownloaded;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<CommunityRoutesProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.items.isEmpty) {
                return const Center(
                    child: Text('Henüz paylaşılmış bir rota bulunmuyor.'));
              }

              final allItems = provider.items;
              final filteredItems = _hideDownloaded
                  ? allItems.where((item) => !item.isDownloaded).toList()
                  : allItems;

              if (filteredItems.isEmpty) {
                return const Center(
                  child: Text('Tüm rotalar indirilmiş ve gizlenmiş.'),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.fetchRoutes(),
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final route = item.route;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      clipBehavior: Clip.antiAlias,
                      color: item.isDownloaded ? Colors.green[50] : null,
                      child: InkWell(
                        onTap: () => _handleRouteTap(route, provider),
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(route.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge),
                                      ),
                                      if (item.isDownloaded)
                                        const Icon(Icons.check_circle,
                                            color: Colors.green, size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Mesafe: ${route.totalDistance} | Süre: ${route.totalTravelTime}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Paylaşan: ${item.authorName}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontStyle: FontStyle.italic),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${route.averageRating.toStringAsFixed(1)} (${route.ratingCount} oy)',
                                        style:
                                            Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.comment_outlined,
                                          color: Colors.grey, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${route.commentCount} yorum',
                                        style:
                                            Theme.of(context).textTheme.bodySmall,
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
                ),
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
                    Text('Rota indiriliyor...',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}