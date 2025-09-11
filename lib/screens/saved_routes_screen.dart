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
    if (route.firestoreId == null) return;

    final String title = route.isShared ? 'Paylaşımı Durdur' : 'Rotayı Paylaş';
    final String content = route.isShared
        ? "'${route.name}' rotasının toplulukla paylaşımını durdurmak istediğinizden emin misiniz?"
        : "'${route.name}' rotasını diğer kullanıcılarla paylaşmak istediğinizden emin misiniz? Rota, topluluk ekranında görünecektir.";
    final String confirmAction = route.isShared ? 'Paylaşımı Durdur' : 'Paylaş';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmAction)),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.shareRoute(route.firestoreId!, !route.isShared);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(route.isShared ? "'${route.name}' rotası artık paylaşılmıyor." : "'${route.name}' rotası başarıyla paylaşıldı!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteRoute(TravelRoute route) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rotayı Sil'),
        content: Text("'${route.name}' adlı rotayı silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirm == true && route.firestoreId != null) {
      await _firestoreService.deleteRoute(route.firestoreId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'${route.name}' rotası silindi."), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRouteDetailsDialog(TravelRoute route) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(route.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Planlanan Mesafe: ${route.totalDistance}'),
                if (route.actualDistance != null)
                  Text('Gerçekleşen Mesafe: ${route.actualDistance}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                if (route.actualDuration != null && route.actualDuration!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Gerçekleşen Toplam Süre: ${route.actualDuration}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
                if (route.needs != null && route.needs!.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text('İhtiyaç Listesi:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  ...route.needs!.map((need) => Text('  • $need')).toList(),
                ],
                if (route.notes != null && route.notes!.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text('Özel Notlar:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  ...route.notes!.map((note) => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('  • ${note['locationName']}: ${note['note']}'),
                  )).toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.directions),
              label: const Text('Başlat'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close details dialog

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
        title: const Text('Kaydedilmiş Rotalar'),
      ),
      body: StreamBuilder<List<TravelRoute>>(
        stream: _firestoreService.getRoutes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Kaydedilmiş rota bulunamadı.'));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
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
                  subtitle: Text('Mesafe: ${route.totalDistance} | Süre: ${route.totalTravelTime}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          route.isShared ? Icons.share : Icons.share_outlined,
                          color: route.isShared ? Colors.green : null,
                        ),
                        tooltip: route.isShared ? 'Paylaşımı Durdur' : 'Rotayı Paylaş',
                        onPressed: () => _shareRoute(route),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Rotayı Sil',
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
