# Diğer "D:" Yolu Referanslarını Temizleme Planı

Proje genelinde yapılan kapsamlı tarama sonucunda, eski `D:` yoluna referans veren birkaç yer daha tespit edilmiştir. Bunlar özellikle IDE (Android Studio/IntelliJ) ayarlarını etkilemektedir.

## Tespit Edilen Referanslar

1.  **IDE Ayarları:** `.idea/libraries/Dart_SDK.xml` dosyası içinde Dart SDK'nın konumu hala `D:` olarak görünmektedir. Bu durum IDE'nin kod tamamlama ve analiz özelliklerini bozabilir.
2.  **Artifact Kayıtları:** Önceki görevlerin döküm dosyalarında (`.artifacts/`) bu yol geçmektedir, ancak bunlar sadece kayıt olduğu için değiştirilmeleri gerekmemektedir.
3.  **Önbellek Dosyaları:** `android/.gradle` içindeki bazı ikili dosyalarda bu yol geçebilir. `flutter clean` bunu büyük oranda çözer.

## Önerilen Değişiklikler

### [IDE Yapılandırması]

#### [MODIFY] [.idea/libraries/Dart_SDK.xml](file:///C:/Users/cetin/Projects/TripBook/.idea/libraries/Dart_SDK.xml)
- Dosya içindeki tüm `D:/Repo/Flutter/Projects/Test/flutter/bin/cache/dart-sdk` yollarını `C:/flutter/bin/cache/dart-sdk` ile değiştireceğiz.

## Doğrulama Planı

### Manuel Doğrulama
- Değişiklik sonrası Android Studio içinden **File > Restart IDE** yapılması önerilir.
- Proje açıldığında Dart SDK'nın doğru yoldan (`C:\flutter...`) yüklendiği ve analiz motorunun hatasız çalıştığı doğrulanacak.
