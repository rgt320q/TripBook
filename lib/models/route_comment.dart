import 'package:cloud_firestore/cloud_firestore.dart';

class RouteComment {
  final String userId;
  final String userName;
  final String comment;
  final Timestamp timestamp;

  RouteComment({
    required this.userId,
    required this.userName,
    required this.comment,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'timestamp': timestamp,
    };
  }

  factory RouteComment.fromMap(Map<String, dynamic> map) {
    return RouteComment(
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Unknown',
      comment: map['comment'] as String? ?? '',
      timestamp: map['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
