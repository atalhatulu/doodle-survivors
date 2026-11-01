extends SceneTree

# Kapsamlı 3D Grid & Chunk Sistemi Denetim Testi (Audit Test)

var step: int = 0
var timer: float = 0.0
var main3d: Node = null
var cm: Node = null
var player: Node = null

func _init() -> void:
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	if step == 0:
		step = 1
		print("==================================================")
		print("DOODLE SURVIVORS: GRID & CHUNK 3D AUDIT TESTI")
		print("==================================================")
		
		var main_scene = load("res://scenes/world/main_3d.tscn")
		assert(main_scene != null, "HATA: main_3d.tscn yuklenemedi!")
		main3d = main_scene.instantiate()
		root.add_child(main3d)
		
		cm = main3d.get_node_or_null("ChunkManager3D")
		assert(cm != null, "HATA: ChunkManager3D dugumu main_3d icinde bulunamadi!")
		player = main3d.get_node_or_null("Player3D")
		assert(player != null, "HATA: Player3D dugumu main_3d icinde bulunamadi!")
		return

	timer += 0.016
	
	if step == 1 and timer > 0.2:
		step = 2
		# Test 1: Baslangic Chunk Olusumu (5x5 = 25 Chunk)
		var initial_chunk_count = cm.loaded_chunks.size()
		print("[AUDIT 1] Baslangic Yuklenen Chunk Sayisi: %d" % initial_chunk_count)
		assert(initial_chunk_count == 25, "HATA: 5x5 grid (CHUNK_RADIUS=2) 25 chunk yuklemeli!")
		assert(cm.loaded_chunks.has(Vector2i.ZERO), "HATA: Merkez chunk (0,0) yuklenmedi!")
		print("  -> [PASS] 5x5 Baslangic grid yapisi dogrulandi.")

		# Test 2: Guvenli Baslangic Bolgesi (Safe Zone Audit)
		var solid_count_in_spawn = 0
		for coord in cm.loaded_chunks:
			var ch = cm.loaded_chunks[coord]
			for child in ch.get_children():
				if child is StaticBody3D or child is Area3D:
					var world_dist = child.global_position.length()
					if world_dist < 4.0:
						print("    [COLLISION NEAR SPAWN]: %s at %s (dist: %f)" % [child.name, child.global_position, world_dist])
						solid_count_in_spawn += 1
		print("[AUDIT 2] Baslangic (0,0,0) 4m Guvenli Alandaki Katı Nesne Sayisi: %d" % solid_count_in_spawn)
		assert(solid_count_in_spawn == 0, "HATA: Oyuncunun hemen dibine katı nesne spawn olmus!")
		print("  -> [PASS] Oyuncu spawn alani guvenli ve engelsiz.")

		# Test 3: Koordinat Donusum Matematigi (Negative & Boundary Audit)
		var test_points = [
			Vector3(0, 0, 0), Vector2i(0, 0),
			Vector3(24, 0, 24), Vector2i(0, 0),
			Vector3(47.9, 0, 47.9), Vector2i(0, 0),
			Vector3(48.0, 0, 0), Vector2i(1, 0),
			Vector3(-0.1, 0, 0), Vector2i(-1, 0),
			Vector3(-48.0, 0, -48.0), Vector2i(-1, -1),
			Vector3(-48.1, 0, -48.1), Vector2i(-2, -2),
			Vector3(120.0, 0, -180.0), Vector2i(2, -4)
		]
		for i in range(0, test_points.size(), 2):
			var pos: Vector3 = test_points[i]
			var expected: Vector2i = test_points[i+1]
			var calc: Vector2i = cm._world_to_chunk(pos)
			assert(calc == expected, "HATA: Koordinat donusumu hatali! Pos: %s -> Beklenen: %s, Hesaplanan: %s" % [pos, expected, calc])
		print("  -> [PASS] Negatif ve pozitif sonsuz koordinat donusum matematigi kusursuz.")

		# Test 4: Dinamik Hareket, Chunk Yukleme/Bosaltma (Memory Leak & Churn Audit)
		player.global_position = Vector3(150.0, 0.0, 0.0)
		var new_chunk = cm._world_to_chunk(player.global_position)
		assert(new_chunk == Vector2i(3, 0), "HATA: Oyuncu yeni chunk'a gecemedi!")
		cm.current_player_chunk = new_chunk
		cm._update_chunks(false)
		
		var moved_chunk_count = cm.loaded_chunks.size()
		print("[AUDIT 4] Oyuncu 150m Doguya Yurdukten Sonra Yuklenen Chunk Sayisi: %d" % moved_chunk_count)
		assert(moved_chunk_count == 25, "HATA: Chunk sayisi dinamik yukleme sonrasi 25'te sabit kalmadi! (Hafiza sizintisi riski)")
		assert(not cm.loaded_chunks.has(Vector2i.ZERO), "HATA: Geride kalan eski merkez chunk (0,0) bellekten silinmedi!")
		assert(cm.loaded_chunks.has(Vector2i(3, 0)), "HATA: Oyuncunun yeni merkez chunk'i (3,0) yuklenmedi!")
		print("  -> [PASS] Dinamik yukleme/bosaltma (culling/freeing) 25 chunk sabitligiyle dogrulandi.")

		# Test 5: LOD (Level of Detail) Mesafe Katmanlari Denetimi
		player.global_position = Vector3(0.0, 0.0, 0.0)
		cm.current_player_chunk = Vector2i.ZERO
		cm._update_chunks(false)
		cm._update_lod_and_culling()
		
		var center_group = cm.chunk_lod_groups[Vector2i.ZERO]
		var small_visible = true
		for s in center_group["small"]:
			if is_instance_valid(s) and not s.visible:
				small_visible = false
		assert(small_visible, "HATA: Oyuncunun hemen yanindaki kucuk LOD nesneleri gorunur olmali!")
		
		var far_group = cm.chunk_lod_groups[Vector2i(2, 2)]
		var far_small_hidden = true
		for s in far_group["small"]:
			if is_instance_valid(s) and s.visible:
				far_small_hidden = false
		assert(far_small_hidden, "HATA: 70m+ uzaktaki kucuk LOD nesneleri (cicek/ot/cop) gizlenmeliydi!")
		print("  -> [PASS] LOD mesafe katmanlari (Yakin tam detay, uzak siluet culling) dogrulandi.")

		# Test 6: Kamera Yönelimli Culling (Frustum/Orientation Audit)
		var behind_group = cm.chunk_lod_groups[Vector2i(0, 2)]
		var behind_small_hidden = true
		for s in behind_group["small"]:
			if is_instance_valid(s) and s.visible:
				behind_small_hidden = false
		assert(behind_small_hidden, "HATA: Kameranin arkasinda kalan chunk'taki kucuk nesneler cull edilmeliydi!")
		print("  -> [PASS] Kamera yonelimli culling (arkadaki nesneleri kapatma) dogrulandi.")

		# Test 7: Zemin Materyali ve Dikişsizlik (Seamless Shader Audit)
		assert(cm.terrain_material != null, "HATA: Zemin materyali olusturulmadi!")
		var chunk_ground = cm.loaded_chunks[Vector2i.ZERO].get_node_or_null("Ground")
		assert(chunk_ground != null, "HATA: Chunk icinde zemin mesh'i bulunamadi!")
		assert(chunk_ground.material_override == cm.terrain_material, "HATA: Chunk ortak dikişsiz zemin materyalini kullanmiyor!")
		print("  -> [PASS] Zemin shader paylasimi ve dikissiz zemin butunlugu dogrulandi.")

		print("==================================================")
		print("AUDIT SONUCU: 7 / 7 KUSURSUZ (GRID/CHUNK TAM GUVENILIR)")
		print("==================================================")
		quit(0)
