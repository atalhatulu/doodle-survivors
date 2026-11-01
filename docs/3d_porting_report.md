# 3D Sistem Entegrasyonu & 5 Temel Fazın Port Raporu

## 1. 3D Dalga & Boss Sistemi (`scripts/enemy_spawner_3d.gd`)
- 2D versiyondaki 20 dakikalık aşamalı dalga temposu 3D uzaya aktarıldı.
- 12 farklı canavar arketipi (Eyeball, Noodles, Bee, Chomper, Snail, Brute Cyclops, Ghost, Bat, Frog, Flower, Wing Eye, King) ve dakika bazlı spawn havuzları eklendi.
- Her 60 saniyede bir altın auralı, can ve hasarı dakikaya göre ölçeklenen Elit Canavar doğumu sağlandı.
- 4., 8. ve 14. dakikalarda özel kuşatma etkinlikleri (Yarasa Akını, Demir Çember, Gölge Hücumu) entegre edildi.
- 5., 10., 15. dakikalarda Bölge Lordları, 20. dakikada ise Kadim Taçlı Kral boss karşılaşması tanımlandı.
- Oyuncudan aşırı uzaklaşan canavarların (`despawn_reposition_distance: 55m`) oyuncunun hareket yönüne doğru öne taşınması mekanizması eklendi.

## 2. 3D Hazine Sandığı & Silah Evrimi (`scenes/pickups/chest_3d.tscn`, `scripts/chest_3d.gd`)
- Elit canavarlar ve boss'lar öldüğünde %100 kesinlikle 3D Hazine Sandığı (`Chest3D`) düşürmesi sağlandı (`scripts/enemy_3d.gd`).
- Sandık açıldığında oyuncunun şans katsayısına (`luck_mult`) göre 1 ile 3 adet seviye atlama/evrim kartı tetiklenir (`LevelUpMenu.show_level_up_options(true)`).
- Seviye 7 olan silahlar ve gerekli pasif eşyalar envanterde bulunduğunda, sandık doğrudan Efsanevi Silah Evrimini havuza dahil eder.

## 3. 3D Hasar Sayıları (`scenes/ui/damage_number_3d.tscn`, `scripts/damage_number_3d.gd`)
- Canavarlar (`Enemy3D`) veya kırılabilir variller (`Barrel3D`) hasar aldığında 3D dünyada vuruş noktasında uçuşan, zıplayan ve sönümlenen hasar göstergesi eklendi.
- Kamera açısına göre otomatik yönlenen (`billboard = 1`), derinlik testi arkasında kaybolmayan (`no_depth_test = true`), normal vuruşlarda mürekkep siyahı, kritik vuruşlarda kırmızı/turuncu ünlemli stil uygulandı.
- `MetaProgression` ayarlarındaki `show_damage_numbers` seçeneğine bağlandı.

## 4. 3D Kadim Sunak & Lanet Paktı (`scenes/world/shrine_3d.tscn`, `scripts/shrine_3d.gd`)
- 3D dünyada oyuncu yaklaştığında (`radius = 3.5m`) görünür olan `[E] Kadim Sunak` 3D bilgi etiketi oluşturuldu.
- Oyuncu yaklaşıp `E` veya kabul tuşuna bastığında zaman durdurularak 3 lanet paktı seçeneği sunulur:
  1. Kan Paktı (%35 Can feda -> +%20 Hasar, +%15 Kritik)
  2. Açgözlülük Paktı (%25 Düşman Akını -> 2 Kat Altın)
  3. Ruh Paktı (-15 Maks Can -> +1 Yeniden Doğma Hakkı)
- Pakt mühürlendiğinde sunak efektle yok olur ve oyuncu statlarına anında yansır.

## 5. Görüş & Kamera Saydamlığı (`scripts/obstacle_transparency_3d.gd`, `scripts/player_3d.gd`)
- Ağaçlar (`tree_3d.tscn`), çamlar (`pine_3d.tscn`) ve kayalar (`rock_3d.tscn`) için saydamlık kontrol scripti oluşturuldu ve `camera_fading_obstacles` grubuna eklendi.
- `Player3D._update_camera_obstacles_transparency()` fonksiyonu üzerinden `Camera3D` ile oyuncu gövdesi arasına giren engeller fizik raycast ile tespit edilir.
- Görüşü kapatan engeller `alpha: 0.25` seviyesine akıcı şekilde solarken, aradan çıkınca tekrar `alpha: 1.0` değerine geri döner.
