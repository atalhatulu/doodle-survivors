# Doodle Survivors — Sistemik Onarım ve Hata Düzeltme Raporu

Bu rapor, projede tespit edilen tüm kritik oynanış hatalarının, mekanik/matematiksel açıkların, UI girdi kilitlenmelerinin ve tematik tutarsızlıkların onarım detaylarını içermektedir.

---

## 1. Çözülen Kritik Oynanış Hataları

### 1.1. 5. Dakika Boss'unun Oyunu Erken Bitirmesi
- **Düzeltme:** [`enemy_spawner.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/enemy_spawner.gd) içindeki `_spawn_boss()` fonksiyonu `is_final_boss: bool = false`, `hp` ve `dmg` parametreleriyle güncellendi.
- **Akış:** 5, 10 ve 15. dakikalardaki boss'lar çoklu hazine sandığı ve yüksek XP veren ara boss (Mid-Boss) olarak işaretlendi; yalnızca 20. dakikadaki nihai boss öldüğünde `king_boss_defeated` sinyali tetiklenerek zafer ekranına geçilmesi sağlandı.

### 1.2. Düşman Renk ve Boyut Varyantlarının Çalışmaması
- **Düzeltme:** [`enemy_base.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/enemy_base.gd) içine `variant_tint: Color` ve `variant_scale_mult: float` saklayıcıları eklendi. `_ready()` fonksiyonu bu değerleri sprite scale ve modulate ile harmanlayacak şekilde güncellendi.
- Ayrıca [`enemy_spawner.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/enemy_spawner.gd) içinde `_add_enemy_to_scene()` çağrısı `set_variant()` satırının önüne alınarak sahne ağacına giriş sırasından bağımsız olarak Turuncu, Kızıl ve Mor düşman elit formlarının sorunsuz görünmesi sağlandı.

### 1.3. ESC ve TAB Menü / Pause Kilitlenmeleri
- **ESC Çakışması:** [`game_over_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/game_over_menu.gd) içindeki `_unhandled_input` fonksiyonu yalnızca menü görünür ve duraklatma modundayken girdi alacak ve `get_viewport().set_input_as_handled()` ile olayı tüketecek şekilde sınırlandırıldı. Menü açma yetkisi merkezi olarak [`game_manager.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/game_manager.gd)'ye verildi.
- **Envanter & ESC/TAB:** [`inventory_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/inventory_menu.gd) içinde ESC'ye basıldığında envanterin kapanması ve olayın yutulması sağlandı. Seviye atlama veya oyun sonu ekranları açıkken envanterin açılması engellendi.
- **2x Hız Tuşu:** [`hud.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/hud.gd) içindeki çakışan `KEY_TAB` kaldırıldı; hız değiştirme tuşu yalnızca `KEY_T` olarak ayarlandı ve UI metni güncellendi.

### 1.4. Kamera Zoom (0.7) ve Ekran İçi Doğma Sorunu
- **Düzeltme:** [`enemy_spawner.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/enemy_spawner.gd) doğma mesafeleri `spawn_distance_min = 1100.0`, `spawn_distance_max = 1250.0`, `despawn_reposition_distance = 1550.0` değerlerine çekildi.
- Mermi silinme mesafeleri ([`bullet.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/bullet.gd), [`proj_sword.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/proj_sword.gd)) `1350.0` piksele çıkarılarak çapraz atışların ekran köşelerinde zamansız kaybolması önlendi.

---

## 2. Mekanik ve Matematiksel Denge Onarımları

### 2.1. XP ve Altın Küsurat Biriktiricisi
- **Düzeltme:** [`player.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/player.gd) içine `xp_remainder: float` ve `coin_remainder: float` eklendi.
- `add_xp()` ve `add_coins()` fonksiyonları ondalık artışları küsurat havuzunda biriktirip tam sayıya ulaştıkça kazandıracak şekilde yeniden yazıldı. Böylece **Taş Maske** (+%20 Altın) ve **Bilgelik Tacı** (+%12 XP) 1. ve 2. seviyelerde tekli kristal/altınlarda da kuruşu kuruşuna etki etmeye başladı.

### 2.2. Maksimum Seviye ve Boş Kart Koruması
- **Düzeltme:** [`level_up_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/level_up_menu.gd) içinde `passive_carbon_paper` (Çoğaltıcı Mühür) ve `passive_eraser_backup` (Diriliş Tılsımı) için `max_level: 2` kuralı bağlandı.
- Tüm silah ve pasifler maksimuma ulaştığında oyunun çökmesini veya geçersiz silah üretmesini engellemek için havuz boşaldığında oyuncuya anında **Şifa İksiri** (+35 HP) veya **Altın Kesesi** (+50 Altın) sunan tüketilebilir ödül sistemi eklendi; [`player.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/player.gd) `type == "consumable"` verisini uygulayacak şekilde genişletildi.
- Seviye atlama kartlarındaki `(+%%35)` biçimlendirme hatası `(+%35)` olarak düzeltildi.

### 2.3. İksir Şişesi ve Büyü Kitabı Mekanik Yenilenmesi
- **Simya İksiri ([`weapon_potion.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/weapon_potion.gd)):**
  - Artık `extra_projectiles` (Miktar) istatistiğine göre tek seferde birden fazla şişe fırlatıyor.
  - Zemin görseli kırılmamış şişe yerine zehirli mor gölet efekti (`proj_ink_splash.png`) ile değiştirildi.
  - Sadece ilk düşüşte değil, yerde kaldığı süre boyunca her 0.4 saniyede bir periyodik alan hasarı (DoT) vuracak şekilde güncellendi. Böylece **Kadim Kum Saati (Süre)** pasifi iksirin toplam hasarını doğrudan katlar hale geldi.
