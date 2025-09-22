import 'package:cloud_firestore/cloud_firestore.dart';

class TravelLocation {
  final int? id; // Local DB id
  final String? firestoreId; // Firestore document id
  final String name; // User-defined custom name
  final String geoName; // Name from reverse geocoding
  final String? description;
  final double latitude;
  final double longitude;
  final String? groupId;
  final String? notes;
  final List<Map<String, dynamic>>? needsList;
  final int? estimatedDuration; // Duration in minutes
  final DateTime? createdAt;
  final bool isImported;
  final String userId;

  TravelLocation({
    this.id,
    this.firestoreId,
    required this.name,
    required this.geoName,
    this.description,
    required this.latitude,
    required this.longitude,
    this.groupId,
    this.notes,
    this.needsList,
    this.estimatedDuration,
    this.createdAt,
    this.isImported = false,
    required this.userId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "geoName": geoName,
      if (description != null) "description": description,
      "latitude": latitude,
      "longitude": longitude,
      "groupId": groupId,
      if (notes != null) "notes": notes,
      if (needsList != null) "needsList": needsList,
      if (estimatedDuration != null) "estimatedDuration": estimatedDuration,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'isImported': isImported,
      'userId': userId,
    };
  }

  factory TravelLocation.fromFirestore(
    String id,
    Map<String, dynamic> firestoreMap,
  ) {
    List<Map<String, dynamic>>? parsedNeeds;
    final needsData = firestoreMap['needsList'];
    if (needsData is List) {
      if (needsData.isNotEmpty && needsData.first is String) {
        // Handle old format List<String> and convert
        parsedNeeds = needsData
            .map((need) => {'name': need as String, 'checked': false})
            .toList();
      } else {
        // Handle new format List<Map<String, dynamic>>
        parsedNeeds = List<Map<String, dynamic>>.from(
          needsData.map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
    }

    return TravelLocation(
      firestoreId: id,
      name: firestoreMap['name'] as String,
      geoName:
          firestoreMap['geoName'] as String? ??
          firestoreMap['name'] as String, // Fallback for old data
      description: firestoreMap['description'] as String?,
      latitude: firestoreMap['latitude'] as double,
      longitude: firestoreMap['longitude'] as double,
      groupId: firestoreMap['groupId'] as String?,
      notes: firestoreMap['notes'] as String?,
      needsList: parsedNeeds,
      estimatedDuration: firestoreMap['estimatedDuration'] as int?,
      createdAt: (firestoreMap['createdAt'] as Timestamp?)?.toDate(),
      isImported: firestoreMap['isImported'] as bool? ?? false,
      userId: firestoreMap['userId'] as String? ?? '', // Handle old data without userId
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TravelLocation &&
        (firestoreId != null && other.firestoreId != null
            ? firestoreId == other.firestoreId
            : name == other.name &&
                  latitude == other.latitude &&
                  longitude == other.longitude);
  }

  @override
  int get hashCode {
    return firestoreId != null
        ? firestoreId.hashCode
        : Object.hash(name, latitude, longitude);
  }
}