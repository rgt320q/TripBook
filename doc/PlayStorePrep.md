# TripBook — Google Play Store Yayın Hazırlığı

> Durum: analiz tamamlandı. Aşağıdaki liste öncelik sırasıyla uygulanacak işleri ve
> Play Console yönlendirmesini içerir. "P0" maddeleri yayın öncesi **bloklayıcıdır**.

## 1. Mevcut Durum Analizi

| Konu | Durum | Etki |
|---|---|---|
| Release imzalama | `android/app/build.gradle.kts` (buildTypes.release) **debug key** ile imzalıyor | 🔴 Play'e yüklenemez |
| Adaptive icon | `mipmap-anydpi-v26` klasörü yok, sadece eski PNG (`ic_launcher.png`) | 🔴 Store/cihaz ikonu kötü görünür |
| Hesap silme | Kodda yok (sadece logout & şifre değiştirme var) | 🔴 Play zorunluluğu — yayın reddi nedeni |
| Gizlilik politikası | Yok | 🔴 Konum/kişisel veri toplanıyor → zorunlu |
| Arka plan konumu | `ACCESS_BACKGROUND_LOCATION` + `FOREGROUND_SERVICE_LOCATION` + geolocator servisi aktif | 🟠 Play "App access"/konum beyanı + gerekçe metni gerekir |
| Cleartext traffic | `android:usesCleartextTraffic="true"` (`src/main/AndroidManifest.xml`) | 🟠 Güvenlik zaafı; kaldırılmalı |
| API key'ler | `doc/ToDo.txt` madde 5: canlıya geçmeden değiştirilecek | 🟠 Rotasyondan önce yayın YOK |
| targetSdk | 35 (compileSdk 36) — Play için yeterli | ✅ |
| minSdk | 24, core library desugaring açık | ✅ |
| Firestore kuralları | Güvenli görünüyor (`isOwner`/`isSignedIn`, fcmToken ayrı koleksiyonda) | ✅ |
| Storage kuralları | `profile_images` dışı her şey kapalı | ✅ |
| FCM / Crashlytics / Analytics | Kurulu ve yapılandırılmış | ✅ |
| Testler | 3 kırmızı test (bilinen, önceden tespit edilmiş) | 🟠 kalite; engel değil |
| Versiyon | `pubspec.yaml`: `1.0.0+1` | ✅ |

## 2. İhtiyaç Listesi (Öncelikli)

### P0 — Yayın öncesi bloklar

1. **Release imzalama keystore'u**
   - `keytool` ile kalıcı bir upload keystore üret (örn. `android/app/upload-keystore.jks`).
   - `android/key.properties` oluştur (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`).
   - `android/app/build.gradle.kts` içinde `signingConfigs`'e `release` ekle ve
     `buildTypes.release.signingConfig`'i oraya yönlendir; **debug key kullanımını kaldır**.
   - `.gitignore` zaten `key.properties` ve `*.jks` hariç tutuyor — doğrula.

2. **Hesap silme özelliği (kod)**
   - Firebase Auth: `user.delete()` (öncesinde `reauthenticateWithCredential`).
   - Firestore: `users/{uid}` + alt koleksiyonlar (`locations`, `routes`, `groups`, `reached_logs`)
     ve `user_tokens/{uid}` sil.
   - Storage: `profile_images/...` ilgili dosyalarını sil.
   - Profil ekranına "Hesabı Sil" kartı + onay dialogu + reauthenticate akışı ekle (EN/TR l10n).

3. **API key rotasyonu**
   - Yeni `GOOGLE_MAPS_API_KEY` (Android: paket `com.cetinsoft.tripbook` + release SHA-1;
     web: referrer kısıtı) üret ve `android/secrets.properties`'e işle.
   - Yeni `MAPS_PROXY_KEY` (Firebase Secret Manager) üret; `firebase deploy --only functions`.
   - `assets/.env` içindeki web anahtarını güncelle.

4. **Adaptive ikon üretimi**
   - `dart run flutter_launcher_icons --config=...` çalıştır (adaptive icon config'i ekle).
   - `mipmap-anydpi-v26/ic_launcher.xml` üretildiğini doğrula.
   - Manifest'e `android:roundIcon="@mipmap/ic_launcher"` ekle.

### P1 — Play politikaları

5. **Gizlilik politikası** (EN+TR web sayfası veya barındırılan statik sayfa)
   - Konum (arka plan dahil), e-posta/ad/birthdate, avatar fotoğrafı ve toplanma amacı.
   - Veri silme yöntemi (hesap silme akışı + iletişim/URL).
   - URL'i Play Store listing'e gir.

6. **Data safety formu (Play Console)**
   - Konum, kişisel bilgiler, resimler; toplanır/paylaşılmaz; silme mekanizması beyanı.

7. **Konum bildirimleri & FGS**
   - "App access" bölümü: approximate + precise location; arka plan konum gerekçesi.
   - Foreground service type "location" bildirimi.
   - Uygulama içi belirgin açıklama ("prominent disclosure") ekle.

8. **Cleartext temizliği**
   - `usesCleartextTraffic="true"` kaldır; gerekiyorsa `network_security_config` kullan.

9. **Kırmızı testlerin düzeltilmesi**
   - `test/` altındaki 3 başarısız testi analiz edip düzelt.

### P2 — Mağaza varlıkları & hazırlık

10. App ikonu 512x512, feature graphic 1024x500, telefon screenshot'ları (5.5" / 7").
11. Kısa/açıklayıcı tanım (EN+TR), kategori, fiyatlandırma (ücretsiz/ücretli).
12. `versionCode/versionName` stratejisi (örn. `1.0.0+1`, her sürümde code +1).
13. İçerik derecelendirmesi anketi + hedef kitle beyanı.

## 3. Yönlendirme Rehberi (Play Console akışı)

1. **Geliştirici hesabı** — Google Play Console'a kayıt ($25 tek seferlik). Kişisel hesapta
   **kapalı test zorunluluğu**: ≥12 testçi ile ≥14 gün test ardından production erişim onayı
   istenir. Önce `internal testing` → `closed testing` → production sıralamasıyla ilerle.
2. **AAB üretimi** — `flutter build appbundle --release`.
3. **Doğrulama**
   - Gerçek cihazlarda (Android 14/15, küçük ekran) release AAB kur ve kapsamlı test et
     (arka plan navigasyonu, konum izinleri, FGS, bildirimler).
   - Crashlytics'in veri gönderdiğini doğrula.
4. **Play App Signing** — aktifleştir; upload key ile AAB yükle; mevcut debug imzalı
   denemeleri unut (imza değişirse eski kurulumlar güncellenemez).
5. **Store listing** — P0/P1/P2 tamamlandıktan sonra listing'i doldur ve review'a gönder.
6. **Yayın sonrası** — targetSdk'yi 36'ya yükseltme planı, aşamalı rollout, metrik izleme.

## 4. Notlar

- `android/` ve kök `.gitignore` `key.properties`, `secrets.properties`, `*.jks` içeriyor; imzalama
  dosyaları asla repo'ya itilmemeli.
- `secrets.properties` → `GOOGLE_MAPS_API_KEY` Android manifest'ine `resValue` ile gidiyor;
  web anahtarı `assets/.env`'de.
- FCM bildirim kanalı: `high_importance_channel` manifest'te tanımlı.
- Firebase yapılandırma dosyaları (`google-services.json`, `firebase.json`, storage.rules,
  firestore.rules) güncel tut.
