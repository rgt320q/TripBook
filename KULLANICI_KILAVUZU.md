# Travel Log - Kullanıcı Kılavuzu

Bu belge, Travel Log uygulamasının özelliklerini ve nasıl kullanılacağını açıklamaktadır.

## 1. Genel Bakış

Travel Log, seyahatlerinizi planlamak, konumları kaydetmek, rotalar oluşturmak ve seyahat esnasında ilerlemenizi takip etmek için tasarlanmış bir mobil uygulamadır.

---

## 2. Harita Ekranı ve Temel İşlemler

Uygulamanın ana ekranı interaktif bir haritadır.

### 2.1. Konum İşaretçileri (Pinler)
- **Mevcut Konumunuz:** Haritada, etrafında parlama efekti olan mavi bir nokta ile gösterilir.
- **Kaydedilmiş Konumlar:** Klasik Google Haritalar pini şeklinde gösterilir.
  - **Renklendirme:**
    - Bir gruba atanmış konumlar, grubun rengini alır.
    - Herhangi bir gruba dahil olmayan konumlar **gri** renkte gösterilir.
    - Aktif bir rota sırasında ziyaret ettiğiniz konumlar ise **yeşil** renge döner.

### 2.2. Yeni Konum Ekleme
- Haritada herhangi bir yere **uzun basarak** yeni bir konum ekleyebilirsiniz.
- Açılan pencerede konuma özel bir isim, açıklama, notlar, ihtiyaç listesi ve tahmini durma süresi gibi detayları girebilirsiniz.

### 2.3. Konumuma Git Butonu
- Haritanın sağ alt köşesinde bulunan **hedef (my_location)** ikonuna basarak haritayı anında mevcut konumunuza ortalayabilirsiniz.

---

## 3. Konum ve Grup Yönetimi

Uygulama, konumlarınızı ve gruplarınızı verimli bir şekilde yönetmeniz için özel ekranlar sunar.

### 3.1. Konumları Yönet
- Üst menüdeki **liste (list_alt)** ikonu ile bu ekrana ulaşabilirsiniz.
- Tüm kayıtlı konumlarınız burada listelenir.
- Konumları isme veya oluşturulma tarihine göre sıralayabilirsiniz.
- Herhangi bir konuma tıkladığınızda detaylarını (isim, açıklama, grup, notlar vb.) düzenleyebilirsiniz.
- **Haritadan Geçiş:** Haritadaki bir pine tıkladığınızda, bu ekran açılır ve liste otomatik olarak ilgili konuma kaydırılır.

### 3.2. Grupları Yönet
- Üst menüdeki **klasör (folder_copy_outlined)** ikonu ile bu ekrana ulaşabilirsiniz.
- Konumlarınızı kategorize etmek için renkli gruplar oluşturabilir, düzenleyebilir ve silebilirsiniz.
- Bir konumu düzenlerken, oluşturduğunuz bu gruplardan birine atayabilirsiniz.

---

## 4. Rota Planlama ve Kullanımı

Uygulama, kayıtlı konumlarınızdan dinamik rotalar oluşturmanıza olanak tanır.

### 4.1. Rota Oluşturma
- Harita ekranında üst menüdeki **yol tarifi (directions)** ikonuna tıklayın.
- **Gruptan Seç:** Belirli bir gruptaki tüm konumları içeren bir rota oluşturur.
- **Manuel Seçim:** Listeden istediğiniz konumları seçerek özel bir rota oluşturmanızı sağlar.
- Rota oluşturulduğunda, uygulama konumları mevcut konumunuza göre en verimli şekilde sıralar.

### 4.2. Rota Kaydetme ve Yükleme
- **Kaydetme:** Rota özeti ekranında **kaydet (save)** ikonuna basarak mevcut rotayı isimlendirip kaydedebilirsiniz.
- **Yükleme:** Harita ekranında üst menüdeki **rota (route_sharp)** ikonuna basarak daha önce kaydettiğiniz rotaları yükleyebilirsiniz.

### 4.3. Rota Özeti ve Kontrol Listesi
- Bir rota oluşturulduğunda veya aktif bir rota için üst menüdeki **özet (summarize)** ikonuna basıldığında bir özet ekranı açılır.
- Bu ekranda toplam mesafe, tahmini yol ve duraklama süreleri gibi bilgiler yer alır.
- **İhtiyaç Listesi:**
  - Rota üzerindeki konumlara eklediğiniz tüm ihtiyaçlar burada birleştirilmiş bir kontrol listesi olarak sunulur.
  - Bu liste **o anki seyahate özeldir**. İşaretlediğiniz maddeler (tikler), siz rotayı kapatana kadar korunur.
  - Rota kapatılıp yeniden açıldığında veya aynı rota şablonuyla yeni bir seyahat başlatıldığında, bu liste temizlenmiş (tiksiz) olarak gelir.
- **Özel Notlar:** Rota üzerindeki konumlara ait tüm özel notlar da bu ekranda bir arada gösterilir.

---

## 5. Aktif Rota Takibi

Bir rotayı başlattığınızda, harita ekranı seyahatinizi aktif olarak takip eder.

- **Gidilecek Yol:** Henüz gitmediğiniz yol parçaları haritada **açık gri** renkte gösterilir.
- **Gidilmiş Yol:** Bir durağa vardığınızda, o durağa kadar kat ettiğiniz yolun rengi kalıcı olarak **canlı maviye** döner.
- **Ulaşılan Duraklar:** Bir durağa 50 metreden daha fazla yaklaştığınızda, o durağın pini kalıcı olarak **yeşil** olur.
- **Bildirimler:** Bir durağa yaklaştığınızda, o konumla ilgili (varsa) Wikipedia özeti içeren bir bildirim alırsınız. Ayrıca bir durakta planladığınız süreden daha fazla kalırsanız süre hatırlatma bildirimi alırsınız.

### 5.1. Ulaşılan Konumlar Geçmişi
- Üst menüdeki **geçmiş (history)** ikonu ile daha önce bir rota sırasında ulaştığınız ve bildirim aldığınız tüm konumların bir listesine ve Wikipedia linklerine erişebilirsiniz.
