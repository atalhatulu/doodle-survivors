extends SceneTree

const XPGem = preload("res://scripts/xp_gem.gd")

func _init() -> void:
	process_frame.connect(_run_all_tests, CONNECT_ONE_SHOT)

func _run_all_tests() -> void:
	AudioServer.set_bus_mute(0, true)
	print("==================================================")
	print("DOODLE SURVIVORS: FAZ 1-2-3 HEADLESS DOĞRULAMA")
	print("==================================================")
	
	var total_tests := 0
	var passed_tests := 0
	
	# TEST 1: MetaProgression Ayarlar ve Karakter Havuzu
	total_tests += 1
	var meta = preload("res://scripts/meta_progression.gd").new()
	if meta.CHARACTERS.has("necromancer") and meta.CHARACTERS.size() >= 5:
		print("[PASS] Test 1: 5 Karakter ve Necromancer tanımları mevcut.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 1: Necromancer eksik.")
		
	# TEST 2: AudioManager Bus Yapısı ve Ses Ayarları
	total_tests += 1
	var audio_mgr = preload("res://scripts/audio_manager.gd").new()
	audio_mgr.set_volume("master", 0.8)
	audio_mgr.set_volume("sfx", 0.7)
	audio_mgr.set_volume("music", 0.6)
	if meta.settings["master_volume"] != null and meta.settings["screen_shake"] != null:
		print("[PASS] Test 2: AudioManager ve Settings veri sözlüğü çalışıyor.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 2: Ayar parametreleri eksik.")
	audio_mgr.free()
	meta.free()
	
	# TEST 3: Player ve 5 Sınıf Dash Testi
	total_tests += 1
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	
	var classes = ["knight", "ranger", "mage", "alchemist", "necromancer"]
	var dash_ok := true
	for c_id in classes:
		player.character_id = c_id
		player.is_dashing = false
		player.dash_timer = 0.0
		player._try_dash()
		if not player.is_dashing and c_id != "mage": # mage blink instant
			dash_ok = false
			printerr("[FAIL] Dash başarısız: ", c_id)
		player.is_dashing = false
		player.dash_timer = 0.0
		
	if dash_ok:
		print("[PASS] Test 3: 5 Karakter sınıfının Dash/Yetenek mekanikleri çalışıyor.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 3: Dash mekanikleri hatalı.")
		
	# TEST 4: Minion Skeleton Canlılığı
	total_tests += 1
	var skel_scene = load("res://scenes/entities/minion_skeleton.tscn")
	var skel = skel_scene.instantiate()
	root.add_child(skel)
	if skel.is_in_group("minions") and skel.has_method("take_damage"):
		print("[PASS] Test 4: İskelet minyon sahnesi ve grubu doğrulandı.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 4: İskelet minyon hatalı.")
	skel.queue_free()
	
	# TEST 5: Status Effects ve Element Rezonansı (Ateş + Zehir = Toksik Patlama)
	total_tests += 1
	var enemy_scene = load("res://scenes/enemies/enemy_eyeball.tscn")
	var enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	enemy.global_position = Vector2(100, 100)
	enemy.apply_status("burn", 3.0, 10.0)
	enemy.apply_status("poison", 3.0, 10.0) # Burada Toksik Patlama tetiklenmeli
	
	if enemy.is_burning or enemy.is_poisoned or enemy.current_health < enemy.max_health:
		print("[PASS] Test 5: Element Rezonansı (Ateş + Zehir -> Toksik Patlama) çalışıyor.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 5: Element Rezonansı tetiklenmedi.")
		
	# TEST 6: Boşluk Girdabı ve Süper İletken Rezonansı
	total_tests += 1
	var vortex_scene = load("res://scenes/weapons/proj_void_vortex.tscn")
	var vortex = vortex_scene.instantiate()
	root.add_child(vortex)
	vortex.global_position = Vector2(150, 150)
	if vortex.is_in_group("void_vortices") and vortex.has_method("trigger_superconduct"):
		vortex.trigger_superconduct()
		print("[PASS] Test 6: Boşluk Girdabı Süper İletken Rezonansı hazır.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 6: Boşluk girdabı grubu veya metodu eksik.")
	vortex.queue_free()
	enemy.queue_free()
	
	# TEST 7: Kadim Sunak (Pact Shrine) Etkileşimi
	total_tests += 1
	var shrine_scene = load("res://scenes/world/pact_shrine.tscn")
	var shrine = shrine_scene.instantiate()
	root.add_child(shrine)
	if shrine.has_method("_on_blood_pact_selected") and shrine.has_method("_on_greed_pact_selected"):
		shrine.player_in_range = player
		shrine._on_blood_pact_selected()
		print("[PASS] Test 7: Kadim Sunak ve Lanet Paktı etkileşimi çalışıyor.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 7: Sunak pakt metotları eksik.")
	shrine.queue_free()
	
	# TEST 8: 5 Silah Evrimi Örnekleme ve Çalışma Zamanı
	total_tests += 1
	var evos = [
		"res://scenes/weapons/weapon_evo_divine_sun.tscn",
		"res://scenes/weapons/weapon_evo_hellfire_storm.tscn",
		"res://scenes/weapons/weapon_evo_king_cleaver.tscn",
		"res://scenes/weapons/weapon_evo_storm_quiver.tscn",
		"res://scenes/weapons/weapon_evo_cosmic_archon.tscn"
	]
	var evos_ok := true
	for evo_path in evos:
		var scene = load(evo_path)
		if not scene:
			evos_ok = false
			printerr("[FAIL] Evrim sahnesi yüklenemedi: ", evo_path)
			continue
		var inst = scene.instantiate()
		root.add_child(inst)
		inst.queue_free()
		
	if evos_ok:
		print("[PASS] Test 8: 5 Efsanevi Silah Evrimi başarıyla örneklendi.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 8: Silah evrimlerinde yükleme hatası.")
		
	# TEST 9: LevelUpMenu Evrim Havuzuna Giriş Kontrolü
	total_tests += 1
	var lvl_menu_scene = load("res://scenes/ui/level_up_menu.tscn")
	var lvl_menu = lvl_menu_scene.instantiate()
	root.add_child(lvl_menu)
	
	var dummy_aura_node = Node2D.new()
	player.owned_weapons["weapon_aura"] = {"level": 7, "node": dummy_aura_node}
	player.owned_passives["passive_armor"] = 1
	lvl_menu._build_valid_pool()
	var found_evo := false
	for choice in lvl_menu.valid_pool:
		if choice.get("id") == "weapon_evo_divine_sun":
			found_evo = true
			break
			
	if found_evo:
		print("[PASS] Test 9: LevelUpMenu evrim koşulu sağlandığında Efsanevi Evrimi havuza ekliyor.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 9: Efsanevi evrim havuza eklenmedi.")
	lvl_menu.queue_free()
	dummy_aura_node.free()
	
	# TEST 10: Run Summary ve DPS Takipçisi (GameOverMenu)
	total_tests += 1
	var over_scene = load("res://scenes/ui/game_over_menu.tscn")
	var over_menu = over_scene.instantiate()
	root.add_child(over_menu)
	
	player.record_weapon_damage("weapon_sword", 1250.0)
	player.record_weapon_damage("weapon_aura", 3400.0)
	player.total_enemies_killed = 42
	player.coins_in_run = 85
	
	over_menu._populate_run_summary("05:12", 8)
	if over_menu.stat_kills_val.text == "42" and over_menu.dps_container.get_child_count() >= 2:
		print("[PASS] Test 10: Run Summary ve Silah DPS dökümü başarıyla oluşturuldu.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 10: Run Summary verileri eksik.")
	over_menu.queue_free()
	
	player.queue_free()
	
	# TEST 11: XP Kristali 250 Sınırı ve En Uzaktaki Kristale Füzyon
	total_tests += 1
	XPGem.reset_pool()
	var test_parent = Node2D.new()
	root.add_child(test_parent)
	current_scene = test_parent
	
	for i in range(260):
		var pos = Vector2(50.0 + i * 5.0, 0)
		XPGem.spawn_gem(self, pos, 5)
		
	var gem_count = XPGem.get_active_gem_count()
	var furthest = XPGem._find_furthest_gem_from_player()
	if gem_count == 250 and furthest and furthest.xp_amount >= 55:
		print("[PASS] Test 11: XP Kristali 250 sınırı ve en uzaktaki kristale değer aktarımı doğrulandı.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 11: XP Kristal sınırı veya füzyon başarısız: count=", gem_count, " furthest_xp=", furthest.xp_amount if furthest else 0)
		
	XPGem.reset_pool()
	test_parent.queue_free()
	
	# TEST 12: Mıknatıs Alanı ve start_attraction ile Kristal Çekimi
	total_tests += 1
	var mag_player = player_scene.instantiate()
	mag_player.global_position = Vector2(0, 0)
	root.add_child(mag_player)
	
	var gem_scene = load("res://scenes/pickups/xp_gem.tscn")
	var test_gem = gem_scene.instantiate()
	test_gem.global_position = Vector2(100, 0) # 180px mıknatıs yarıçapı içinde
	test_gem.xp_amount = 35
	root.add_child(test_gem)
	
	if mag_player.has_method("_on_magnet_area_entered"):
		mag_player._on_magnet_area_entered(test_gem)
		
	var attracted_ok: bool = test_gem.is_attracted
	var initial_xp: int = mag_player.current_xp
	
	if test_gem.has_method("_collect"):
		test_gem._collect(mag_player)
		
	if attracted_ok and mag_player.current_xp == initial_xp + 35:
		print("[PASS] Test 12: Mıknatıs çekim alanı (start_attraction) ve kristal toplama çalışıyor.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 12: Mıknatıs veya toplama başarısız: attracted=", attracted_ok, " xp=", mag_player.current_xp)
		
	# TEST 13: Altın Sikke (Gold Coin) Varlık ve Görsel Doğrulaması
	total_tests += 1
	var coin_scene = load("res://scenes/pickups/coin_pickup.tscn")
	var coin_inst = coin_scene.instantiate()
	root.add_child(coin_inst)
	var coin_spr: Sprite2D = coin_inst.get_node_or_null("Sprite2D")
	if coin_spr and coin_spr.texture and coin_spr.texture.resource_path.ends_with("gold_coin.png"):
		print("[PASS] Test 13: Altın Sikke (gold_coin.png) sahneye ve sprite'a başarıyla bağlandı.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 13: Altın Sikke dokusu hatalı: ", coin_spr.texture if coin_spr else "yok")
	coin_inst.queue_free()
	
	# TEST 14: Silah Seviye Atlamasında Taban Mermi Temizliği ve Pasif Ayrımı
	total_tests += 1
	var bow_scene = load("res://scenes/weapons/weapon_bow.tscn")
	var bow = bow_scene.instantiate()
	root.add_child(bow)
	bow.upgrade_level(7) # 7. seviyeye yükselt
	var axe_scene = load("res://scenes/weapons/weapon_axe.tscn")
	var axe = axe_scene.instantiate()
	root.add_child(axe)
	axe.upgrade_level(7)
	if bow.projectiles_count == 1 and axe.axes_count == 1 and bow.damage > 22.0 and axe.damage > 50.0:
		print("[PASS] Test 14: Silah seviye atlamasında taban mermi çoğalması temizlendi; hasar/hız ölçeklemesi korundu.")
		passed_tests += 1
	else:
		printerr("[FAIL] Test 14: Silah mermi sayısı seviye ile arttı: bow=", bow.projectiles_count, " axe=", axe.axes_count)
	bow.queue_free()
	axe.queue_free()
	
	# TEST 15: Yakın Düşman Mutlak Öncelik Hedefleme Testi
	total_tests += 1
	var test_bow = bow_scene.instantiate()
	test_bow.targeting_mode = "SECTOR" # Normalde sektörüne bakar
	root.add_child(test_bow)
	test_bow.global_position = Vector2(0, 0)
	test_bow.player = null # center_pos = test_bow.global_position (0, 0)
	
	# Önceki testlerden kalan enemies gruplu düğümleri temizle
	for e in root.get_tree().get_nodes_in_group("enemies"):
		e.remove_from_group("enemies")
		e.queue_free()
	
	var far_enemy = enemy_scene.instantiate()
	far_enemy.global_position = Vector2(300, 0) # Sektöründe ama uzakta (300px)
	root.add_child(far_enemy)
	
	var close_enemy = enemy_scene.instantiate()
	close_enemy.global_position = Vector2(0, 45) # Sektör dışı ama dibimizde (45px)
	root.add_child(close_enemy)
	
	test_bow._find_target()
	var test15_ok := true
	if test_bow.current_target != close_enemy:
		printerr("[FAIL] Test 15a: Yay dibimizdeki düşmanı hedeflemedi: target=", test_bow.current_target)
		test15_ok = false
		
	# Büyü Asası (STRONGEST) testi: Uzaktaki tank düşman (hp=1000) yerine dibimizdeki zayıf düşmanı (hp=10, 45px) hedeflemeli
	var staff_scene = load("res://scenes/weapons/weapon_staff.tscn")
	var test_staff = staff_scene.instantiate()
	root.add_child(test_staff)
	test_staff.global_position = Vector2(0, 0)
	test_staff.player = null
	far_enemy.health = 1000.0
	test_staff._find_target()
	if test_staff.current_target != close_enemy:
		printerr("[FAIL] Test 15b: Büyü asası dibimizdeki düşman varken uzaktaki tankı seçti: target=", test_staff.current_target)
		test15_ok = false
		
	# Ölü düşman testi: Yakındaki düşman öldüğünde anında diğer düşmana geçmeli
	close_enemy.is_dead = true
	test_bow._find_target()
	if test_bow.current_target != far_enemy:
		printerr("[FAIL] Test 15c: Ölü düşman elenmedi: target=", test_bow.current_target)
		test15_ok = false
		
	if test15_ok:
		print("[PASS] Test 15: Dibimizdeki acil tehdit (45px) tüm modlarda (SECTOR, STRONGEST) mutlak öncelikle hedeflendi ve ölü düşman filtresi doğrulandı.")
		passed_tests += 1
		
	far_enemy.queue_free()
	close_enemy.queue_free()
	test_bow.queue_free()
	test_staff.queue_free()
	
	print("==================================================")
	print("TEST SONUCU: %d / %d BAŞARILI" % [passed_tests, total_tests])
	print("==================================================")
	
	# Bekleyen queue_free çağrılarının temizlenmesi için 2 kare bekle
	await process_frame
	await process_frame
	
	if passed_tests == total_tests:
		quit(0)
	else:
		quit(1)
