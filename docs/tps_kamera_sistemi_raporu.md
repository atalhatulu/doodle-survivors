# TPS Kamera ve Papercraft Karton Perspektif Raporu

## 1. Genel Bakış ve Amaç
Masaüstündeki prototip (`shadow_forest_papercraft_tps_survivors.html`) referans alınarak Godot projesindeki kamera sistemi ve 2.5D derinlik mimarisi TPS (omuz üstü / arkadan takip) perspektifine uyarlandı.

## 2. Yapılan Değişiklikler ve Matematiksel Uyum

### A. TPS Over-The-Shoulder Kamera Dinamiği (`scripts/player.gd`)
- Prototip HTML Three.js parametreleri:
  - `tpsDistance = 11`, `tpsHeight = 6.8`, `lookTarget.y += 2.2`, `cameraAngleX = (dx / innerWidth) * 1.6`.
- Godot Kamera Entegrasyonu:
  - `tps_target_offset = Vector2(0.0, -90.0)` ile karakterin arkasından hafif yukarı ufuk çizgisine bakan omuz üstü perspektif tabanı oluşturuldu.
  - Farenin ekran merkezine olan bağıl açısına bağlı olarak (`dx/width`, `dy/height`) yumuşak interpolasyonlu dinamik nişan alma ve ufuk önlemesi (`tps_look_lead`) eklendi.
  - Ekran sarsıntısı (`trauma`), TPS ofset değerinin üzerine additive olarak eklendi; böylece vuruş hissi bozulmadan kameraya yansıtıldı.

### B. Papercraft Karton Zemin ve Işık Dengelemesi (`scripts/chunk_manager.gd`)
- HTML prototipindeki koyu karton elyafı ve karanlık orman atmosferi (`#0f1712`, `#1c2820`) tonuna sadık kalınarak dinamik chunk zemin modülasyonu karanlık orman karton dokusuna (`Color(0.24, 0.32, 0.26)`) çekildi.
- Beyaz kalıp kesim (die-cut sticker outline) konturlu karakterler, düşmanlar, ağaçlar, kayalar ve altın sikkeler, koyu karton zemin üzerinde derinlik kazandı.

## 3. Doğrulama ve Testler
- `godot --headless -s scripts/test_phases_headless.gd`: 15/15 test hatasız geçti.
- `godot --rendering-driver opengl3 -s scripts/capture_verification_screenshots.gd`: Ekran görüntüleri alındı ve görsel açı teyit edildi (`docs/test_tps_gameplay.png`).
