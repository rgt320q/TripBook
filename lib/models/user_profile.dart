
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? name; // Renamed from username
  final String? languageCode;
  final GeoPoint? homeLocation;

  UserProfile({
    required this.uid,
    this.name,
    this.languageCode,
    this.homeLocation,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return UserProfile(
      uid: snapshot.id,
      name: data['name'] as String?,
      languageCode: data['languageCode'] as String?,
      homeLocation: data['homeLocation'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) 'name': name,
      if (languageCode != null) 'languageCode': languageCode,
      if (homeLocation != null) 'homeLocation': homeLocation,
    };
  }
}
