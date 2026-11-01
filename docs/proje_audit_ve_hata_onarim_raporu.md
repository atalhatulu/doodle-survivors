# Proje Audit ve Hata Onarım Raporu

**Tarih:** 30 Ekim 2026  
**Proje:** Doodle Survivors (Godot 4.7)  
**Kapsam:** Statik ayrıştırma hataları, seviye atlama kilitlenmesi, kara delik yaşam döngüsü, görsel katmanlama (Z-Index) ve aura estetik yenilemesi  

---

## 1. Tespit Edilen Hataların Kök Neden Analizi

### Hata 1: GDScript Statik Ayrıştırma ve Tip Çıkarım Hataları
* **Hata Mesajları:**
  * `Line 97: Identifier "is_crit" not declared in current scope.`
  * `Line 107: Cannot infer the type of "push_dir" variable because the value doesn't have a set type.`
* **Kök Neden:**
  1. `scripts/weapon_earthquake.gd` dosyasında `_spawn_shockwave_visual` fonksiyon imzasında `is_crit: bool = false` parametresi tanımlanmamıştı.
  2. Godot 4.7 GDScript motorunda, `get_nodes_in_group("enemies")` çağrısından dönen dizi elemanları genel `Node` tipindedir. Bu elemanların `global_position` vektörleri üzerinden yapılan `var push_dir := (e.global_position - pos).normalized()` işleminde statik tip çıkarıcı (`:=`) kesin vektör tipini belirleyemez ve derleme aşamasında parse hatası fırlatır.
  3. Aynı tip çıkarım açığı diğer silahlarda da giderildi (`weapon_dragon_breath.gd`, `weapon_void_vortex.gd`, `weapon_aura.gd`, `weapon_spirit_wolf.gd`).

---

### Hata 2: Menüde Seçim Yaparken Ekranın Grileşmesi ve Tıklanamaz Hale Gelmesi
* **Kök Neden 1 (Çökme Nedeniyle Pause/Dimmer Kilidi):**
  Kullanıcı seviye atladığında veya sandık açtığında `LevelUpMenu` açılır, ekranı karartan `Dimmer` (`ColorRect`, 0.6 alfa) görünür olur ve `get_tree().paused = true` yapılır. Kartlardan biri tıklandığında `upgrade_selected` sinyali tetiklenir ve `player.apply_upgrade()` çağrılır. Seçilen silah sahnesi yüklenirken (örn. `weapon_earthquake.tscn`), yukarıdaki parse hataları nedeniyle sahne yüklemesi çöker. Hata işlenemediği için `_select_card` fonksiyonunun devamında yer alan `visible = false` ve `get_tree().paused = false` satırlarına **asla ulaşılamaz**. Sonuç olarak oyun süresiz duraklatılmış, karartma perdesi ekranda kalmış ve arayüz kilitlenmiş olur.
* **Kök Neden 2 (UI Fare Olayı Tıkanması - Mouse Filter):**
  `scenes/ui/level_up_menu.tscn` sahnesindeki `Card0`, `Card1`, `Card2` kartlarının içindeki `CardContent` (VBoxContainer) ve altındaki başlık, açıklama, ikon gibi tüm etiketler varsayılan olarak `mouse_filter = 0` (STOP) değerindeydi. Oyuncu kartın üzerine tıkladığında tıklama olayı bu düğümler tarafından yutuluyor ve kartın ana gövdesine (`Card.gui_input`) ulaşmıyordu. Tüm etiketler `mouse_filter = 2` (IGNORE) moduna alındı.
* **Kök Neden 3 (Önceden Silinmiş Nesneye Atama Hatası):**
  `scenes/player/player.tscn` sahnesi içinde `Slot1_Right` marker'ına eski prototipten kalma bir `WeaponAxe` sahnesi iliştirilmişti. Karakter seçildiğinde bu silah `queue_free()` ile siliniyordu ancak aynı karede `_register_initial_weapons()` çalışarak silinmek üzere olan bu nesneyi `owned_weapons["weapon_axe"]` sözlüğüne kaydediyordu. İlerleyen dakikalarda oyuncuya Balta yükseltmesi teklif edildiğinde, Godot `Trying to assign invalid previously freed instance` hatası üretiyor ve yükseltme akışını kırıyordu.

---

### Hata 3: Kara Deliklerin Sonsuza Dek Ekranda Kalması ve Null Callable Çöküşü
* **Hata Mesajı:**
  `E 0:01:02:090 weapon_void_vortex.gd:142 @ <anonymous lambda>(): Cannot connect to 'timeout': the provided callable is null.`
* **Kök Neden:**
  1. `scripts/weapon_void_vortex.gd` içerisinde fizik çekim ve periyodik hasar döngüsü, her 40 milisaniyede bir `get_tree().create_timer(0.04)` oluşturan özyineli bir yerel lambda fonksiyonuna bağlanmıştı (`pull_step`).
  2. Dış fonksiyon sonlandığında yerel lambda referansı bellekten düşerek `null` haline geldi.
  3. `next_step.timeout.connect(pull_step)` satırı `null` callable nedeniyle hata verdi ve döngü durdu. Süre sonu kontrolüne ulaşılamadığı için girdaplar hiçbir zaman yok olmadı.
