import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? name; // Deprecated, use fullName instead
  final String? firstName; // Deprecated, use fullName instead
  final String? lastName; // Deprecated, use fullName instead
  final String? fullName; // Gerçek ad soyad
  final String? nickname; // Takma isim / kullanıcı adı
  final String? phone;
  final String? bio;
  final String? languageCode;
  final GeoPoint? homeLocation;
  final Timestamp? birthDate;
  final String? gender;
  final String? profileImageUrl; // Firebase Storage URL'i - artık kullanılmıyor
  final bool hasLocalProfileImage; // Lokal profil resmi var mı? - artık kullanılmıyor
  final String? selectedAvatarPath; // Seçili pixel art avatar path'i
  final bool showFullNameInPublic; // Gerçek adı herkese göster
  final bool showNicknameInPublic; // Takma ismi herkese göster
  final String displayNameInPublic; // Paylaşımlarda hangi isim görünecek: 'fullName' veya 'nickname'
  final bool showBioInPublic; // Bioyu herkese göster
  final bool showProfileImageInPublic; // Profil resmini herkese göster
  final bool showPhoneInPublic; // Telefonu herkese göster
  final bool showBirthDateInPublic; // Doğum tarihini herkese göster
  final bool showGenderInPublic; // Cinsiyeti herkese göster

  UserProfile({
    required this.uid,
    this.name,
    this.firstName,
    this.lastName,
    this.fullName,
    this.nickname,
    this.phone,
    this.bio,
    this.languageCode,
    this.homeLocation,
    this.birthDate,
    this.gender,
    this.profileImageUrl,
    this.hasLocalProfileImage = false,
    this.selectedAvatarPath,
    this.showFullNameInPublic = true,
    this.showNicknameInPublic = true,
    this.displayNameInPublic = 'nickname', // Default olarak nickname göster
    this.showBioInPublic = false,
    this.showProfileImageInPublic = true,
    this.showPhoneInPublic = false,
    this.showBirthDateInPublic = false,
    this.showGenderInPublic = false,
  });

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return UserProfile(
      uid: snapshot.id,
      name: data['name'] as String?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      fullName: data['fullName'] as String?,
      nickname: data['nickname'] as String?,
      phone: data['phone'] as String?,
      bio: data['bio'] as String?,
      languageCode: data['languageCode'] as String?,
      homeLocation: data['homeLocation'] as GeoPoint?,
      birthDate: data['birthDate'] as Timestamp?,
      gender: data['gender'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      hasLocalProfileImage: data['hasLocalProfileImage'] as bool? ?? false,
      selectedAvatarPath: data['selectedAvatarPath'] as String?,
      showFullNameInPublic: data['showFullNameInPublic'] as bool? ?? 
          (data['showFirstNameInPublic'] as bool? ?? true), // Migration için eski değeri kontrol et
      showNicknameInPublic: data['showNicknameInPublic'] as bool? ?? true,
      displayNameInPublic: data['displayNameInPublic'] as String? ?? 'nickname',
      showBioInPublic: data['showBioInPublic'] as bool? ?? false,
      showProfileImageInPublic: data['showProfileImageInPublic'] as bool? ?? true,
      showPhoneInPublic: data['showPhoneInPublic'] as bool? ?? false,
      showBirthDateInPublic: data['showBirthDateInPublic'] as bool? ?? false,
      showGenderInPublic: data['showGenderInPublic'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) 'name': name,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (fullName != null) 'fullName': fullName,
      if (nickname != null) 'nickname': nickname,
      if (phone != null) 'phone': phone,
      if (bio != null) 'bio': bio,
      if (languageCode != null) 'languageCode': languageCode,
      if (homeLocation != null) 'homeLocation': homeLocation,
      if (birthDate != null) 'birthDate': birthDate,
      if (gender != null) 'gender': gender,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      'hasLocalProfileImage': hasLocalProfileImage,
      if (selectedAvatarPath != null) 'selectedAvatarPath': selectedAvatarPath,
      'showFullNameInPublic': showFullNameInPublic,
      'showNicknameInPublic': showNicknameInPublic,
      'displayNameInPublic': displayNameInPublic,
      'showBioInPublic': showBioInPublic,
      'showProfileImageInPublic': showProfileImageInPublic,
      'showPhoneInPublic': showPhoneInPublic,
      'showBirthDateInPublic': showBirthDateInPublic,
      'showGenderInPublic': showGenderInPublic,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? firstName,
    String? lastName,
    String? fullName,
    String? nickname,
    String? phone,
    String? bio,
    String? languageCode,
    GeoPoint? homeLocation,
    Timestamp? birthDate,
    String? gender,
    String? profileImageUrl,
    bool? hasLocalProfileImage,
    String? selectedAvatarPath,
    bool? showFullNameInPublic,
    bool? showNicknameInPublic,
    String? displayNameInPublic,
    bool? showBioInPublic,
    bool? showProfileImageInPublic,
    bool? showPhoneInPublic,
    bool? showBirthDateInPublic,
    bool? showGenderInPublic,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      languageCode: languageCode ?? this.languageCode,
      homeLocation: homeLocation ?? this.homeLocation,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      hasLocalProfileImage: hasLocalProfileImage ?? this.hasLocalProfileImage,
      selectedAvatarPath: selectedAvatarPath ?? this.selectedAvatarPath,
      showFullNameInPublic: showFullNameInPublic ?? this.showFullNameInPublic,
      showNicknameInPublic: showNicknameInPublic ?? this.showNicknameInPublic,
      displayNameInPublic: displayNameInPublic ?? this.displayNameInPublic,
      showBioInPublic: showBioInPublic ?? this.showBioInPublic,
      showProfileImageInPublic: showProfileImageInPublic ?? this.showProfileImageInPublic,
      showPhoneInPublic: showPhoneInPublic ?? this.showPhoneInPublic,
      showBirthDateInPublic: showBirthDateInPublic ?? this.showBirthDateInPublic,
      showGenderInPublic: showGenderInPublic ?? this.showGenderInPublic,
    );
  }
  
  /// Herkese açık olan bilgileri döndür
  UserProfile getPublicProfile() {
    return UserProfile(
      uid: uid,
      name: name, // Backward compatibility için tutuyoruz
      firstName: firstName, // Deprecated ama migration için tutuyoruz
      lastName: lastName, // Deprecated ama migration için tutuyoruz
      fullName: showFullNameInPublic ? fullName : null,
      nickname: showNicknameInPublic ? nickname : null,
      phone: showPhoneInPublic ? phone : null,
      bio: showBioInPublic ? bio : null,
      birthDate: showBirthDateInPublic ? birthDate : null,
      gender: showGenderInPublic ? gender : null,
      selectedAvatarPath: showProfileImageInPublic ? selectedAvatarPath : null,
      hasLocalProfileImage: false, // Artık kullanılmıyor
      displayNameInPublic: displayNameInPublic,
      showFullNameInPublic: showFullNameInPublic,
      showNicknameInPublic: showNicknameInPublic,
      showBioInPublic: showBioInPublic,
      showProfileImageInPublic: showProfileImageInPublic,
      showPhoneInPublic: showPhoneInPublic,
      showBirthDateInPublic: showBirthDateInPublic,
      showGenderInPublic: showGenderInPublic,
    );
  }
  
  /// Gösterilecek ismi döndür (öncelik sırası: nickname > fullName > firstName lastName > name)
  String getDisplayName() {
    if (nickname?.isNotEmpty == true) {
      return nickname!;
    }
    
    if (fullName?.isNotEmpty == true) {
      return fullName!;
    }
    
    // Migration için eski firstName/lastName alanlarını kontrol et
    final firstName = this.firstName?.trim();
    final lastName = this.lastName?.trim();
    
    if (firstName?.isNotEmpty == true && lastName?.isNotEmpty == true) {
      return '$firstName $lastName';
    } else if (firstName?.isNotEmpty == true) {
      return firstName!;
    } else if (lastName?.isNotEmpty == true) {
      return lastName!;
    }
    
    return name?.isNotEmpty == true ? name! : 'Anonim Kullanıcı';
  }
  
  /// Herkese açık gösterilecek ismi döndür (displayNameInPublic ayarına göre)
  String getPublicDisplayName() {
    // Kullanıcının tercihine göre hangi ismi göstereceğini belirle
    if (displayNameInPublic == 'fullName') {
      if (showFullNameInPublic && fullName?.isNotEmpty == true) {
        return fullName!;
      }
      // Fallback: Migration için eski alanları kontrol et
      final firstName = this.firstName?.trim();
      final lastName = this.lastName?.trim();
      
      if (firstName?.isNotEmpty == true && lastName?.isNotEmpty == true) {
        return '$firstName $lastName';
      } else if (firstName?.isNotEmpty == true) {
        return firstName!;
      } else if (lastName?.isNotEmpty == true) {
        return lastName!;
      }
    } else {
      // displayNameInPublic == 'nickname' veya default
      if (showNicknameInPublic && nickname?.isNotEmpty == true) {
        return nickname!;
      }
    }
    
    return 'Anonim Kullanıcı';
  }
}
