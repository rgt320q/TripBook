import 'dart:convert' as convert;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tripbook/models/reached_location_log.dart';
import 'package:tripbook/models/route_comment.dart';
import 'package:tripbook/models/travel_location.dart';
import 'package:tripbook/models/location_group.dart';
import 'package:tripbook/models/travel_route.dart';
import 'package:tripbook/models/user_profile.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() {
    return _instance;
  }

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirestoreService._internal({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @visibleForTesting
  FirestoreService.internal(this._db, this._auth);

  static const String _functionsBase =
      'https://us-central1-tripbook-68238.cloudfunctions.net';

  User? get _currentUser => _auth.currentUser;

  Future<String?> _idToken() async {
    try {
      return await _currentUser?.getIdToken();
    } catch (e) {
      if (kDebugMode) print('Error getting ID token: $e');
      return null;
    }
  }

  // Get user-specific locations collection
  CollectionReference<TravelLocation> get _locationsCollection {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }
    return _db
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('locations')
        .withConverter<TravelLocation>(
          fromFirestore: (snapshots, _) =>
              TravelLocation.fromFirestore(snapshots.id, snapshots.data()!),
          toFirestore: (location, _) => location.toFirestore(),
        );
  }

  Future<void> addLocation(TravelLocation location) async {
    try {
      final docRef = await _locationsCollection.add(location);
      
      // If location belongs to groups, update each group's locationIds
      if (location.groupIds.isNotEmpty) {
        final WriteBatch batch = _db.batch();
        for (final groupId in location.groupIds) {
          final groupRef = _db.collection('users')
              .doc(_currentUser!.uid)
              .collection('groups')
              .doc(groupId);
          batch.update(groupRef, {
            'locationIds': FieldValue.arrayUnion([docRef.id])
          });
        }
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to add location: ${e.toString()}');
    }
  }

  Future<List<String>> addLocations(List<TravelLocation> locations) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }
    
    try {
      final WriteBatch batch = _db.batch();
      final List<String> newIds = [];

      for (final location in locations) {
        final newDocRef = _locationsCollection.doc();
        batch.set(newDocRef, location);
        newIds.add(newDocRef.id);
      }

      await batch.commit();
      return newIds;
    } catch (e) {
      throw Exception('Failed to add locations: ${e.toString()}');
    }
  }

  Stream<List<TravelLocation>> getLocations() {
    return _locationsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<List<TravelLocation>> getLocationsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await _locationsCollection
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    final locationsMap = {for (var doc in snapshot.docs) doc.id: doc.data()};
    // Order the results based on the original ID list
    return ids
        .map((id) => locationsMap[id])
        .where((loc) => loc != null)
        .cast<TravelLocation>()
        .toList();
  }

  Future<void> updateLocation(String id, TravelLocation location) async {
    try {
      final oldDoc = await _locationsCollection.doc(id).get();
      final List<String> oldGroupIds = List<String>.from(oldDoc.data()?.groupIds ?? []);
      
      await _locationsCollection.doc(id).update(location.toFirestore());

      // Calculate added and removed groups
      final addedGroups = location.groupIds.where((g) => !oldGroupIds.contains(g)).toList();
      final removedGroups = oldGroupIds.where((g) => !location.groupIds.contains(g)).toList();

      if (addedGroups.isNotEmpty || removedGroups.isNotEmpty) {
        final WriteBatch batch = _db.batch();
        
        // Remove from old groups
        for (final groupId in removedGroups) {
          final groupRef = _db.collection('users')
              .doc(_currentUser!.uid)
              .collection('groups')
              .doc(groupId);
          batch.update(groupRef, {
            'locationIds': FieldValue.arrayRemove([id])
          });
        }
        
        // Add to new groups
        for (final groupId in addedGroups) {
          final groupRef = _db.collection('users')
              .doc(_currentUser!.uid)
              .collection('groups')
              .doc(groupId);
          batch.update(groupRef, {
            'locationIds': FieldValue.arrayUnion([id])
          });
        }
        
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to update location: ${e.toString()}');
    }
  }

  Future<void> updateLocationNeeds(
    String docId,
    List<Map<String, dynamic>> needs,
  ) async {
    try {
      await _locationsCollection.doc(docId).update({'needsList': needs});
    } catch (e) {
      throw Exception('Failed to update location needs: ${e.toString()}');
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      final doc = await _locationsCollection.doc(id).get();
      final List<String> groupIds = List<String>.from(doc.data()?.groupIds ?? []);

      await _locationsCollection.doc(id).delete();

      if (groupIds.isNotEmpty) {
        final WriteBatch batch = _db.batch();
        for (final groupId in groupIds) {
          final groupRef = _db.collection('users')
              .doc(_currentUser!.uid)
              .collection('groups')
              .doc(groupId);
          batch.update(groupRef, {
            'locationIds': FieldValue.arrayRemove([id])
          });
        }
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to delete location: ${e.toString()}');
    }
  }

  Future<void> deleteLocations(List<String> ids) async {
    if (_currentUser == null || ids.isEmpty) {
      return;
    }
    
    try {
      final WriteBatch batch = _db.batch();
      for (final id in ids) {
        batch.delete(_locationsCollection.doc(id));
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete locations: ${e.toString()}');
    }
  }

  // GROUPS

  CollectionReference<LocationGroup> get _groupsCollection {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }
    return _db
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('groups')
        .withConverter<LocationGroup>(
          fromFirestore: (snapshot, _) =>
              LocationGroup.fromFirestore(snapshot.id, snapshot.data()!),
          toFirestore: (group, _) => group.toFirestore(),
        );
  }

  Stream<List<LocationGroup>> getGroups() {
    return _groupsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<List<LocationGroup>> getGroupsOnce() async {
    final snapshot = await _groupsCollection.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<DocumentReference<LocationGroup>> addGroup(LocationGroup group) async {
    return await _groupsCollection.add(group);
  }

  Future<List<TravelLocation>> getLocationsForGroup(String groupId) async {
    // 1. Get the group to check for explicit order
    final groupDoc = await _groupsCollection.doc(groupId).get();
    final groupData = groupDoc.data();
    final List<String> orderedIds = groupData?.locationIds ?? [];

    // 2. Query the locations belonging to this group
    final snapshot = await _locationsCollection
        .where('groupIds', arrayContains: groupId)
        .get();
    
    final locations = snapshot.docs.map((doc) => doc.data()).toList();

    if (orderedIds.isNotEmpty) {
      // 3. Sort based on orderedIds list
      final Map<String, TravelLocation> locMap = {
        for (var loc in locations) loc.firestoreId!: loc
      };
      
      final List<TravelLocation> sorted = [];
      // Add items that are in orderedIds in that order
      for (var id in orderedIds) {
        if (locMap.containsKey(id)) {
          sorted.add(locMap[id]!);
          locMap.remove(id);
        }
      }
      // Add any remaining items (that might not be in the list yet) by creation date
      final remaining = locMap.values.toList();
      remaining.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
      sorted.addAll(remaining);
      
      return sorted;
    } else {
      // Fallback: Sort by createdAt
      locations.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
      return locations;
    }
  }

  Future<void> updateGroupLocationOrder(String groupId, List<String> locationIds) async {
    try {
      await _groupsCollection.doc(groupId).update({'locationIds': locationIds});
    } catch (e) {
      throw Exception('Failed to update group order: ${e.toString()}');
    }
  }

  Future<void> updateGroup(String id, LocationGroup group) async {
    await _groupsCollection.doc(id).update(group.toFirestore());
  }

  Future<void> deleteGroup(String id) async {
    // Delete all locations associated with this group.
    // Note: locations store group membership in the `groupIds` array.
    final locationsToDelete = await _locationsCollection
        .where('groupIds', arrayContains: id)
        .get();
    if (locationsToDelete.docs.isNotEmpty) {
      final WriteBatch batch = _db.batch();
      for (final doc in locationsToDelete.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    // Then delete the group itself
    await _groupsCollection.doc(id).delete();
  }

  // ROUTES

  CollectionReference<TravelRoute> get _routesCollection {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }
    return _db
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('routes')
        .withConverter<TravelRoute>(
          fromFirestore: (snapshot, _) =>
              TravelRoute.fromFirestore(snapshot.id, snapshot.data()!),
          toFirestore: (route, _) => route.toFirestore(),
        );
  }

  CollectionReference<TravelRoute> get _communityRoutesCollection => _db
      .collection('community_routes')
      .withConverter<TravelRoute>(
        fromFirestore: (snapshot, _) =>
            TravelRoute.fromFirestore(snapshot.id, snapshot.data()!),
        toFirestore: (route, _) => route.toFirestore(),
      );

  Stream<List<TravelRoute>> getRoutes() {
    return _routesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // This method is added to allow manual refreshing of the user routes stream
  // by triggering a new snapshot event.
  Future<void> forceRefreshUserRoutesStream() async {
    if (_currentUser == null) return;
    // Perform a simple query to trigger a new snapshot event for listeners
    await _routesCollection.limit(1).get();
  }

  Stream<List<TravelRoute>> getCommunityRoutes() {
    return _communityRoutesCollection
        .where('isShared', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<TravelRoute>> getCommunityRoutesOnce() async {
    final snapshot = await _communityRoutesCollection
        .where('isShared', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.server));
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<TravelRoute?> getDownloadedCommunityRoute(
    String communityRouteId,
  ) async {
    if (_currentUser == null) return null;
    final snapshot = await _routesCollection
        .where('communityRouteId', isEqualTo: communityRouteId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }

  Future<void> shareRoute(String routeId, bool isShared) async {
    if (_currentUser == null) throw Exception('User not logged in');

    final originalRouteDoc = _routesCollection.doc(routeId);

    if (isShared) {
      // Share the route
      final routeSnapshot = await originalRouteDoc.get();
      final routeData = routeSnapshot.data();
      if (routeData != null) {
        // Fetch the locations for the route
        final locations = await getLocationsByIds(routeData.locationIds);
        final locationMaps = locations.map((loc) => loc.toFirestore()).toList();

        final userProfile = await getUserProfile().first;
        final userName = userProfile?.getPublicDisplayName() ?? 'Anonymous';

        final sharedRoute = routeData.copyWith(
          isShared: true,
          sharedBy: _currentUser!.uid,
          authorName: userName,
          locations: locationMaps,
        );
        await _communityRoutesCollection.doc(routeId).set(sharedRoute);
        await originalRouteDoc.update({
          'isShared': true,
          'sharedBy': _currentUser!.uid,
        });
      }
    } else {
      // Unshare the route. The subcollections (comments/ratings) are removed
      // by the Cloud Function because a client cannot delete other users'
      // comments/ratings directly (and cannot forge counter updates).
      try {
        final idToken = await _idToken();
        if (idToken == null) throw Exception('User not authenticated');

        final response = await http.get(
          Uri.parse(
            '$_functionsBase/unshareRoute?routeId='
            '${Uri.encodeComponent(routeId)}',
          ),
          headers: {'Authorization': 'Bearer $idToken'},
        );
        if (response.statusCode != 200) {
          throw Exception(
            'Failed to unshare route: ${response.statusCode}',
          );
        }

        await originalRouteDoc.update({'isShared': false, 'sharedBy': null});
      } catch (e, s) {
        if (!kIsWeb) {
          FirebaseCrashlytics.instance.recordError(
            e,
            s,
            reason: 'Error un-sharing route: $routeId',
          );
        }
        // Re-throw the exception to be handled by the caller if needed
        rethrow;
      }
    }
  }

  Future<List<TravelRoute>> getRoutesOnce() async {
    final snapshot = await _routesCollection
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<DocumentReference<TravelRoute>> addRoute(TravelRoute route) async {
    try {
      return await _routesCollection.add(route);
    } catch (e) {
      throw Exception('Failed to save route: ${e.toString()}');
    }
  }

  Future<void> updateRoute(String routeId, TravelRoute route) async {
    try {
      await _routesCollection.doc(routeId).update(route.toFirestore());
    } catch (e) {
      throw Exception('Failed to update route: ${e.toString()}');
    }
  }

  Future<void> deleteRoute(String routeId) async {
    // Also delete from community if it's shared
    await _communityRoutesCollection
        .doc(routeId)
        .delete()
        .catchError((_) => {});
    await _routesCollection.doc(routeId).delete();
  }

  // RATINGS AND COMMENTS

  Future<void> addOrUpdateRating(String routeId, double rating) async {
    if (_currentUser == null) throw Exception('User not logged in');
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    final idToken = await _idToken();
    if (idToken == null) throw Exception('User not authenticated');

    // Ratings are written by the Cloud Function so the average/count are
    // computed atomically on the server and cannot be forged by clients.
    final response = await http.get(
      Uri.parse(
        '$_functionsBase/rateRoute?routeId='
        '${Uri.encodeComponent(routeId)}&rating=$rating',
      ),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to rate route: ${response.statusCode}');
    }
  }

  Future<double?> getUserRating(String routeId) async {
    if (_currentUser == null) return null;
    try {
      final ratingDoc = await _communityRoutesCollection
          .doc(routeId)
          .collection('ratings')
          .doc(_currentUser!.uid)
          .get();
      if (ratingDoc.exists) {
        return ratingDoc.data()?['rating'] as double?;
      }
      return null;
    } catch (e, s) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          s,
          reason: 'Error getting user rating for route: $routeId',
        );
      }
      return null;
    }
  }

  Future<void> addComment(String routeId, String comment) async {
    if (_currentUser == null) throw Exception('User not logged in');

    final idToken = await _idToken();
    if (idToken == null) throw Exception('User not authenticated');

    // Comments are created by the Cloud Function so the content is validated
    // server-side and the commentCount is incremented atomically.
    final response = await http.post(
      Uri.parse('$_functionsBase/addComment'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: convert.jsonEncode({'routeId': routeId, 'comment': comment}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add comment: ${response.statusCode}');
    }
  }

  Stream<List<RouteComment>> getComments(String routeId) {
    return _communityRoutesCollection
        .doc(routeId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RouteComment.fromMap(doc.data()))
              .toList(),
        );
  }

  // REACHED LOCATION LOGS

  CollectionReference<ReachedLocationLog> get _reachedLogsCollection {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }
    return _db
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('reached_logs')
        .withConverter<ReachedLocationLog>(
          fromFirestore: (snapshot, _) =>
              ReachedLocationLog.fromFirestore(snapshot),
          toFirestore: (log, _) => log.toFirestore(),
        );
  }

  Future<String?> addReachedLocationLog(ReachedLocationLog log) async {
    try {
      final docRef = await _reachedLogsCollection.add(log);
      return docRef.id;
    } catch (e, s) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          s,
          reason: 'Error adding reached location log',
        );
      }
      return null;
    }
  }

  Stream<List<ReachedLocationLog>> getReachedLocationLogs() {
    return _reachedLogsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  Future<void> updateReachedLocationLog(
    String id, {
    required bool isRead,
  }) async {
    await _reachedLogsCollection.doc(id).update({'isRead': isRead});
  }

  Future<void> deleteReadLogs() async {
    final snapshot = await _reachedLogsCollection
        .where('isRead', isEqualTo: true)
        .get();
    WriteBatch batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> markAllLogsAsRead() async {
    final snapshot = await _reachedLogsCollection
        .where('isRead', isEqualTo: false)
        .get();
    WriteBatch batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> markAllLogsAsUnread() async {
    final snapshot = await _reachedLogsCollection
        .where('isRead', isEqualTo: true)
        .get();
    WriteBatch batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': false});
    }
    await batch.commit();
  }

  // USER PROFILE

  DocumentReference<UserProfile> get _userProfileDoc {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }
    return _db
        .collection('users')
        .doc(_currentUser!.uid)
        .withConverter<UserProfile>(
          fromFirestore: (snapshot, _) => UserProfile.fromFirestore(snapshot),
          toFirestore: (profile, _) => profile.toFirestore(),
        );
  }

  Stream<UserProfile?> getUserProfile() {
    if (_currentUser == null) return Stream.value(null);
    return _userProfileDoc.snapshots().map((snapshot) => snapshot.data());
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _userProfileDoc.set(profile, SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      final docSnapshot = await _db.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return UserProfile.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e, s) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          s,
          reason: 'Error getting user profile by ID: $userId',
        );
      }
      return null;
    }
  }

  Future<Map<String, UserProfile>> getUsersProfilesByIds(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    final Map<String, UserProfile> profiles = {};

    try {
      // Firestore 'whereIn' query has a limit of 10 elements per query.
      const chunkSize = 10;
      for (var i = 0; i < userIds.length; i += chunkSize) {
        final chunk = userIds.sublist(
          i,
          i + chunkSize > userIds.length ? userIds.length : i + chunkSize,
        );

        if (chunk.isEmpty) continue;

        final snapshot = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .withConverter<UserProfile>(
              fromFirestore: (snapshot, _) => UserProfile.fromFirestore(snapshot),
              toFirestore: (profile, _) => profile.toFirestore(),
            )
            .get();

        for (var doc in snapshot.docs) {
          profiles[doc.id] = doc.data();
        }
      }
      return profiles;
    } catch (e, s) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          s,
          reason: 'Error getting user profiles by IDs',
        );
      }
      return {};
    }
  }

  // FCM TOKENS
  // Tokens are stored in their own owner-only collection so they are never
  // exposed through the publicly-readable /users profile documents.

  Future<void> saveFcmToken(String token) async {
    if (_currentUser == null) return;
    await _db.collection('user_tokens').doc(_currentUser!.uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> getFcmToken() async {
    if (_currentUser == null) return null;
    final doc = await _db.collection('user_tokens').doc(_currentUser!.uid).get();
    return doc.data()?['fcmToken'] as String?;
  }

  Future<void> clearFcmToken() async {
    if (_currentUser == null) return;
    await _db.collection('user_tokens').doc(_currentUser!.uid).set({
      'fcmToken': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Deletes ALL of the signed-in user's data (personal data, FCM token,
  /// shared community routes, comments/ratings, profile images). The server
  /// side runs with the admin SDK so it can clean up content that client rules
  /// would block. Throws on failure; deletes are idempotent so retrying is safe.
  Future<void> deleteUserData() async {
    if (_currentUser == null) throw Exception('User not logged in');

    final idToken = await _idToken();
    if (idToken == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('$_functionsBase/deleteUserData'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user data: ${response.statusCode}');
    }
  }
}
