import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

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
          fromFirestore: (snapshots, _) => TravelLocation.fromFirestore(snapshots.id, snapshots.data()!),
          toFirestore: (location, _) => location.toFirestore(),
        );
  }

  Future<void> addLocation(TravelLocation location) async {
    await _locationsCollection.add(location);
  }

  Future<List<String>> addLocations(List<TravelLocation> locations) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }
    final WriteBatch batch = _db.batch();
    final List<String> newIds = [];

    for (final location in locations) {
      final newDocRef = _locationsCollection.doc();
      batch.set(newDocRef, location);
      newIds.add(newDocRef.id);
    }

    await batch.commit();
    return newIds;
  }

  Stream<List<TravelLocation>> getLocations() {
    return _locationsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<List<TravelLocation>> getLocationsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await _locationsCollection.where(FieldPath.documentId, whereIn: ids).get();
    final locationsMap = {for (var doc in snapshot.docs) doc.id: doc.data()};
    // Order the results based on the original ID list
    return ids.map((id) => locationsMap[id]).where((loc) => loc != null).cast<TravelLocation>().toList();
  }

  Future<void> updateLocation(String id, TravelLocation location) async {
    await _locationsCollection.doc(id).update(location.toFirestore());
  }

  Future<void> updateLocationNeeds(String docId, List<Map<String, dynamic>> needs) async {
    await _locationsCollection.doc(docId).update({'needsList': needs});
  }

  Future<void> deleteLocation(String id) async {
    await _locationsCollection.doc(id).delete();
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
          fromFirestore: (snapshot, _) => LocationGroup.fromFirestore(snapshot.id, snapshot.data()!),
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

  Future<void> addGroup(LocationGroup group) async {
    await _groupsCollection.add(group);
  }

  Future<List<TravelLocation>> getLocationsForGroup(String groupId) async {
    final snapshot = await _locationsCollection.where('groupId', isEqualTo: groupId).snapshots().first;
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> updateGroup(String id, LocationGroup group) async {
    await _groupsCollection.doc(id).update(group.toFirestore());
  }

  Future<void> deleteGroup(String id) async {
    // Delete all locations associated with this group
    final locationsToDelete = await _locationsCollection.where('groupId', isEqualTo: id).get();
    for (final doc in locationsToDelete.docs) {
      await doc.reference.delete();
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
          fromFirestore: (snapshot, _) => TravelRoute.fromFirestore(snapshot.id, snapshot.data()!),
          toFirestore: (route, _) => route.toFirestore(),
        );
  }

  CollectionReference<TravelRoute> get _communityRoutesCollection => _db.collection('community_routes').withConverter<TravelRoute>(
        fromFirestore: (snapshot, _) => TravelRoute.fromFirestore(snapshot.id, snapshot.data()!),
        toFirestore: (route, _) => route.toFirestore(),
      );

  Stream<List<TravelRoute>> getRoutes() {
    return _routesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<TravelRoute>> getCommunityRoutes() {
    return _communityRoutesCollection
        .where('isShared', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<TravelRoute?> getDownloadedCommunityRoute(String communityRouteId) async {
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

        final sharedRoute = routeData.copyWith(
          isShared: true,
          sharedBy: _currentUser!.uid,
          locations: locationMaps,
        );
        await _communityRoutesCollection.doc(routeId).set(sharedRoute);
        await originalRouteDoc.update({'isShared': true, 'sharedBy': _currentUser!.uid});
      }
    } else {
      // Unshare the route
      await _communityRoutesCollection.doc(routeId).delete();
      await originalRouteDoc.update({'isShared': false, 'sharedBy': null});
    }
  }

  Future<List<TravelRoute>> getRoutesOnce() async {
    final snapshot = await _routesCollection.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<DocumentReference<TravelRoute>> addRoute(TravelRoute route) async {
    return await _routesCollection.add(route);
  }

  Future<void> updateRoute(String routeId, TravelRoute route) async {
    await _routesCollection.doc(routeId).update(route.toFirestore());
  }

  Future<void> deleteRoute(String routeId) async {
    // Also delete from community if it's shared
    await _communityRoutesCollection.doc(routeId).delete().catchError((_) => {});
    await _routesCollection.doc(routeId).delete();
  }

  // RATINGS AND COMMENTS

  Future<void> addOrUpdateRating(String routeId, double rating) async {
    if (_currentUser == null) throw Exception('User not logged in');
    final userId = _currentUser!.uid;

    final ratingDoc = _communityRoutesCollection.doc(routeId).collection('ratings').doc(userId);
    await ratingDoc.set({'rating': rating});

    // Update average rating on the main route document
    final ratingsSnapshot = await _communityRoutesCollection.doc(routeId).collection('ratings').get();
    final ratings = ratingsSnapshot.docs.map((doc) => doc.data()['rating'] as double).toList();
    final double averageRating = ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0.0;
    final int ratingCount = ratings.length;

    await _communityRoutesCollection.doc(routeId).update({
      'averageRating': averageRating,
      'ratingCount': ratingCount,
    });
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
    } catch (e) {
      print('Error getting user rating: $e');
      return null;
    }
  }

  Future<void> addComment(String routeId, String comment) async {
    if (_currentUser == null) throw Exception('User not logged in');
    final userProfile = await getUserProfile().first;
    final userName = userProfile?.name ?? 'Anonymous';

    final routeRef = _communityRoutesCollection.doc(routeId);
    final commentCollection = routeRef.collection('comments');

    // Add the comment
    await commentCollection.add({
      'userId': _currentUser!.uid,
      'userName': userName,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Atomically increment the comment count
    await routeRef.update({'commentCount': FieldValue.increment(1)});
  }

  Stream<List<RouteComment>> getComments(String routeId) {
    return _communityRoutesCollection
        .doc(routeId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RouteComment.fromMap(doc.data())).toList());
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
          fromFirestore: (snapshot, _) => ReachedLocationLog.fromFirestore(snapshot),
          toFirestore: (log, _) => log.toFirestore(),
        );
  }

  Future<String?> addReachedLocationLog(ReachedLocationLog log) async {
    try {
      final docRef = await _reachedLogsCollection.add(log);
      return docRef.id;
    } catch (e) {
      // TODO: Add proper logging for database errors
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

  Future<void> updateReachedLocationLog(String id, {required bool isRead}) async {
    await _reachedLogsCollection.doc(id).update({'isRead': isRead});
  }

  Future<void> deleteReadLogs() async {
    final snapshot = await _reachedLogsCollection.where('isRead', isEqualTo: true).get();
    WriteBatch batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> markAllLogsAsRead() async {
    final snapshot = await _reachedLogsCollection.where('isRead', isEqualTo: false).get();
    WriteBatch batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // USER PROFILE

  DocumentReference<UserProfile> get _userProfileDoc {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }
    return _db.collection('users').doc(_currentUser!.uid).withConverter<UserProfile>(
      fromFirestore: (snapshot, _) => UserProfile.fromFirestore(snapshot),
      toFirestore: (profile, _) => profile.toFirestore(),
    );
  }

  Stream<UserProfile?> getUserProfile() {
    if (_currentUser == null) return Stream.value(null);
    return _userProfileDoc.snapshots().map((snapshot) => snapshot.data());
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final dataToSave = profile.toFirestore();
    print('Saving user profile data: $dataToSave'); // DEBUG PRINT
    await _userProfileDoc.set(profile, SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      final docSnapshot = await _db.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return UserProfile.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print('Error getting user profile by ID: $e');
      return null;
    }
  }

  Future<Map<String, UserProfile>> getUsersProfilesByIds(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    try {
      final snapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .withConverter<UserProfile>(
            fromFirestore: (snapshot, _) => UserProfile.fromFirestore(snapshot),
            toFirestore: (profile, _) => profile.toFirestore(),
          )
          .get();
      
      return {for (var doc in snapshot.docs) doc.id: doc.data()};
    } catch (e) {
      print('Error getting user profiles by IDs: $e');
      return {};
    }
  }
}
