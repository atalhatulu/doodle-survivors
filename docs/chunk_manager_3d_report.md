# 3D Sonsuz Usulsüz Dünya (Chunk Manager 3D) Raporu

## 1. Sistemin Mimarisi ve Amacı
2D sürümdeki sonsuz procedural grid mekaniği (`scripts/chunk_manager.gd`), 3D uzaya (`scripts/chunk_manager_3d.gd`) aktarılmıştır.

- **Chunk Boyutu ve Izgara:** `CHUNK_SIZE = 48.0` metre ve `CHUNK_RADIUS = 2` olarak yapılandırılmıştır. Oyuncunun etrafında sürekli aktif bir 5x5 (toplam 25 adet) `Node3D` chunk havuzu tutulur.
- **Takip Mantığı:** Oyuncunun X ve Z düzlemindeki konumu `Vector2i(int(floor(player.global_position.x / CHUNK_SIZE)), int(floor(player.global_position.z / CHUNK_SIZE)))` ile izlenir. Oyuncu bir chunk sınırını geçtiğinde ihtiyaç duyulan yeni koordinatlar yüklenir, geride kalan uzak chunk'lar bellekten silinir (`queue_free`).
- **Zemin & Dikişsiz Shader:** Her chunk kendi 48x48m `PlaneMesh` zeminine sahiptir. Ortak `ground_terrain.gdshader` materyali dünya koordinatlarına göre (`(INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz`) hesaplama yaptığı için chunk sınırlarında hiçbir dikiş izi veya ek yeri oluşmaz; çim, nemli toprak, patika ve mikro varyasyonlar arazi boyunca kesintisiz akar.

## 2. Deterministik Dağılım ve Engel Yönetimi
- **Tohum (Seed):** Her chunk `(coord.x * 73856093) ^ (coord.y * 19349663)` formülüyle bağımsız ve deterministik olarak üretilir.
- **Güvenli Alan (Safe Zone):** Başlangıç konumu `(0, 0, 0)` etrafındaki 6.5 metre yarıçaplı dairesel alana hiçbir engel yerleştirilmez. Oyuncu doğduğu anda ferah ve güvenli bir hareket alanına sahip olur.
- **Nesne ve Engel Havuzu:**
  - **Kırılabilir Nesneler:** 2-4 adet ahşap fıçı (`barrel_3d.tscn`), testi (`jar_3d.tscn`) veya mezar taşı (`grave_3d.tscn`).
  - **Fenerler:** Işık saçan ruh fenerleri (`lantern_3d.tscn`).
  - **Kayalar ve Sütunlar:** Gri kayalar (`rock_3d.tscn`) ve antik harabe sütunları (`ruin_pillar_3d.tscn`).
  - **Orman:** Devasa kadim ağaçlar (`giant_tree_3d.tscn`), meşe ağaçları (`tree_3d.tscn`) ve çamlar (`pine_3d.tscn`).
  - **Zemin Süsleri:** Işıltılı zambaklar (`flower_3d.tscn`) ve çimen öbekleri (`grass_clump_3d.tscn`).
  - **Kadim Sunaklar:** Nadir olarak (%20 şans) başlangıç dışındaki chunk'larda beliren runik sunaklar (`shrine_3d.tscn`).

## 3. Sahne Entegrasyonu (`main_3d.tscn`)
- Eski statik 400x400m tek parça `GroundMesh` kaldırılmış, yerine `ChunkManager3D` düğümü eklenmiştir.
- Fizik bütünlüğü ve düşme koruması için `InfiniteGroundCollision` (`WorldBoundaryShape3D`) korunmuştur.
- `main_3d.gd` içerisindeki tek seferlik statik obstacle spawn döngüsü kaldırılarak tüm çevre üretimi `ChunkManager3D`'ye devredilmiş, çakışma ve çift spawn engellenmiştir.

## 4. Test ve Doğrulama
- `godot --headless -s scripts/test_combat_3d.gd` çalıştırılmış, 10 sistemin tümü hatasız geçmiştir.
- `godot --headless -s scripts/test_phases_headless.gd` çalıştırılmış, 15 testin tamamı başarılı olmuştur.
- `godot --rendering-driver vulkan -s scripts/capture_true_3d_screenshot.gd` çalıştırılmış ve güncellenen dikişsiz zemin görüntüsü `docs/test_true_3d_tps.png` dosyasına kaydedilmiştir.