- **Büyü Kitabı ([`weapon_spellbook.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/weapon_spellbook.gd)):**
  - `extra_projectiles` istatistiğine göre oyuncunun etrafında eşit açılarla dönen 2, 3, 4 kitap halkası oluşturma desteği eklendi.
  - Sadece `body_entered` anında değil, kitabın yörüngesinde kalan veya içeride yürüyen düşmanlara her 0.35 saniyede bir düzenli temas hasarı vuracak kontrol eklendi.

### 2.4. Mermi ve Menzilli Silah Hataları
- **Avcı Yayı ([`proj_arrow.tscn`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scenes/weapons/proj_arrow.tscn)):** `max_pierce = 3` atanarak delici ok niteliği aktif edildi.
- **Ölü Düşman Koruması:** [`bullet.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/bullet.gd), [`proj_sword.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/proj_sword.gd), [`proj_axe.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/proj_axe.gd) ve [`boomerang_projectile.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/boomerang_projectile.gd) dosyalarına `if "is_dead" in body and body.is_dead: return` koruması eklendi; aynı karede ölen düşmanların arkadan gelen mermilerin delme haklarını yutması engellendi.
- **Balta ([`proj_axe.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/proj_axe.gd)):** Azami menzilde her fizik karesinde tween spam'i yapması `is_fading` bayrağıyla engellendi.
- **Menzilli Silahlar ([`weapon_ranged.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/weapon_ranged.gd)):** Geri tepme sırasında sprite ofsetinin `0.0`'a sıfırlanması önlendi, `SECTOR` modunda yuva açısı `get_parent().position.angle()` ile düzeltildi ve her karede çalışan ağır dizi sıralaması 0.12 saniyede bire düşürülerek optimize edildi.

### 2.5. Kalıcı Kritik Şans ve Yuva Sayısı
- **Kritik Şans:** [`player.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/player.gd) içine `base_crit_chance` eklendi; Atölyeden alınan kalıcı kritik şansı [`meta_progression.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/meta_progression.gd) tarafından bu tabana yazılıyor ve oyun içi Şanslı Yonca alındığında kalıcı şans korunuyor.
- **6. Silah Yuvası:** [`player.tscn`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scenes/player/player.tscn) içine `Slot6_Bottom` eklenerek UI'daki 6 silah yuvası ile fiziksel düğüm sayısı eşitlendi.
- **XP ve Altın Yarış Durumu:** [`xp_gem.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/xp_gem.gd) ve [`coin_pickup.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/coin_pickup.gd) dosyalarına `is_collected` ve `is_absorbed` bayrakları eklenerek çift toplama ve karşılıklı silinme yarış durumları giderildi.

---

## 3. Görsel Derinlik (YSort), Tema ve Performans

### 3.1. YSort Derinlik Sıralaması
- [`player.tscn`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scenes/player/player.tscn) üzerindeki sabit `z_index = 10` ve sprite üzerindeki `z_index = 12` kaldırıldı.
- [`main.tscn`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scenes/world/main.tscn) kök düğümüne `y_sort_enabled = true` verildi. Artık oyuncu ağaçların ve kayaların arkasından geçerken doğru şekilde arkada, önünden geçerken önde çizilmektedir.

### 3.2. Kırtasiye / Kağıt Teması Kalıntılarının Temizlenmesi
- [`meta_progression.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/meta_progression.gd): *"Kurşun Kalem Ucu"*, *"Hızlı Silgi"*, *"Dev Mıknatıs"*, *"Mürekkep Zırhı"* terimleri -> **"Savaş Gücü"**, **"Çeviklik"**, **"Çekim Küresi"**, **"Kritik Vuruş"**, **"Şövalye Zırhı"** olarak fantezi RPG diline çevrildi.
- [`shop_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/shop_menu.gd): *"GELİŞTİR (%d Ataş)"* -> **"GELİŞTİR (%d Altın)"** yapıldı.
- [`game_over_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/game_over_menu.gd): *"KAĞIT YIRTILDI"*, *"Çizim masasına kısa bir mola"*, *"mürekkebi tükendi"* -> **"YENİLGİ"**, **"Maceraya kısa bir mola"**, **"Karanlık ordulara yenik düştün"** olarak güncellendi.
- [`level_up_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/level_up_menu.gd) ve [`inventory_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/inventory_menu.gd): *"Doodle Zırhı"* -> **"Şövalye Zırhı"** yapıldı.

### 3.3. Performans İyileştirmeleri
- [`enemy_base.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/enemy_base.gd) içindeki çevre engeli taraması yalnızca yer birimleri için (`(collision_mask & 4) != 0`) çalışacak şekilde sınırlandı; uçan ve hayalet birimlerdeki gereksiz raycast yükü kaldırıldı.
- [`weapon_ranged.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/weapon_ranged.gd) hedef sıralama algoritması kare başı çalışmaktan çıkartılıp 0.12 saniyelik zamanlayıcıya bağlandı.

---

## 4. Doğrulama ve Test Sonuçları
- Godot 4.7 headless editör taraması (`godot --headless --editor --quit`): **Hata yok, sıfır uyarı.**
- Godot 4.7 headless çalışma testi (`godot --headless --quit-after 60`): **Başarıyla tamamlandı (Çıkış kodu: 0).**