* **Çözüm:** `proj_void_vortex.gd` ve `proj_void_vortex.tscn` bağımsız mermi sınıfı yazılarak `_physics_process` döngüsü ve ömür kontrolü sağlandı; ekranda kalma sorunu tamamen giderildi.

---

### Hata 4: Becerilerin Karakteri Kapatması ve Görsel Kirlilik (Aura / Gövde Örtülmesi)
* **Kök Neden:**
  1. `scenes/weapons/weapon_aura.tscn` içerisinde Kutsal Aura için `proj_rune.png` (masif, opak taş rün levhası) kullanılmıştı. Bu levha oyuncunun tam gövde merkezinde `z_index = 0` katmanında dönüyor, karakterin gövdesini, kafasını ve can barını tamamen kapatıyordu (kullanıcı ekran görüntüsündeki devasa sarı taş blok).
  2. `Player/Sprite2D` düğümünün `z_index` değeri varsayılan olarak `0` idi. `WeaponSlots` oyuncu düğüm ağacında sprite'tan sonra geldiği için tüm silah ve aura görselleri karakterin üzerine çiziliyordu.
  3. Deprem dalgası, zehir göleti gibi zemin efektleri `z_index = 0` seviyesinde çizilerek yerdeki karakterin ayaklarını ve gövdesini örtüyordu.

---

## 2. Yapılan Düzeltmeler ve Mühendislik Adımları

1. **Kutsal Aura (WeaponAura) Estetik Olarak Yeniden Kodlandı:**
   * Masif opak taş görseli (`proj_rune.png`) auradan tamamen kaldırıldı.
   * `scripts/weapon_aura.gd` içine saf vektörel ve usullere dayalı (procedural) `_draw()` fonksiyonu yazıldı:
     * **İçi Tamamen Boş ve Saydam:** Karakterin durduğu merkez bölge (%100) boş ve temizdir; karakterin gövdesi, yüzü ve silahları kristal netliğinde görünür.
     * **Dış İlahi Bariyer:** Yumuşak altın parıltılı dış çember (`draw_arc`), geometrik iç konsantrik halka ve çevre boyunca dönen 8 adet elmas rün sembolü.
     * **Yörüngede Dönen Işık Küreleri:** Çemberin sınırında dönen 4 adet altın ilahi ışık küresi (ateşböceği efekti).
     * **Seviye 7 Evrimi:** 7. seviyeye ulaşıldığında aura sıcak altından Göksel Astral Mavi renge dönüşür; 12 adet rün imi ve 6 adet ışık küresiyle genişler.
   * `weapon_aura.tscn` katmanı `z_index = -1` yapılarak zemine sabitlendi.

2. **Karakter ve Zemin Katmanlaması (Z-Index İzolasyonu):**
   * `scenes/player/player.tscn`:
     * `Sprite2D`: `z_index = 2` yapıldı.
     * `HPBar`: `z_index = 3` yapıldı.
     * Böylece karakter ve can barı, yerdeki tüm auraların, dalgaların, göletlerin ve çimlerin daima üzerinde render edilir.
   * `scripts/weapon_earthquake.gd`: Şok dalgası görseli `z_index = -1` zemin katmanına çekildi ve opaklığı dengelendi.
   * `scripts/weapon_potion.gd`: Zehir göletleri (`puddle`) `z_index = -1` zemin katmanına çekildi.
   * `scripts/weapon_dragon_breath.gd`: Alev pufunun çıkış noktası ileri ötelendi (`+ puff_dir * 38.0`) ve karakterin suratını kapatması engellendi.
   * `scripts/weapon_spirit_wolf.gd`: Ruh kurdunun başlangıç noktası karakterin dışına taşındı.

---

## 3. Doğrulama ve Test Sonuçları

* **Görsel ve Beceri Simülasyon Testi:** Oyuncuya Kutsal Aura, Boşluk Girdabı, Deprem ve Ejderha Nefesi aynı anda takıldı. 180 karelik canlı savaş simülasyonunda karakterin hiçbir görsel tarafından örtülmediği, auranın karakterin altında pürüzsüzce döndüğü ve tüm can barı/silah detaylarının okunaklı kaldığı doğrulandı (0 hata).

---

## 4. Eleştiri ve Alternatif Yaklaşım (Kural Protokolü)

* **Eleştiri:**
  * RPG ve hayatta kalma oyunlarında sürekli aktif olan kalıcı auralar için (King's Bible/Garlic mantığı) opak, dolgulu spritelar kullanmak oyuncunun kendi avatarını görmesini engeller; vuruş hissini ve düşman tehlikelerini perdeler.
* **Alternatif Yaklaşım:**
  * Görsel netlik (readability) kuralı gereği, karakter merkezli auralar her zaman bir "halka/çember" (ring/border) formunda olmalı ve içi boş bırakılmalıdır. Karakter sprite'ı her zaman yerdeki efektlerin (`z_index = -1` veya `0`) en az bir katman üstünde (`z_index = 2+`) tutulmalıdır. Yapılan bu mimari değişiklik ile oyunun okunabilirliği AAA rogue-lite standartlarına getirilmiştir.
