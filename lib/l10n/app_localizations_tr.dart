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
    return 'Rota \"$routeName\" olarak kaydedildi!';
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
}
