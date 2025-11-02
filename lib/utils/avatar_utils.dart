class AvatarUtils {
  // Mevcut avatarların listesi
  static const List<String> availableAvatars = [
    'assets/avatars/traveler_1.svg',
    'assets/avatars/hiker_2.svg',
    'assets/avatars/photographer_3.svg',
    'assets/avatars/explorer_4.svg',
    'assets/avatars/cyclist_5.svg',
    'assets/avatars/camper_6.svg',
    'assets/avatars/beach_7.svg',
    'assets/avatars/tourist_8.svg',
    'assets/avatars/driver_9.svg',
    'assets/avatars/guide_10.svg',
  ];

  // Avatar açıklamaları
  static const Map<String, String> avatarDescriptions = {
    'assets/avatars/traveler_1.svg': '🎒 Seyahatçi - Çantasında haritası olan deneyimli gezgin',
    'assets/avatars/hiker_2.svg': '⛰️ Dağcı - Yürüyüş sopasıyla dağları keşfeden maceracı',
    'assets/avatars/photographer_3.svg': '📸 Fotoğrafçı - Her anı ölümsüzleştiren sanat aşığı',
    'assets/avatars/explorer_4.svg': '🧭 Kaşif - Pusulayla yol bulan keşif uzmanı',
    'assets/avatars/cyclist_5.svg': '🚴 Bisikletçi - İki tekerle dünyayı gezen sporcu',
    'assets/avatars/camper_6.svg': '🏕️ Kampçı - Doğayla iç içe geceleme uzmanı',
    'assets/avatars/beach_7.svg': '🏖️ Plaj Seyahatçisi - Güneş, kum ve deniz severler için',
    'assets/avatars/tourist_8.svg': '🏙️ Şehir Turistı - Büyük şehirleri keşfeden kentli',
    'assets/avatars/driver_9.svg': '🚗 Yol Serüvencisi - Arabayla sınırsız özgürlük',
    'assets/avatars/guide_10.svg': '🌲 Rehber - Doğayı bilen, yol gösteren uzman',
  };

  // Avatar adları (kısa)
  static const Map<String, String> avatarNames = {
    'assets/avatars/traveler_1.svg': 'Seyahatçi',
    'assets/avatars/hiker_2.svg': 'Dağcı',
    'assets/avatars/photographer_3.svg': 'Fotoğrafçı',
    'assets/avatars/explorer_4.svg': 'Kaşif',
    'assets/avatars/cyclist_5.svg': 'Bisikletçi',
    'assets/avatars/camper_6.svg': 'Kampçı',
    'assets/avatars/beach_7.svg': 'Plaj Severler',
    'assets/avatars/tourist_8.svg': 'Şehir Turistı',
    'assets/avatars/driver_9.svg': 'Yol Serüvencisi',
    'assets/avatars/guide_10.svg': 'Rehber',
  };

  /// Varsayılan avatar path'i döndürür
  static String getDefaultAvatar() {
    return availableAvatars.first;
  }

  /// Avatar path'inin geçerli olup olmadığını kontrol eder
  static bool isValidAvatar(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return false;
    return availableAvatars.contains(avatarPath);
  }

  /// Geçerli olmayan avatar path'i için varsayılan avatar döndürür
  static String validateAvatarPath(String? avatarPath) {
    if (isValidAvatar(avatarPath)) {
      return avatarPath!;
    }
    return getDefaultAvatar();
  }

  /// Avatar için açıklama döndürür
  static String getAvatarDescription(String avatarPath) {
    return avatarDescriptions[avatarPath] ?? 'Bilinmeyen avatar';
  }

  /// Avatar için kısa ad döndürür
  static String getAvatarName(String avatarPath) {
    return avatarNames[avatarPath] ?? 'Bilinmeyen';
  }
}