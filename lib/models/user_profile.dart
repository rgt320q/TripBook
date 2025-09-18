import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? name; // Renamed from username
  final String? languageCode;
  final GeoPoint? homeLocation;
  final String? fcmToken;

  UserProfile({
    required this.uid,
    this.name,
    this.languageCode,
    this.homeLocation,
    this.fcmToken,
  });

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return UserProfile(
      uid: snapshot.id,
      name: data['name'] as String?,
      languageCode: data['languageCode'] as String?,
      homeLocation: data['homeLocation'] as GeoPoint?,
      fcmToken: data['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) 'name': name,
      if (languageCode != null) 'languageCode': languageCode,
      if (homeLocation != null) 'homeLocation': homeLocation,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? languageCode,
    GeoPoint? homeLocation,
    String? fcmToken,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      languageCode: languageCode ?? this.languageCode,
      homeLocation: homeLocation ?? this.homeLocation,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
