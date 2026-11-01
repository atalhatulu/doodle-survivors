# Altın Sikke, Silah Mermi Dengelemesi ve Yakın Hedefleme İyileştirme Raporu

**Tarih:** 2026-10-31  
**Proje:** Doodle Survivors (Godot 4.7)  
**Kapsam:** Sikke Sprite Değişimi, Silah Mermi Çoğalma Mantığı Dengelemesi, En Yakın Düşman Hedefleme Algoritması  

---

## 1. Yapılan İşlemler ve Değişiklikler

### Görev 1: Altın Sikke (Gold Coin) Görseli ve Bağlantıları
- **Eski Durum:** Altınlar için ataş/ofis metaforu içeren `coin_paperclip.png` kullanılıyordu.
- **Yeni Durum:**
  - 64x64 çözünürlükte, koyu bronz/altın kenarlıklı, kabartmalı runik fantezi yıldızı amblemine sahip karanlık/orta çağ fantezi RPG temalı `gold_coin.png` üretildi ve Godot import motoruna tanıtıldı.
  - `coin_pickup.tscn` ve `coin_pickup.gd` güncellenerek yeni doku bağlandı.
  - Arayüz sahnelerindeki (`hud.tscn`, `main_menu.tscn`, `shop_menu.tscn`) sikke gösterge ikonları `gold_coin.png` dokusuna yönlendirildi.
  - Eski referansların kırılmaması için `coin_paperclip.png` dokusu da aynı altın sikke sprite'ı ile güncellendi.

### Görev 2: Silah Taban Mermi Sayısı ve Pasif Ayrımı
- **Eski Durum:**
  - `weapon_ranged.gd` ve `weapon_axe_thrower.gd` seviye 3, 5 ve 7'ye ulaştığında taban mermi sayısını 2, 3 ve 4'e çıkarıyordu. Bu durum hem görsel kirlilik yaratıyor hem de çoğaltma pasifi (`passive_carbon_paper` / Çoğaltıcı Mühür) ile üst üste bindiğinde aşırı mermi saçılmasına yol açıyordu.
- **Yeni Durum:**
  - Silah seviye atlamalarından taban mermi artışı kaldırıldı.
  - Silahların seviye atlama ölçeklemesi; hasar artışı (+%35 - +%40), atış/saldırı hızı (+%10 - +%11), menzil/alan ve 7. seviye zirve çarpanı ile güçlendirildi.
  - Ekstra mermi/saldırı fırlatma mekaniği yalnızca pasif eşyalara (`passive_carbon_paper` - `extra_projectiles`) devredildi.
  - `level_up_menu.gd` kart metinleri, yanıltıcı "+1 Ekstra Mermi" ifadelerinden arındırılarak hasar ve saldırı hızı ölçeklemesini net yansıtacak şekilde revize edildi.

### Görev 3: En Yakın Düşman Hedefleme Algoritması ve Acil Tehdit Önceliği
- **Eski Durum:**
  - Silahlardaki hedef arama döngüleri (örneğin `SECTOR` modundaki yay, `MOVEMENT_DIR` modundaki kılıç, `STRONGEST` modundaki asa) oyuncunun dibinde (0-140px) acil tehdit oluşturan düşmanları görmezden gelip uzak hedeflere yönelebiliyordu.
  - Ölmüş düşmanlar ölüm animasyonu sırasında (`_die` esnasında) gruptan anında çıkarılmadığı için silahlar birkaç kare boyunca ölü bedenleri hedefleyebiliyordu.
- **Yeni Durum:**
  - `enemy_base.gd` içindeki `_die()` fonksiyonunun en başında `remove_from_group("enemies")` çağrılarak ölen yaratıkların silah hedef havuzundan anında düşmesi sağlandı.
  - `weapon_ranged.gd` içindeki `_find_target()` metoduna Acil Tehdit Koruması eklendi: Oyuncunun dibinde (160px menzil içinde) bir düşman varsa, silahın modu ne olursa olsun mutlak öncelikle oyuncunun en dibindeki düşman hedeflenir.
  - Silah `_process` döngüsünde mevcut hedefin ölmesi (`is_dead == true`) durumunda `target_scan_timer` beklemeden anında yeni hedef araması tetiklenir.
  - Aday düşman filtrelemesinde `is_dead` ve nesne geçerlilik kontrolleri sıkılaştırıldı.
  - `weapon_axe_thrower.gd` ve `weapon_potion.gd` içerisindeki mesafe hesaplamaları silahın yerel ofseti yerine doğrudan oyuncunun merkez koordinatına (`center_pos`) bağlandı.

---

## 2. Doğrulama ve Test Kaydı

`scripts/test_phases_headless.gd` test paketi çalıştırılarak doğrulandı (`godot --headless -s scripts/test_phases_headless.gd`):
- **Test 1 - 12:** Mevcut oyun ve mekanik testleri (12/12 PASS).
- **Test 13:** Altın Sikke dokusunun sahneye ve sprite'a doğru bağlandığı doğrulandı (PASS).
- **Test 14:** Silah seviyesi 7'ye yükseltildiğinde taban mermi sayısının 1 kaldığı, hasarın ölçeklendiği doğrulandı (PASS).
- **Test 15:** Hem Yay (`SECTOR`), hem Asa (`STRONGEST`) modunda dibimizdeki acil tehdidin (45px) mutlak öncelikle hedeflendiği ve ölü düşman filtresinin derhal tetiklendiği doğrulandı (PASS).
- **Genel Sonuç:** 15 / 15 Test Başarılı (0 Hata).
