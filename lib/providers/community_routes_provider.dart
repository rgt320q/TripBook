import 'package:flutter/material.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/models/user_profile.dart';
import 'package:tripbook/services/firestore_service.dart';

// Helper class to hold a route and its author's name
class CommunityRouteItem {
  final TravelRoute route;
  final String authorName;
  final bool isDownloaded;

  CommunityRouteItem({
    required this.route,
    required this.authorName,
    this.isDownloaded = false,
  });
}

class CommunityRoutesProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<CommunityRouteItem> _items = [];
  List<CommunityRouteItem> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchRoutes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final communityRoutes = await _firestoreService.getCommunityRoutesOnce();
      final userRoutes = await _firestoreService.getRoutesOnce();

      final downloadedCommunityIds = userRoutes
          .map((r) => r.communityRouteId)
          .whereType<String>()
          .toSet();

      final userIds = communityRoutes
          .map((r) => r.sharedBy)
          .whereType<String>()
          .toSet()
          .toList();

      Map<String, UserProfile> profiles = {};
      if (userIds.isNotEmpty) {
        profiles = await _firestoreService.getUsersProfilesByIds(userIds);
      }

      _items = communityRoutes.map((route) {
        final authorName = profiles[route.sharedBy]?.name ?? 'Bilinmiyor';
        return CommunityRouteItem(
          route: route,
          authorName: authorName,
          isDownloaded: downloadedCommunityIds.contains(route.firestoreId),
        );
      }).toList();
    } catch (e) {
      // Handle error appropriately
      print('Error fetching community routes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
