// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get helloWorld => 'Merhaba Dünya!';

  @override
  String get selectGroupColor => 'Grup Rengi Seçin:';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get sortByNameAsc => 'Ada Göre (A-Z)';

  @override
  String get sortByNameDesc => 'Ada Göre (Z-A)';

  @override
  String get sortByDateNewest => 'Tarihe Göre (Yeni)';

  @override
  String get sortByDateOldest => 'Tarihe Göre (Eski)';

  @override
  String get noGroupsYet => 'Henüz bir grup oluşturulmamış.';

  @override
  String get deleteGroup => 'Grup Sil';

  @override
  String deleteGroupConfirmation(String groupName) {
    return '\'$groupName\' grubunu silmek istediğinizden emin misiniz? Bu gruba ait tüm konumlar da silinecektir.';
  }

  @override
  String get delete => 'Sil';

  @override
  String get groupName => 'Grup Adı';

  @override
  String get newGroup => 'Yeni Grup Oluştur';

  @override
  String get editGroup => 'Grup Düzenle';

  @override
  String get selectGroup => 'Grup Seç';

  @override
  String get travelGroups => 'Seyahat Grupları';

  @override
  String error(String error) {
    return 'Bir hata oluştu: $error';
  }

  @override
  String get noLocationsInGroup => 'Bu grupta henüz konum bulunmamaktadır.';

  @override
  String get profileScreenTitle => 'Kullanıcı Profili';

  @override
  String get profileEmailLabel => 'E-posta';

  @override
  String get profileUsernameLabel => 'Kullanıcı Adı';

  @override
  String get profileHomeLocationLabel => 'Ev Konumu (Enlem,Boylam)';

  @override
  String get profileLanguageLabel => 'Dil';

  @override
  String get profileSaveSuccess => 'Profil güncellendi!';

  @override
  String get profileLoadError => 'Profil yüklenemedi.';

  @override
  String get profileUsernameValidation => 'Lütfen bir kullanıcı adı girin.';

  @override
  String get createRoute => 'Rota Oluştur';

  @override
  String get savedRoutes => 'Kaydedilmiş Rotalar';

  @override
  String get reachedLocations => 'Ulaşılan Konumlar';

  @override
  String get manageLocations => 'Konumları Yönet';

  @override
  String get manageGroups => 'Grupları Yönet';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get activeRouteSummary => 'Aktif Rota Özeti';

  @override
  String get clearRoute => 'Rotayı Temizle';

  @override
  String get appTitle => 'Seyahat Defteri';

  @override
  String get createRouteDialogTitle => 'Rota Oluştur';

  @override
  String get createRouteDialogContent =>
      'Rotanızı nasıl oluşturmak istersiniz?';

  @override
  String get fromGroup => 'Gruptan Seç';

  @override
  String get manualSelection => 'Manuel Seçim';

  @override
  String get endPointDialogTitle => 'Bitiş Noktası';

  @override
  String get endPointDialogContent =>
      'Başlangıç noktası bitiş noktası olarak ayarlandı. Dilerseniz haritadan farklı bir bitiş noktası seçebilirsiniz.';

  @override
  String get selectFromMap => 'Haritadan Seç';

  @override
  String get homeLocationNotSet => 'Ev konumu ayarlanmadı';

  @override
  String get setHomeLocationTitle => 'Ev Konumunu Ayarla';

  @override
  String get setHomeLocationContent =>
      'Bu konumu eviniz olarak ayarlamak ister misiniz?';

  @override
  String get selectLocation => 'Konum Seç';

  @override
  String get continueButton => 'Devam Et';

  @override
  String get selectNewEndpoint =>
      'Lütfen haritadan yeni bir bitiş noktası seçin.';

  @override
  String get minTwoLocationsError =>
      'Bir rota oluşturmak için en az 2 konum seçmelisiniz.';

  @override
  String get locationsNotFoundError =>
      'Bu rotadaki konumlar bulunamadı veya yetersiz.';

  @override
  String get addLocationDialogTitle => 'Yeni Konum Ekle';

  @override
  String get realLocationNameLabel => 'Gerçek Konum Adı (Değiştirilemez)';

  @override
  String get customLocationNameLabel => 'Özel Konum Adı';

  @override
  String get descriptionLabel => 'Açıklama';

  @override
  String get notesLabel => 'Özel Notlar';

  @override
  String get estimatedDurationLabel => 'Tahmini Süre (dakika)';

  @override
  String get needsLabel => 'İhtiyaçlar (virgülle ayırın)';

  @override
  String get selectGroupOptionalLabel => 'Grup Seç (İsteğe Bağlı)';

  @override
  String get confirmEndpointDialogTitle => 'Bitiş Noktasını Onayla';

  @override
  String confirmEndpointDialogContent(String geoName) {
    return '\'$geoName\' burası bitiş noktası olarak ayarlansın mı?';
  }

  @override
  String get confirm => 'Onayla';

  @override
  String get unknownLocation => 'Bilinmeyen Konum';

  @override
  String get currentLocationError =>
      'Mevcut konumunuz alınamadı. Lütfen konum servislerini kontrol edin.';

  @override
  String get drawRouteError =>
      'Rota çizilemedi. API anahtarınızı kontrol edin veya daha sonra tekrar deneyin.';

  @override
  String get saveRouteDialogTitle => 'Rotayı Kaydet';

  @override
  String get routeNameHint => 'Rota adı girin';

  @override
  String routeExistsError(String routeName) {
    return '\'$routeName\' isminde bir rota zaten var. Üzerine yazılsın mı?';
  }

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String routeSavedSuccess(String routeName) {
    return 'Rota \'$routeName\' olarak kaydedildi!';
  }

  @override
  String get routeCompletionDialogTitle => 'Rota Tamamlandı';

  @override
  String get plannedDistance => 'Planlanan Mesafe';

  @override
  String get actualDistance => 'Gerçekleşen Mesafe';

  @override
  String get plannedTotalDuration => 'Planlanan Toplam Süre';

  @override
  String get actualDuration => 'Gerçekleşen Süre';

  @override
  String get exit => 'Çık';

  @override
  String get routeSummaryTitle => 'Rota Özeti';

  @override
  String get startNavigation => 'Başlat';

  @override
  String get estimatedTravelTime => 'Tahmini Yol Süresi';

  @override
  String get totalTimeAtStops => 'Duraklardaki Toplam Süre';

  @override
  String get totalTripTime => 'Toplam Gezi Süresi';

  @override
  String get totalDistance => 'Toplam Mesafe';

  @override
  String get needsForTrip => 'Bu gezi için ihtiyaçlarınız:';

  @override
  String get notesForTrip => 'Bu gezi için aldığınız özel notlar:';

  @override
  String get launchMapsError => 'Google Haritalar uygulaması başlatılamadı.';

  @override
  String get searchHint => 'Ara...';

  @override
  String get mapTypeTooltip => 'Harita Tipi';

  @override
  String get resetBearingTooltip => 'Kuzeyi Göster';

  @override
  String get myLocationTooltip => 'Konumuma Git';

  @override
  String get manageLocationsScreenTitle => 'Konumları Yönet';

  @override
  String get noSavedLocations => 'Kaydedilmiş konum bulunamadı.';

  @override
  String get groupNone => 'Yok';

  @override
  String get locationUpdatedSuccess => 'Konum güncellendi!';

  @override
  String get groupLabel => 'Grup';

  @override
  String get showOnMap => 'Haritada Göster';

  @override
  String get copyLocationInfo => 'Konum Bilgisini Kopyala';

  @override
  String get locationCopiedSuccess => 'Konum bilgileri kopyalandı!';

  @override
  String get saveChanges => 'Değişiklikleri Kaydet';

  @override
  String get deleteLocation => 'Konumu Sil';

  @override
  String deleteLocationConfirmation(String locationName) {
    return '\'$locationName\' konumunu silmek istediğinizden emin misiniz?';
  }

  @override
  String get locationDeletedSuccess => 'Konum silindi.';

  @override
  String get googleMapsNameLabel => 'Google Haritalar Adı:';

  @override
  String get logoutConfirmationTitle => 'Çıkış Yap';

  @override
  String get logoutConfirmationContent =>
      'Çıkış yapmak istediğinizden emin misiniz?';

  @override
  String get homeLocation => 'Ev Konumu';

  @override
  String get notSet => 'Ayarlanmadı';

  @override
  String get selectHomeLocation => 'Ev Konumunu Seç';

  @override
  String get endLocation => 'Bitiş Konumu';

  @override
  String get homeLocationAuto => 'Ev Konumu (Otomatik)';

  @override
  String get currentLocation => 'Mevcut Konum';

  @override
  String get notificationSoundLabel => 'Zaman Aşımı Bildirim Sesi';

  @override
  String get soundDefault => 'Varsayılan';

  @override
  String get soundChime => 'Çan Sesi';

  @override
  String get soundAlert => 'Uyarı';

  @override
  String get soundNone => 'Sessiz';

  @override
  String get backgroundLocationNotificationText =>
      'TripBook, uygulama arka planda çalışırken konumunuzu takip ediyor.';

  @override
  String get backgroundLocationNotificationTitle => 'TripBook Rota Takibi';

  @override
  String get routeCompleted => 'Rota tamamlandı!';

  @override
  String nearbyLocationNotificationTitle(String locationName) {
    return 'Yakınlardasınız: $locationName';
  }

  @override
  String get nearbyLocationNotificationBody =>
      'Konum için Google araması yapmak için tıklayın!';

  @override
  String get timeExpiredNotificationTitle => 'Süreniz Doldu!';

  @override
  String timeExpiredNotificationBody(String locationName) {
    return '$locationName konumunda planladığınız süre doldu.';
  }

  @override
  String get minOneLocationError => 'Rota için en az bir konum seçmelisiniz.';

  @override
  String get notAvailable => 'Mevcut Değil';

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String get selectEndpointTitle => 'Bitiş Noktasını Seç';

  @override
  String get currentEndpoint => 'Mevcut Bitiş Noktası';

  @override
  String get communityRoutes => 'Topluluk Rotaları';

  @override
  String get locationsNotFoundOrInsufficient =>
      'Bu rotadaki konumlar bulunamadı veya yetersiz.';

  @override
  String get selectedEndpoint => 'Seçilen Bitiş Noktası';

  @override
  String get routeStart => 'Rota başlangıcı';

  @override
  String get endPoint => 'Bitiş Noktası';

  @override
  String get routeEnd => 'Rota bitişi';

  @override
  String get routeExistsWarningTitle => 'Uyarı: Rota Zaten Mevcut';

  @override
  String get routeExistsWarningContent =>
      'Bu rotayı daha önce indirdiniz. Mevcut sürümün üzerine yazmak istiyor musunuz?';

  @override
  String get overwrite => 'Üzerine Yaz';

  @override
  String get downloadRouteTitle => 'Rotayı İndir';

  @override
  String downloadRouteContent(String routeName) {
    return '\'$routeName\' rotasını ve tüm konumlarını kendi rotalarınıza kaydetmek istiyor musunuz?';
  }

  @override
  String get downloadAndView => 'İndir ve Görüntüle';

  @override
  String routeUpdateSuccess(String routeName) {
    return '\'$routeName\' rotası başarıyla güncellendi!';
  }

  @override
  String routeDownloadError(String error) {
    return 'Rota indirilirken bir hata oluştu: $error';
  }

  @override
  String routeDetailsPlannedDistance(String distance) {
    return 'Planlanan Mesafe: $distance';
  }

  @override
  String routeDetailsActualDistance(String distance) {
    return 'Gerçekleşen Mesafe: $distance';
  }

  @override
  String routeDetailsPlannedTravelTime(String time) {
    return 'Planlanan Yol Süresi: $time';
  }

  @override
  String routeDetailsPlannedStopTime(String time) {
    return 'Planlanan Mola Süresi: $time';
  }

  @override
  String routeDetailsPlannedTotalTime(String time) {
    return 'Planlanan Toplam Süre: $time';
  }

  @override
  String routeDetailsActualTotalTime(String time) {
    return 'Gerçekleşen Toplam Süre: $time';
  }

  @override
  String get needsListTitle => 'İhtiyaç Listesi:';

  @override
  String get privateNotesTitle => 'Özel Notlar:';

  @override
  String get close => 'Kapat';

  @override
  String get noLocationsInThisRoute => 'Bu rotada konum bulunamadı.';

  @override
  String get showDownloaded => 'İndirilenleri Göster';

  @override
  String get hideDownloaded => 'İndirilenleri Gizle';

  @override
  String get noSharedRoutes => 'Henüz paylaşılmış bir rota bulunmuyor.';

  @override
  String get allRoutesDownloaded => 'Tüm rotalar indirilmiş ve gizlenmiş.';

  @override
  String routeDistanceAndDuration(String distance, String duration) {
    return 'Mesafe: $distance | Süre: $duration';
  }

  @override
  String sharedBy(String author) {
    return 'Paylaşan: $author';
  }

  @override
  String rating(String rating, int count) {
    return '$rating ($count oy)';
  }

  @override
  String comments(int count) {
    return '$count yorum';
  }

  @override
  String get downloadingRoute => 'Rota indiriliyor...';

  @override
  String get saveRoute => 'Rotayı Kaydet';

  @override
  String saveRouteConfirmation(String routeName) {
    return '\'$routeName\' rotasını kendi kayıtlı rotalarınıza eklemek istediğinizden emin misiniz?';
  }

  @override
  String routeSavedSuccessfully(String routeName) {
    return '\'$routeName\' rotası başarıyla kaydedildi!';
  }

  @override
  String get unknownUser => 'Bilinmiyor';

  @override
  String get distance => 'Mesafe';

  @override
  String get duration => 'Süre';

  @override
  String get totalBreakTime => 'Toplam Mola Süresi';

  @override
  String get rate => 'Puanla';

  @override
  String get commentsTitle => 'Yorumlar';

  @override
  String get drawRoute => 'Rotayı Çiz';

  @override
  String get routeNeeds => 'Rota İhtiyaçları';

  @override
  String get routeNotes => 'Rota Notları';

  @override
  String get addCommentHint => 'Yorum ekle...';

  @override
  String get commentsLoadingError => 'Yorumlar yüklenemiyor.';

  @override
  String commentsLoadingErrorDescription(String error) {
    return 'Yorumlar yüklenirken bir hata oluştu: $error';
  }

  @override
  String get noCommentsYet => 'Henüz yorum yapılmamış.';

  @override
  String get votes => 'oy';

  @override
  String get plannedTravelTime => 'Planlanan Yol Süresi';

  @override
  String get plannedBreakTime => 'Planlanan Mola Süresi';

  @override
  String get plannedTotalTime => 'Planlanan Toplam Süre';

  @override
  String get actualTotalTime => 'Gerçekleşen Toplam Süre';

  @override
  String get needsList => 'İhtiyaç Listesi';

  @override
  String get privateNotes => 'Özel Notlar';

  @override
  String get start => 'Başlat';

  @override
  String get noLocationsInRoute => 'Bu rotada konum bulunamadı.';

  @override
  String get privateNotesLabel => 'Özel Notlar';

  @override
  String get estimatedStayTimeLabel => 'Tahmini Kalma Süresi (dakika)';

  @override
  String get enterValidNumberError => 'Lütfen geçerli bir sayı girin.';

  @override
  String get needsListLabel => 'İhtiyaç Listesi';

  @override
  String get addNewNeedHint => 'Yeni ihtiyaç ekle';

  @override
  String get sortAndEdit => 'Sırala ve Düzenle';

  @override
  String get endLocationLabel => 'Bitiş Konumu';

  @override
  String get change => 'Değiştir';

  @override
  String get latitude => 'Enlem';

  @override
  String get longitude => 'Boylam';

  @override
  String get reachedLocationsLog => 'Ulaşılan Konumlar Günlüğü';

  @override
  String get markAllAsRead => 'Tümünü Okundu İşaretle';

  @override
  String get allLogsMarkedAsRead => 'Tüm günlükler okundu olarak işaretlendi.';

  @override
  String get selectAll => 'Tümünü Seç';

  @override
  String get unselectAll => 'Tüm Seçimi Kaldır';

  @override
  String get allLogsMarkedAsUnread =>
      'Tüm günlükler okunmadı olarak işaretlendi.';

  @override
  String get deleteRead => 'Okunanları Sil';

  @override
  String get readLogsDeleted => 'Okunan tüm kayıtlar silindi.';

  @override
  String get sortByDateNew => 'Tarihe Göre (Yeni)';

  @override
  String get sortByDateOld => 'Tarihe Göre (Eski)';

  @override
  String get noReachedLocations =>
      'Henüz bir konuma ulaşmadınız.\nBir rota başlatıp hedeflere yaklaştığınızda buraya eklenecektir.';

  @override
  String get reachedAt => 'Ulaşılma';

  @override
  String get moreInfo => 'Daha Fazla Bilgi';

  @override
  String get stopSharing => 'Paylaşımı Durdur';

  @override
  String get shareRoute => 'Rotayı Paylaş';

  @override
  String stopSharingConfirmation(String routeName) {
    return '\'$routeName\' rotasının toplulukla paylaşımını durdurmak istediğinizden emin misiniz?';
  }

  @override
  String shareRouteConfirmation(String routeName) {
    return '\'$routeName\' rotasını diğer kullanıcılarla paylaşmak istediğinizden emin misiniz? Rota, topluluk ekranında görünecektir.';
  }

  @override
  String routeNoLongerShared(Object routeName) {
    return '\'$routeName\' rotası artık paylaşılmıyor.';
  }

  @override
  String routeSharedSuccessfully(String routeName) {
    return '\'$routeName\' rotası başarıyla paylaşıldı!';
  }

  @override
  String get deleteRoute => 'Rotayı Sil';

  @override
  String deleteRouteConfirmation(String routeName) {
    return '\'$routeName\' adlı rotayı silmek istediğinizden emin misiniz?';
  }

  @override
  String get deleteLabel => 'Sil';

  @override
  String routeDeleted(String routeName) {
    return '\'$routeName\' rotası silindi.';
  }

  @override
  String get noSavedRoutes => 'Kaydedilmiş rota bulunamadı.';

  @override
  String errorOccurred(String error) {
    return 'Bir hata oluştu: $error';
  }

  @override
  String get distanceLabel => 'Mesafe';

  @override
  String get durationLabel => 'Süre';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageCode => 'tr';

  @override
  String get language => 'Dil';

  @override
  String get login => 'Giriş Yap';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get emailAddress => 'E-posta Adresi';

  @override
  String get password => 'Şifre';

  @override
  String get createNewAccount => 'Yeni hesap oluştur';

  @override
  String get alreadyHaveAccount => 'Zaten bir hesabım var';

  @override
  String get enterValidEmail => 'Lütfen geçerli bir e-posta adresi girin.';

  @override
  String get passwordMinLengthError =>
      'Şifre en az 8 karakter uzunluğunda olmalıdır.';

  @override
  String get routeAlreadySaved => 'Bu rota zaten kayıtlı.';

  @override
  String get downloadedFromCommunity => '(Topluluktan indirildi)';

  @override
  String get deleteRouteConfirmationWithLocations =>
      'Bu rota topluluktan indirildi. İlişkili konumları da silmek istiyor musunuz?';

  @override
  String get locationsLabel => 'Konumlar';

  @override
  String get deleteRouteAndLocations => 'Rotayı ve Konumları Sil';

  @override
  String get passwordComplexityError =>
      'Şifre en az bir harf ve bir rakam içermelidir.';

  @override
  String get passwordWhitespaceError => 'Şifre boşluk içeremez.';

  @override
  String get invalidCommentError => 'Yorum geçersiz karakterler içeriyor.';

  @override
  String get invalidGroupNameError => 'Grup adı geçersiz karakterler içeriyor.';

  @override
  String get locationNameEmptyError => 'Konum adı boş olamaz.';

  @override
  String get locationNameInvalidCharsError =>
      'Konum adı geçersiz karakterler içeriyor.';

  @override
  String get descriptionInvalidCharsError =>
      'Açıklama geçersiz karakterler içeriyor.';

  @override
  String get notesInvalidCharsError => 'Notlar geçersiz karakterler içeriyor.';

  @override
  String get routeNameInvalidCharsError =>
      'Rota adı geçersiz karakterler içeriyor.';

  @override
  String get usernameInvalidCharsError =>
      'Kullanıcı adı geçersiz karakterler içeriyor.';
}
