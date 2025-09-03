import 'package:cloud_firestore/cloud_firestore.dart';

class ReachedLocationLog {
  final String? id;
  final String locationName;
  final String geoName;
  final String infoUrl;
  final Timestamp timestamp;
  final bool isRead;
  final String userId;

  ReachedLocationLog({
    this.id,
    required this.locationName,
    required this.geoName,
    required this.infoUrl,
    required this.timestamp,
    this.isRead = false,
    required this.userId,
  });

  factory ReachedLocationLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReachedLocationLog(
      id: doc.id,
      locationName: data['locationName'] ?? '',
      geoName: data['geoName'] ?? data['locationName'] ?? '',
      infoUrl: data['infoUrl'] ?? data['wikipediaUrl'] ?? '', // Fallback for old data
      timestamp: data['timestamp'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'locationName': locationName,
      'geoName': geoName,
      'infoUrl': infoUrl,
      'timestamp': timestamp,
      'isRead': isRead,
      'userId': userId,
    };
  }
}