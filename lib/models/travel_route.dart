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
    };
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
    );
  }
}