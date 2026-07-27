# Hibrit Rota Yerelleştirme ve Profesyonel UI Güncellemesi

Hibrit rota sistemiyle ilgili tüm metinler yerelleştirildi ve rota özet ekranı daha profesyonel bir görünüme kavuşturuldu.

## Yapılan Değişiklikler

### 1. Tam Yerelleştirme (TR/EN)
- **Hibrit Rota Başlığı:** Artık seçili ulaşım moduna (Araç/Yürüyüş) göre dinamik olarak yerelleşiyor.
- **Teknik Uyarılar:** "Bazı Noktalara Yol Erişimi Yok" ve "Yaklaşık Süre" gibi teknik metinler ARB dosyalarına taşındı.
- **Navigasyon Diyalogları:** Etap tamamlandığında veya yeni etap hazır olduğunda çıkan tüm mesajlar artık seçili dile duyarlı.
- **Sistem Etiketleri:** "Start" ve "Mevcut Konumunuz" gibi harita üzerindeki sabit metinler yerelleştirildi.

### 2. Profesyonel UI İyileştirmeleri
- **Dinamik Başlık Alanı:** Rota özet ekranındaki başlık, `FittedBox` ile sarmalanarak her ekran boyutunda taşmadan düzgün görünmesi sağlandı.
- **Hibrit Göstergesi:** Hibrit rotalar için başlığın yanına şık bir sihirli değnek ikonu (`Icons.auto_fix_high`) eklendi.
- **Bilgi Rozetleri:** "Yol Erişimi Yok" uyarısı, daha okunaklı ve modern bir badge (rozet) tasarımına dönüştürüldü.
- **Gelişmiş Tipografi:** Lokasyon sayısı ve rota tipi arasındaki hiyerarşi, farklı font boyutları ve opaklık değerleri ile daha net hale getirildi.

## Doğrulama ve Test Sonuçları

- [x] **Dile Duyarlılık:** Uygulama İngilizceye çevrildiğinde tüm hibrit rota mesajlarının sorunsuz değiştiği görüldü.
- [x] **Görsel Uyum:** Başlığın çok uzun olduğu durumlarda bile UI bütünlüğünün bozulmadığı doğrulandı.
- [x] **Kullanıcı Deneyimi:** Hibrit rota uyarılarının daha belirgin ama göz yormayan bir şekilde sunulduğu teyit edildi.

> [!TIP]
> Rota özetindeki yeni tasarım, kullanıcıya rotanın "akıllı" bir şekilde (hibrit) tamamlandığını daha profesyonel bir dille hissettiriyor.
