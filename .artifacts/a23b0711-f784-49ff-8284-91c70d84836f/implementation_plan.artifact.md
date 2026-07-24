# Firebase Functions Node.js 22 Güncelleme ve Deprecation Fix Planı

Bu plan, Node.js 22'ye geçiş sonrası yaşanan deploy hatalarını gidermeyi ve `functions.config()` deprecation uyarısını çözmeyi amaçlar.

## Sorun Analizi
1.  **Deprecation Notice:** `functions.config()` API'si Mart 2027'de kapatılacak. Yerine `params` paketi veya `.env` dosyaları kullanılması öneriliyor.
2.  **Deploy Failure:** `getDirections` fonksiyonu oluşturulamıyor. Bu durum genellikle yeni Node runtime'ı (v22) ile eski (1st Gen) fonksiyon yapısı arasındaki uyumsuzluklardan veya eksik yapılandırmadan kaynaklanır.

## Önerilen Değişiklikler

### 1. Firebase Functions v2'ye Geçiş
Firebase Functions v2, modern Node.js sürümleriyle daha uyumludur ve daha iyi performans sunar. `getDirections` fonksiyonunu v2 yapısına taşıyacağız.

### 2. Configuration Migration (Params & .env)
`functions.config()` yerine `firebase-functions/params` ve `.env` dosyası kullanarak Google Maps API Key'i yöneteceğiz.

### 3. Bağımlılık Güncellemeleri
`firebase-functions` ve `firebase-admin` paketlerini Node 22 desteği için en güncel sürümlere çekeceğiz.

---

## Dosya Bazlı Değişiklikler

### [functions/package.json](file:///D:/Repo/Flutter/Projects/TripBook/functions/package.json) [MODIFY]
- `firebase-functions` sürümünü yükselt.
- `firebase-admin` sürümünü yükselt.

### [functions/index.js](file:///D:/Repo/Flutter/Projects/TripBook/functions/index.js) [MODIFY]
- `firebase-functions/v2/https` kullanacak şekilde kodu güncelle.
- `functions.config()` kullanımını `defineString` ile değiştir.
- v2'nin yerleşik CORS desteğini kullan.

### [functions/.env](file:///D:/Repo/Flutter/Projects/TripBook/functions/.env) [NEW]
- `GOOGLE_MAPS_API_KEY` değerini bu dosyaya ekle. (Not: Bu değer `functions:config:get` ile sistemden okunacak ve buraya yazılacaktır).

---

## Doğrulama Planı

### Otomatik Testler
- Fonksiyonların yerel ortamda çalıştığını doğrulamak için:
  ```bash
  cd functions
  npm install
  firebase emulators:start --only functions
  ```

### Manuel Doğrulama
- `firebase deploy --only functions` komutu ile deploy işleminin başarılı olduğunu kontrol et.
- `getDirections` fonksiyonunun URL'ine istek atarak (token ile) çalıştığını doğrula.

---

## Kullanıcı Onayı Gereken Konular
- **Secret Management:** API anahtarını `.env` dosyasında tutmak (ve repoya eklememek) en iyi pratiktir. Eğer bu anahtarı Cloud Secret Manager'da tutmak isterseniz planı ona göre revize edebiliriz. Şimdilik en hızlı çözüm olan `.env` ile ilerliyoruz.
- **v2 URL Değişikliği:** v2 fonksiyonlarının URL yapısı v1'den farklı olabilir (genellikle `https://<region>-<project-id>.cloudfunctions.net/<functionName>`). Uygulamanızdaki URL'i güncellemeniz gerekebilir.
