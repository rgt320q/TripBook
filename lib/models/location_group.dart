import 'package:cloud_firestore/cloud_firestore.dart';

class LocationGroup {
  final String? firestoreId;
  final String name;
  final int? color; // Added color field
  final DateTime? createdAt;
  final String userId;
  final List<String> locationIds;

  LocationGroup({
    this.firestoreId,
    required this.name,
    this.color,
    this.createdAt,
    required this.userId,
    this.locationIds = const [],
  }); // Updated constructor

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'color': color, // Added color to Firestore map
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'userId': userId,
      'locationIds': locationIds,
    };
  }

  factory LocationGroup.fromFirestore(
    String id,
    Map<String, dynamic> firestoreMap,
  ) {
    return LocationGroup(
      firestoreId: id,
      name: firestoreMap['name'] as String,
      color: firestoreMap['color'] as int?,
      createdAt: (firestoreMap['createdAt'] as Timestamp?)?.toDate(),
      userId: firestoreMap['userId'] as String? ?? '', // Handle old data without userId
      locationIds: List<String>.from(firestoreMap['locationIds'] ?? []),
    );
  }

  LocationGroup copyWith({
    String? firestoreId,
    String? name,
    int? color,
    DateTime? createdAt,
    String? userId,
    List<String>? locationIds,
  }) {
    return LocationGroup(
      firestoreId: firestoreId ?? this.firestoreId,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      locationIds: locationIds ?? this.locationIds,
    );
  }
}
