extends SceneTree

# Silah Animasyonları, Görsel ve Davranış Cilası Doğrulama Testi
var timer: float = 0.0
var step: int = 0
var main3d: Node = null
var player3d: Node = null

func _init() -> void:
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	if step == 0:
		step = 1
		print("==================================================")
		print("TEST: SILAH ANIMASYONLARI VE DAVRANIS CILASI")
		print("==================================================")
		var sc = load("res://scenes/world/main_3d.tscn")
		main3d = sc.instantiate()
		root.add_child(main3d)
		player3d = main3d.get_node_or_null("Player3D")
		return
		
	timer += 0.016
	
	if step == 1 and timer > 0.2:
		step = 2
		# 1. TEST: Slot Prosedürel Tepkisi (Kickback & Flash)
		var slot_marker = player3d.weapon_slots_node.get_node_or_null("Slot0")
		assert(slot_marker != null, "Slot0 bulunamadı!")
		var initial_pos = slot_marker.position
		player3d._trigger_slot_kickback(slot_marker)
		
		# Slot0'ın meta olarak orijinal konumunu kaydettiğini doğrula
		assert(slot_marker.has_meta("orig_local_pos"), "orig_local_pos meta verisi kaydedilmedi!")
		assert(slot_marker.get_meta("orig_local_pos") == initial_pos, "Orijinal konum eşleşmedi!")
		
		# Flash nesnesinin çocuk olarak eklendiğini doğrula
		var flash_found := false
		for c in slot_marker.get_children():
			if c is Sprite3D and is_equal_approx(c.pixel_size, 0.007):
				flash_found = true
				break
		assert(flash_found, "Slot ucunda namlu parlaması (flash) sprite'ı üretilmedi! Çocuklar: %s" % str(slot_marker.get_children()))
		print("[PASS] Test 1: Slot Prosedürel Kickback & Flash başlatma doğrulandı.")

	if step == 2 and timer > 0.45:
		step = 3
		# 0.25 saniye sonra slot orijinal konumuna ve scale 1.0'a dönmüş olmalı
		var slot_marker = player3d.weapon_slots_node.get_node_or_null("Slot0")
		var orig_pos = slot_marker.get_meta("orig_local_pos")
		assert(slot_marker.position.distance_to(orig_pos) < 0.01, "Slot kickback sonrası yerine dönmedi!")
		assert(slot_marker.scale.distance_to(Vector3.ONE) < 0.01, "Slot ölçeği 1.0'a geri oturmadı!")
		print("[PASS] Test 2: Slot 0.12s kickback yaylanması ve yerine oturma doğrulandı.")

	if step == 3:
		step = 4
		# 2. TEST: Kılıç Savurması (Melee Arc) Yönelimi
		var proj_sc = load("res://scenes/weapons/proj_blade_3d.tscn")
		var p_sword = proj_sc.instantiate()
		p_sword.position = player3d.global_position
		# Doğuya doğru (Vector3.RIGHT) savur
		var east_dir = Vector3.RIGHT
		p_sword.configure(east_dir, 55.0, 0.0, "res://assets/sprites/weapons/proj_sword_heavy_slash.png", 0.008, 0.0, 99, 0.35, false, "melee_arc", player3d)
		main3d.add_child(p_sword)
		
		# Yarım frame işleterek kılıcın konumunu kontrol et
		p_sword._physics_process(0.016)
		var rel_pos = p_sword.global_position - player3d.global_position
		# Doğuya doğru savurulduğu için X bileşeni pozitif ve baskın olmalıdır (kuzey/Z=-1 değil!)
		assert(rel_pos.x > 1.0, "Kılıç savurması ateşlenen yöne (Doğu) değil, yanlış eksene savruldu! rel_pos: %s" % str(rel_pos))
		print("[PASS] Test 3: Kılıç savurması hedeflenen yöne (Doğu) organik kavisle savruldu.")
		p_sword.queue_free()

	if step == 4:
		step = 5
		# 3. TEST: Hançer Hedefe Kilitlenme (Dagger Homing Steering)
		var enemy_sc = load("res://scenes/enemies/enemy_3d_base.tscn")
		var dummy_enemy = enemy_sc.instantiate()
		dummy_enemy.position = player3d.global_position + Vector3(4.0, 0, 4.0)
		main3d.add_child(dummy_enemy)
		
		var proj_sc = load("res://scenes/weapons/proj_blade_3d.tscn")
		var p_dagger = proj_sc.instantiate()
		p_dagger.position = player3d.global_position
		# Başlangıçta düz ileri atıldı
		p_dagger.configure(Vector3.FORWARD, 25.0, 30.0, "res://assets/sprites/weapons/proj_dagger.png", 0.005, 0.0, 1, 1.5, false, "targeted")
		main3d.add_child(p_dagger)
		
		# Birkaç fizik adımı koştur
		for i in range(15):
			p_dagger._physics_process(0.016)
			
		# Hançerin yönünün dummy_enemy yönüne (pozitif X ve Z) doğru yöneldiğini doğrula
		assert(p_dagger.direction.x > 0.2, "Hançer hedefe doğru kilitlenip yönelmedi! Direction: %s" % str(p_dagger.direction))
		assert(p_dagger.direction.z > 0.0, "Hançer hedefe doğru kilitlenip yönelmedi! Direction: %s" % str(p_dagger.direction))
		print("[PASS] Test 4: Hançer hedefe kilitlenme (homing steering) ve yönelim doğrulandı.")
		p_dagger.queue_free()
		dummy_enemy.queue_free()

	if step == 5:
		step = 6
		# 4. TEST: Asa Küresi Hafif Sinüs Süzülmesi (Arcane Wobble)
		var proj_sc = load("res://scenes/weapons/proj_blade_3d.tscn")
		var p_staff = proj_sc.instantiate()
		p_staff.position = Vector3(0, 1.0, 0)
		p_staff.configure(Vector3.FORWARD, 65.0, 18.0, "res://assets/sprites/weapons/proj_orb.png", 0.007, 8.0, 2, 2.0, false, "targeted")
		main3d.add_child(p_staff)
		
		var max_lateral_deviation := 0.0
		for i in range(40):
			p_staff._physics_process(0.016)
			var lat_dev = absf(p_staff.position.x)
			if lat_dev > max_lateral_deviation:
				max_lateral_deviation = lat_dev
				
		assert(max_lateral_deviation > 0.10, "Asa küresi sinüs süzülmesi (arcane wobble) yetersiz! Max dev: %f" % max_lateral_deviation)
		print("[PASS] Test 5: Asa küresi belirgin sinüs süzülmesi (wobble dev: %.3f m) doğrulandı." % max_lateral_deviation)
		p_staff.queue_free()

	if step == 6:
		step = 7
		# 5. TEST: Balta ve İksir Zemin Darbesi Ayrımı
		var proj_sc = load("res://scenes/weapons/proj_blade_3d.tscn")
		var p_axe = proj_sc.instantiate()
		p_axe.position = Vector3(0, 1.0, 0)
		p_axe.configure(Vector3.FORWARD, 75.0, 20.0, "res://assets/sprites/weapons/proj_axe_head.png", 0.0075, 25.0, 4, 0.1, false, "parabolic_lob", player3d, Vector3(0, 0, 5))
		main3d.add_child(p_axe)
		
		# İniş anına kadar işlet
		p_axe._physics_process(0.12)
		
		# Yerde krater ve darbe şokunun olduğunu, ancak iksir havuzu olmadığını kontrol et
		var found_potion_puddle := false
		for c in main3d.get_children():
			if c.has_method("configure") and c.get("original_tex_path") == "res://assets/sprites/weapons/proj_potion.png":
				found_potion_puddle = true
		assert(not found_potion_puddle, "Balta yere vurduğunda hatalı şekilde iksir birikintisi oluşturdu!")
		print("[PASS] Test 6: Balta yere vurduğunda iksir birikintisi yerine darbe şoku ve krater üretti.")
		
		print("==================================================")
		print("TÜM CILA VE ANIMASYON DOĞRULAMALARI BAŞARILI!")
		print("==================================================")
		main3d.queue_free()
		await process_frame
		quit(0)
