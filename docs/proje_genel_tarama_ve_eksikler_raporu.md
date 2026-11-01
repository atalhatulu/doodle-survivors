# Doodle Survivors — Kapsamlı Proje Taraması, Hata Denetimi ve Geliştirme Yol Haritası

Projedeki 25 GDScript dosyası, 31 sahne (`.tscn`) dosyası ve proje yapılandırması baştan sona taranmıştır. Aşağıda oyunun mevcut durumundaki **kritik hatalar, mekanik kopukluklar, denge sorunları, tematik kalıntılar ve geliştirilmesi gereken noktalar** öncelik sırasıyla listelenmiştir.

---

## 1. Acil Çözülmesi Gereken Kritik Hatalar (Oynanışı Bozanlar)

### 1.1. 5. Dakika Boss'unun Oyunu Erken Bitirmesi
- **Sorun:** [`enemy_spawner.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/enemy_spawner.gd#L55-L60) hem 5. dakikada hem 10. dakikada `_spawn_boss()` çağırıyor. Her iki boss da öldüğünde `king_boss_defeated` sinyalini tetikliyor ve [`game_manager.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/game_manager.gd#L64-L77) oyunu zafer ekranıyla bitiriyor.
- **Sonuç:** Oyuncu 5. dakika boss'unu kestiği anda oyun bitiyor; 6–20. dakikalar için yazılan düşman dalgaları ve XP eğrisi hiçbir zaman oynanamıyor.
- **Çözüm:** Ara boss'lar (5., 10., 15. dk) sadece çoklu sandık ve yüksek XP düşürmeli; oyunu bitiren sinyal yalnızca 20. dakika Final Boss'una bağlanmalı.

### 1.2. Normal Düşman Renk ve Boyut Varyantlarının Hiç Çalışmaması
- **Sorun:** [`enemy_spawner.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/enemy_spawner.gd#L243-L246) içinde `enemy.set_variant(tint_color, scale_bonus)` çağrısı, düşman sahne ağacına eklenmeden (`_add_enemy_to_scene`) **önce** yapılıyor. Düşman henüz sahnede olmadığı için `@onready var sprite: Sprite2D = $Sprite2D` değişkeni `null` oluyor. Ardından düğüm sahneye eklendiğinde çalışan `_ready()` fonksiyonu ([`enemy_base.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/enemy_base.gd#L34-L36)) `base_modulate` ve `base_scale` değerlerini sıfırlıyor.
- **Sonuç:** 3., 6. ve 10. dakikalarda devreye girmesi gereken Turuncu, Kızıl ve Mor düşman formlarının görsel renk/boyut değişimleri oyun içinde hiç görünmüyor.
- **Çözüm:** `set_variant()` çağrısı `_add_enemy_to_scene(enemy)` satırından sonraya alınmalı veya `_ready()` içinde `set_variant` değerleri korunmalı.

### 1.3. ESC ve TAB Tuş Çakışmaları / Duraklatma (Pause) Kilitlenmeleri
- **ESC ile Pause Menüsünün Kapanmaması:** [`game_over_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/game_over_menu.gd#L24-L34) ve [`game_manager.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/game_manager.gd#L25-L36) aynı `ui_cancel` (ESC) girdisini `set_input_as_handled()` olmadan dinliyor. Oyun duraklatılmışken ESC'ye basıldığında `GameOverMenu` menüyü kapatıp `paused = false` yapıyor, aynı karede üst düğüm `Main` artık duraklatma kalktığı için girdiyi alıp menüyü anında geri açıyor.
- **Envanter Açıkken ESC Basınca Oyunun Bozulması:** Envanter (`TAB`) açıkken ESC'ye basıldığında önce `GameOverMenu` devreye girip Pause menüsünü açıyor, hemen ardından `InventoryMenu` çalışıp envanteri kapatırken `get_tree().paused = false` yapıyor. Ekranda "OYUN DURAKLATILDI" yazısı asılı kalırken arka planda oyun akmaya devam ediyor.
- **Seviye Atlama / Ölüm Ekranında TAB Açığı:** Seviye atlama kartları veya ölüm ekranı açıkken oyuncu TAB'a basıp envanteri açıp kapatırsa `get_tree().paused = false` tetikleniyor ve kartlar ekrandayken oyun arka planda çalışmaya devam ediyor.
- **TAB Tuşunun İki İşleve Birden Bağlı Olması:** `KEY_TAB` hem envanter açma (`project.godot`) hem de 2x oyun hızı (`hud.gd`) için tanımlanmış durumda.

### 1.4. Kamera Yakınlaştırması (`0.7`) yüzünden Düşmanların Ekran İçinde Doğması
- **Sorun:** [`player.tscn`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scenes/player/player.tscn#L53) içinde kamera `zoom = Vector2(0.7, 0.7)` olarak ayarlı. `1280x720` çözünürlükte `0.7` zoom ile kameranın gördüğü alan `1828x1028` pikseldir (merkezden sağa/sola `914px`, köşelere `1049px`). Ancak [`enemy_spawner.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/enemy_spawner.gd#L10-L11) düşmanları `850–950px` mesafede doğuruyor.
- **Sonuç:** Düşmanlar ekranın sol/sağ kenarlarında ve köşelerinde oyuncunun gözü önünde yoktan var oluyor. Ayrıca [`bullet.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/bullet.gd#L30) ve [`proj_sword.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/proj_sword.gd#L25) içindeki `1000px` silinme sınırı nedeniyle çapraz giden mermiler ekran köşesinden çıkmadan yok oluyor.
- **Çözüm:** Doğma mesafesi `1100–1250px` aralığına, mermi silinme mesafesi `1200px` değerine, uzaktaki düşmanları taşıma mesafesi ise `1550px` değerine çekilmeli.

---

## 2. Mekanik ve Matematiksel Denge Kusurları

### 2.1. Yuvarlama (`round`) Yüzünden XP ve Altın Pasiflerinin İlk Seviyelerde Çalışmaması
- **Altın (`Taş Maske` / `Lanetli Kuru Kafa`):** Normal altınların değeri `1`'dir. [`player.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/player.gd#L407) içinde `round(1 * 1.20) = 1` ve `round(1 * 1.44) = 1` olduğu için **Taş Maske'nin 1. ve 2. seviyeleri normal altınlarda %0 artış sağlar**. 3. seviyede (`1.728`) bir anda `2` altına (%100 artış) fırlar, 4. ve 5. seviyelerde ise yine hiçbir fark yaratmaz.
- **XP (`Bilgelik Tacı` / `Lanetli Kuru Kafa`):** Çoğu düşman `3` XP bırakır. `round(3 * 1.12) = round(3.36) = 3` olduğu için **Bilgelik Tacı 1. seviyede tekli XP kristallerinde hiçbir etki yapmaz**.
- **Çözüm:** `player.gd` içinde küsuratlı XP (`xp_remainder: float`) ve küsuratlı altın (`coin_remainder: float`) biriktiricisi tutulmalı; böylece her `%12` veya `%20` artış kuruşu kuruşuna oyuncuya yansımalı.

### 2.2. `Çoğaltıcı Mühür` ve `Diriliş Tılsımı`nda 3., 4. ve 5. Seviyelerin Boş Olması
- **Sorun:** [`player.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/player.gd#L327) `extra_projectiles` ve `revives_remaining` değerlerini `mini(2, ...)` ile maksimum 2'de sınırlıyor. Ancak [`level_up_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/level_up_menu.gd#L312) tüm pasifleri 5. seviyeye kadar havuzda tutuyor.
- **Sonuç:** Oyuncu bu iki eşyayı Seviye 3, 4 ve 5'e yükselttiğinde hiçbir özellik kazanmıyor ve 3 seviye atlama hakkı boşa gidiyor.
- **Çözüm:** Her pasifin kendi maksimum seviyesi (`max_level: 2` veya `5`) tanımlanmalı ya da Seviye 3-5 arasında bu eşyalara ek yan bonuslar (ör. Çoğaltıcı Mühür tek seviyelerde +1 mermi, çift seviyelerde +%10 atış hızı; Diriliş Tılsımı dirilme başına +20 maksimum can / zırh) verilmeli.

### 2.3. İksir Şişesi (`weapon_potion.gd`) ve Büyü Kitabı (`weapon_spellbook.gd`) Eksikleri
- **İksir Şişesi Süre Hatası:** [`weapon_potion.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/weapon_potion.gd#L94-L119) yere düştükten `0.05` sn sonra tek bir kez hasar vuruyor, yerde kaldığı süre boyunca periyodik alan hasarı (DoT) vermiyor. Bu yüzden **Kadim Kum Saati (`duration_mult`) İksir Şişesi'nin hasarına hiçbir katkı sağlamıyor**, sadece yerdeki şişe resminin geç silinmesine yol açıyor. Ayrıca yerde birikinti görseli (`proj_ink_splash.png` vb.) yerine kırılmamış şişe görseli (`weapon_potion.png`) duruyor.
- **Büyü Kitabı Sürekli Temas Hatası:** [`weapon_spellbook.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/weapon_spellbook.gd#L68-L84) yalnızca `body_entered` sinyalini dinliyor. Büyük bir elit veya boss kitabın içinde kalmaya devam ederse `0.4` saniyelik bekleme süresi dolsa bile ikinci kez hasar almıyor.
- **Ekstra Mermi (`extra_projectiles`) Uyumsuzluğu:** Büyü Kitabı (dönen kitap sayısı) ve İksir Şişesi (aynı anda fırlatılan şişe sayısı) `extra_projectiles` istatistiğinden hiç etkilenmiyor.

### 2.4. Menzilli Silahlar ve Mermi Fizik Hataları
- **Avcı Yayı (`proj_arrow.tscn`) Delicilik Eksikliği:** Açıklamasında `"delici oklar fırlatır"` yazmasına rağmen `max_pierce = 1` olduğu için ilk düşmana çarptığında yok oluyor.
- **Sektör (`SECTOR`) Hedefleme Hatası:** [`weapon_ranged.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/weapon_ranged.gd#L133) `position.angle()` değerine bakıyor; ancak silahın kendi yerel konumu `Vector2.ZERO` olduğu için açı her zaman `0.0` (sağ yön) çıkıyor. Doğrusu `get_parent().position.angle()` olmalıdır.
- **Geri Tepme (Recoil) Kayması:** [`weapon_ranged.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/weapon_ranged.gd#L202-L203) ateş edildiğinde `sprite.position.x` değerini `0.0`'a sıfırlayarak sahnede ayarlanan `15..28px` silah ofsetini bozuyor.
- **Ölü Düşmanların Mermi Yutması:** Aynı karede çoklu mermi atıldığında ilk mermi düşmanı öldürse bile çarpışma katmanı kare sonunda (`set_deferred`) kapandığı için arkadan gelen diğer mermiler aynı ölü düşmana çarparak delme haklarını kaybediyor (`if body.is_dead: return` kontrolü eksik).

### 2.5. Kalıcı Gelişim (`MetaProgression`) ve Silah Yuvası Tutarsızlıkları
- **Kalıcı Kritik Şansın Ezilmesi:** Atölyeden satın alınan kalıcı kritik şansı, oyun içinde `Şanslı Yonca` alındığında [`player.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/player.gd#L322) içindeki sabit `0.05 + (luck_mult - 1.0) * 0.4` formülüyle sıfırlanıyor.
- **Silah Yuvası Sayısı (5 vs 6):** Envanter ekranında `Maks 6` yazmasına rağmen [`player.tscn`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scenes/player/player.tscn#L56-L76) içinde sadece 5 adet `Marker2D` silah yuvası bulunuyor.
- **XP Kristali Birleşmesi (`xp_gem.gd`) Yarış Durumu:** Aynı karede birleşen iki kristal birbirini silebiliyor veya aynı anda hem fizik sinyali hem mesafe kontrolü tetiklenirse çift toplanabiliyor (`is_collected` / `is_absorbed` bayrağı eksik).

---

## 3. Görsel Sıralama (YSort), Tema Temizliği ve Performans

### 3.1. `YSort` ve `z_index` Hatası
- [`main.tscn`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scenes/world/main.tscn) içinde `ChunkManager` (ağaçlar, kayalar) ve `YSortEntities` (oyuncu, düşmanlar) ayrı düğümlerdir ve `Player.z_index = 10` verilmiştir. Bu yüzden oyuncu ve düşmanlar ağaçların arkasından geçerken bile her zaman ağaçların tepesinde çizilir.

### 3.2. Kalan Kırtasiye / Kağıt Teması Kalıntıları
Pasif eşyaların isimleri ve ikonları fantezi temasına geçirilmiş olsa da aşağıdaki dosyalarda hâlâ kırtasiye/kağıt terimleri yer almaktadır:
- [`meta_progression.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/meta_progression.gd#L19-L55): *"Keskin Kalem Ucu"*, *"Kalın Karton Zırh"*, *"seri çizim"*, *"ataş çekim alanı"*.
- [`shop_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/shop_menu.gd#L121) ve [`main_menu.tscn`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scenes/ui/main_menu.tscn#L127): *"DÜKKAN (KALICI KIRTASİYE)"*, *"Toplam Ataş"*.
- [`game_over_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/game_over_menu.gd#L39-L52): *"MÜREKKEP BİTTİ!"*, *"Kağıt kesiklerine yenik düştün"*, *"Kazanılan Ataş"*.
- [`level_up_menu.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/level_up_menu.gd#L131): `"Doodle Zırhı"`.
- Altın görseli: `coin_paperclip.png` (ataş görseli yerine altın sikke kullanılmalı).

### 3.3. Performans İyileştirme Noktaları
- **Uçan/Hayalet Düşmanlarda Gereksiz Raycast:** [`enemy_base.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/enemy_base.gd#L116) içinde engellerden geçebilen hayalet ve yarasa düşmanlar bile her fizik karesinde çevre engelleri için raycast sorgusu yapıyor (ve engellerin etrafından dolaşıyor).
- **Her Karede Hedef Sıralama:** [`weapon_ranged.gd`](file:///home/teha/Documents/GitHub/Godot/doodle-survivors/scripts/weapon_ranged.gd#L63) her `_process` karesinde tüm düşman dizisini kopyalayıp `sort_custom` ile sıralıyor; bunun yerine hedef arama periyodu (`0.15` sn) veya yalnızca atış anında sıralama yapılmalı.

---

## 4. Eksik Olan ve Oyunu Büyütecek Geliştirme Alanları (Yol Haritası)

1. **Mermi Fırlatmayan Yeni Silah Arketipleri:**
   - **Ruhani Kurt (Minion/Çağrı):** Sahada bağımsız gezip düşmanları ısıran yoldaş.
   - **Ejderha Nefesi (Sürekli Koni Alevi):** Baktığın yöne kesintisiz alev püskürten yakın/orta menzil silahı.
   - **Hiçlik Girdabı (Kitle Kontrolü / Kara Delik):** Düşmanları merkeze vakumlayıp patlayan alan büyüsü.
   - **Deprem / Savaş Narası (360 Derece Şok Dalgası):** Karakterin etrafındaki düşmanları ezen ve geri savuran darbe.
2. **Silah Evrim (Evolution) Sistemi:**
   - Seviye 7'ye ulaşmış bir silah + ilgili pasif eşya tamamlandığında, elit/boss sandığından çıkan özel evrim kartıyla silahın nihai forma dönüşmesi.
3. **Seviye Atlama Ekranı (3 Kart Yan Yana Seçim):**
   - Mevcut tekli kart ("1. Şans -> Geç -> 2. Şans -> Mecburi Al") yapısı oyuncuya 3 seçeneği aynı anda karşılaştırma imkanı vermiyor. Klasik 3 kartın yan yana göründüğü ve oyuncunun doğrudan istediğini seçtiği düzen çok daha akıcıdır.
4. **Harita ve Biyom Çeşitliliği / Dinamik Olaylar:**
   - Kırılabilir çevre nesneleri (içinden iyileştirme iksiri, altın kesesi veya tüm ekranı çeken mıknatıs çıkan fıçılar/mezar taşları).
   - Belirli dakikalarda gerçekleşen özel dalga olayları (ör. 4. dakikada yarasa sürüsü çemberi, 8. dakikada elit muhafız kuşatması).
5. **Karakter Seçim Ekranı:**
   - Farklı başlangıç silahına ve kendine has pasif stat bonusuna sahip seçilebilir karakterler (ör. Şövalye: Kılıç ile başlar +%20 Zırh; Büyücü: Asa ile başlar +%20 Alan; Avcı: Yay ile başlar +%20 Hareket Hızı).
