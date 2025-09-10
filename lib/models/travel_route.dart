import 'package:cloud_firestore/cloud_firestore.dart';

class TravelRoute {
  final String? firestoreId;
  final String name;
  final List<String> locationIds;
  final String totalTravelTime;
  final String totalDistance;
  final DateTime? createdAt;
  final String? actualDuration;
  final String? actualDistance;

  final String? totalStopDuration;
  final String? totalTripDuration;
  final List<String>? needs;
  final List<Map<String, String>>? notes;

  // Fields for sharing and rating
  final bool isShared;
  final String? sharedBy;
  final double averageRating;
  final int ratingCount;
  final int commentCount;

  TravelRoute({
    this.firestoreId,
    required this.name,
    required this.locationIds,
    required this.totalTravelTime,
    required this.totalDistance,
    this.createdAt,
    this.actualDuration,
    this.actualDistance,
    this.totalStopDuration,
    this.totalTripDuration,
    this.needs,
    this.notes,
    this.isShared = false,
    this.sharedBy,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.commentCount = 0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'locationIds': locationIds,
      'totalTravelTime': totalTravelTime,
      'totalDistance': totalDistance,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      if (actualDuration != null) 'actualDuration': actualDuration,
      if (actualDistance != null) 'actualDistance': actualDistance,
      if (totalStopDuration != null) 'totalStopDuration': totalStopDuration,
      if (totalTripDuration != null) 'totalTripDuration': totalTripDuration,
      if (needs != null) 'needs': needs,
      if (notes != null) 'notes': notes,
      'isShared': isShared,
      'sharedBy': sharedBy,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'commentCount': commentCount,
    };
  }

  TravelRoute copyWith({
    String? firestoreId,
    String? name,
    List<String>? locationIds,
    String? totalTravelTime,
    String? totalDistance,
    DateTime? createdAt,
    String? actualDuration,
    String? actualDistance,
    String? totalStopDuration,
    String? totalTripDuration,
    List<String>? needs,
    List<Map<String, String>>? notes,
    bool? isShared,
    String? sharedBy,
    double? averageRating,
    int? ratingCount,
    int? commentCount,
  }) {
    return TravelRoute(
      firestoreId: firestoreId ?? this.firestoreId,
      name: name ?? this.name,
      locationIds: locationIds ?? this.locationIds,
      totalTravelTime: totalTravelTime ?? this.totalTravelTime,
      totalDistance: totalDistance ?? this.totalDistance,
      createdAt: createdAt ?? this.createdAt,
      actualDuration: actualDuration ?? this.actualDuration,
      actualDistance: actualDistance ?? this.actualDistance,
      totalStopDuration: totalStopDuration ?? this.totalStopDuration,
      totalTripDuration: totalTripDuration ?? this.totalTripDuration,
      needs: needs ?? this.needs,
      notes: notes ?? this.notes,
      isShared: isShared ?? this.isShared,
      sharedBy: sharedBy ?? this.sharedBy,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  factory TravelRoute.fromFirestore(String id, Map<String, dynamic> firestoreMap) {
    return TravelRoute(
      firestoreId: id,
      name: firestoreMap['name'] as String,
      locationIds: List<String>.from(firestoreMap['locationIds']),
      totalTravelTime: firestoreMap['totalTravelTime'] as String,
      totalDistance: firestoreMap['totalDistance'] as String,
      createdAt: (firestoreMap['createdAt'] as Timestamp?)?.toDate(),
      actualDuration: firestoreMap['actualDuration'] as String?,
      actualDistance: firestoreMap['actualDistance'] as String?,
      totalStopDuration: firestoreMap['totalStopDuration'] as String?,
      totalTripDuration: firestoreMap['totalTripDuration'] as String?,
      needs: firestoreMap['needs'] != null ? List<String>.from(firestoreMap['needs']) : null,
      notes: firestoreMap['notes'] != null
          ? List<Map<String, String>>.from(
              (firestoreMap['notes'] as List).map((item) => Map<String, String>.from(item))
            )
          : null,
      isShared: firestoreMap['isShared'] as bool? ?? false,
      sharedBy: firestoreMap['sharedBy'] as String?,
      averageRating: (firestoreMap['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: firestoreMap['ratingCount'] as int? ?? 0,
      commentCount: firestoreMap['commentCount'] as int? ?? 0,
    );
  }
}