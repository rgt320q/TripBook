# Hibrit Rota Yerelleştirme ve UI İyileştirmesi

Bu plan, hibrit rota sistemiyle ilgili tüm metinlerin yerelleştirilmesini ve rota özet ekranındaki "Hibrit Rota" bilgisinin daha profesyonel görünmesi için UI iyileştirmelerini içerir.

## Kullanıcı İncelemesi Gerekli

> [!IMPORTANT]
> Hibrit rota başlığı, ekran genişliğine göre dinamik olarak ayarlanacak ve çok uzun olduğunda taşma yapmayacak şekilde (Marquee veya Wrap) düzenlenecektir.
> Tüm teknik terimler (Kuş Uçuşu, Etap vb.) her iki dilde (TR/EN) tutarlı hale getirilecektir.

## Önerilen Değişiklikler

### [Localization]

#### [MODIFY] [app_en.arb](file:///C:/Users/cetin/Projects/TripBook/lib/l10n/app_en.arb) & [app_tr.arb](file:///C:/Users/cetin/Projects/TripBook/lib/l10n/app_tr.arb)
- `hybridRouteTitle`: "Hibrit Rota ({mode} + Kuş Uçuşu)" / "Hybrid Route ({mode} + As the Crow Flies)"
- `noRoadAccessWarning`: "Bazı Noktalara Yol Erişimi Yok" / "No Road Access to Some Points"
- `approximateDurationWarning`: "Hesaplanamayan rotalar olduğu için yaklaşık süre hesaplanmıştır." / "Approximate duration calculated due to unreachable routes."
- `stageCompletedTitle`: "Etap Tamamlandı" / "Stage Completed"
- `stageCompletedMessage`: "{location} konumuna ulaştınız..." mesajı.
- `nextStageReadyTitle`: "Yeni Etap Hazır" / "Next Stage Ready"
- `nextStageReadyMessage`: "Deniz geçişi/ara bölge tamamlandı..." mesajı.
- `navigationNotAvailableTitle`: "Ulaşım Arasındasınız" / "Mid-Transit"
- `navigationNotAvailableMessage`: "Bu etap için Google Haritalar kullanılamaz..." mesajı.
- `modeDriving`: "Araç" / "Driving"
- `modeWalking`: "Yürüyüş" / "Walking"

### [Screens]

#### [MODIFY] [map_screen.dart](file:///C:/Users/cetin/Projects/TripBook/lib/screens/map_screen.dart)
- `_showRouteSummary` metodundaki hardcoded metinler `l10n` çağrıları ile değiştirilecek.
- Başlık alanı (`Hybrid Route...`), eğer metin sığmıyorsa `FittedBox` veya `TextOverflow.ellipsis` yerine, daha şık durması için `Column` içinde alt alta veya ikonlarla desteklenmiş bir `Row` yapısına dönüştürülecek.
- "Bazı Noktalara Yol Erişimi Yok" rozeti (badge), ana başlığın altına daha belirgin ama göz yormayan bir şekilde yerleştirilecek.
- Diyaloglardaki (`_showStageInfoDialog`, `_showNextStagePrompt`) tüm metinler yerelleştirilecek.

## Doğrulama Planı

### Manuel Doğrulama
- Uygulama dili İngilizceye çevrilip tüm hibrit rota mesajlarının İngilizce olduğu doğrulanacak.
- Küçük ekranlı bir cihazda hibrit rota başlığının sığıp sığmadığı ve görsel kalitesi kontrol edilecek.
- Rota aşamalarındaki (etap geçişleri) bildirim ve diyalog metinlerinin dile göre değiştiği kontrol edilecek.
