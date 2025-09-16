import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tripbook/models/travel_route.dart';
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
  StreamSubscription? _communityRoutesSubscription;
  StreamSubscription? _userRoutesSubscription;

  List<TravelRoute>? _communityRoutes;
  List<TravelRoute>? _userRoutes;

  List<CommunityRouteItem> _items = [];
  List<CommunityRouteItem> get items => _items;

  bool _isLoading = true; // Start with loading true
  bool get isLoading => _isLoading;

  CommunityRoutesProvider() {
    _listenToStreams();
  }

  void _listenToStreams() {
    _communityRoutesSubscription?.cancel();
    _communityRoutesSubscription = _firestoreService.getCommunityRoutes().listen((routes) {
      _communityRoutes = routes;
      _processRoutes();
    });

    _userRoutesSubscription?.cancel();
    _userRoutesSubscription = _firestoreService.getRoutes().listen((routes) {
      _userRoutes = routes;
      _processRoutes();
    });
  }

  Future<void> _processRoutes() async {
    // Wait until both streams have delivered their first batch of data.
    if (_communityRoutes == null || _userRoutes == null) {
      return;
    }

    final downloadedCommunityIds = _userRoutes!
        .map((r) => r.communityRouteId)
        .whereType<String>()
        .toSet();

    final authorIds = _communityRoutes!
        .map((r) => r.sharedBy)
        .whereType<String>()
        .toSet()
        .toList();

    if (authorIds.isEmpty) {
      _items = _communityRoutes!.map((route) {
        return CommunityRouteItem(
          route: route,
          authorName: route.authorName ?? 'Bilinmiyor',
          isDownloaded: downloadedCommunityIds.contains(route.firestoreId),
        );
      }).toList();
    } else {
      final authorProfiles = await _firestoreService.getUsersProfilesByIds(authorIds);
      _items = _communityRoutes!.map((route) {
        final authorName = authorProfiles[route.sharedBy]?.name ??
            route.authorName ??
            'Bilinmiyor';
        final updatedRoute = route.copyWith(authorName: authorName);
        return CommunityRouteItem(
          route: updatedRoute,
          authorName: authorName,
          isDownloaded: downloadedCommunityIds.contains(route.firestoreId),
        );
      }).toList();
    }

    // Only set loading to false after the first successful processing.
    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  // Call this method to manually refresh the data if needed.
  void refreshRoutes() {
    // Reset and re-listen to the streams to force a full refresh.
    _communityRoutes = null;
    _userRoutes = null;
    _isLoading = true;
    notifyListeners();
    _listenToStreams();
  }

  @override
  void dispose() {
    _communityRoutesSubscription?.cancel();
    _userRoutesSubscription?.cancel();
    super.dispose();
  }
}
