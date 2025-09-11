import 'package:flutter/material.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/screens/community_route_detail_screen.dart';
import 'package:tripbook/services/firestore_service.dart';

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

  @override
  void initState() {
    super.initState();
    _communityRoutesStream =
        _firestoreService.getCommunityRoutes().asyncMap((routes) async {
      if (routes.isEmpty) return <CommunityRouteItem>[];

      final userIds =
          routes.map((r) => r.sharedBy).whereType<String>().toSet().toList();
      
      if (userIds.isEmpty) {
        return routes.map((route) => CommunityRouteItem(route: route, authorName: 'Bilinmiyor')).toList();
      }

      final profiles = await _firestoreService.getUsersProfilesByIds(userIds);

      return routes.map((route) {
        final authorName = profiles[route.sharedBy]?.name ?? 'Bilinmiyor';
        return CommunityRouteItem(route: route, authorName: authorName);
      }).toList();
    });
  }

  void _navigateToRouteDetails(TravelRoute route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommunityRouteDetailScreen(route: route),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topluluk Rotaları'),
      ),
      body: StreamBuilder<List<CommunityRouteItem>>(
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
                margin:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  onTap: () => _navigateToRouteDetails(route),
                  title: Text(route.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Mesafe: ${route.totalDistance} | Süre: ${route.totalTravelTime}'),
                      const SizedBox(height: 4),
                      Text(
                        'Paylaşan: ${item.authorName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 4),
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
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              );
            },
          );
        },
      ),
    );
  }
}