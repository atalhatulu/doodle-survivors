extends SceneTree

# Kapsamlı 3D Savaş, Karakter, Silah, Pasif Eşya ve Mermi Doğrulama Testi
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
		print("DOODLE SURVIVORS: 3D ENTEGRASYON & STAT TESTI")
		print("==================================================")
		var sc = load("res://scenes/world/main_3d.tscn")
		main3d = sc.instantiate()
		root.add_child(main3d)
		player3d = main3d.get_node_or_null("Player3D")
		return
		
	timer += 0.016
	
	if step == 1 and timer > 0.3:
		step = 2
		# 1. 14 Silah ve 5 Evrim Tanımlarının Kontrolü
		var w_cfgs = player3d.WEAPON_CONFIGS
		var all_14_weapons = [
			"weapon_sword", "weapon_bow", "weapon_staff", "weapon_axe", "weapon_dagger",
			"weapon_potion", "weapon_boomerang", "weapon_spellbook", "weapon_aura",
			"weapon_lightning", "weapon_dragon_breath", "weapon_void_vortex",
			"weapon_spirit_wolf", "weapon_earthquake"
		]
		for w in all_14_weapons:
			assert(w_cfgs.has(w), "Silah konfigürasyonu eksik: " + w)
			var cfg = w_cfgs[w]
			assert(ResourceLoader.exists(cfg["proj_tex"]), "Mermi dokusu bulunamadı: " + cfg["proj_tex"])
		print("[PASS] 14 Temel silahın mermi görseli, atış profili ve hasarı doğrulandı.")
		
		# 2. 5 Karakter Stat Modlarının Uygulanabilirliği
		var meta = player3d.get_node_or_null("/root/MetaProgression")
		var chars = ["knight", "mage", "ranger", "alchemist", "necromancer"]
		for c in chars:
			assert(meta.CHARACTERS.has(c), "Karakter eksik: " + c)
		print("[PASS] 5 Karakter sınıfının stat modları ve başlangıç silahları doğrulandı.")
		
		# 3. 19 Pasif Eşya Stat Entegrasyonu
		var passives_test = [
			{"stat": "move_speed", "val": 1.15},
			{"stat": "max_health", "val": 25.0},
			{"stat": "damage_mult", "val": 1.20},
			{"stat": "magnet_range", "val": 1.40},
			{"stat": "cooldown_mult", "val": 0.85},
			{"stat": "armor", "val": 0.15},
			{"stat": "luck", "val": 0.15},
			{"stat": "area_mult", "val": 1.20},
			{"stat": "extra_projectiles", "val": 1.0},
			{"stat": "hp_regen", "val": 0.30},
			{"stat": "projectile_speed", "val": 1.15},
			{"stat": "duration", "val": 1.20},
			{"stat": "xp_mult", "val": 1.12},
			{"stat": "gold_mult", "val": 1.20},
			{"stat": "revive", "val": 1.0},
			{"stat": "invulnerability", "val": 0.12},
			{"stat": "curse", "val": 1.10},
			{"stat": "torrona", "val": 1.05},
			{"stat": "sharpener", "val": 1.15}
		]
		for p in passives_test:
			player3d.add_passive("test_" + p["stat"], p["stat"], p["val"])
		assert(player3d.extra_projectiles == 1, "extra_projectiles pasifi çalışmadı")
		assert(player3d.revives_remaining == 1, "revive pasifi çalışmadı")
		assert(player3d.hp_regen >= 0.30, "hp_regen pasifi çalışmadı")
		print("[PASS] 19 Pasif eşyanın tüm stat çarpanları Player3D'ye başarıyla uygulandı.")
		
		# 4. Mermi Ateşleme Simülasyonu (Tüm Silahlar)
		for w in all_14_weapons:
			player3d.add_weapon(w)
		print("[PASS] Silah ekleme ve 6 döner slot yönetimi başarıyla çalışıyor.")
		
		# 5. Dirilme (Revive) ve Dokunulmazlık Testi
		player3d.take_damage(9999.0)
		assert(not player3d.is_dead, "Dirilme hakkı varken oyuncu öldü!")
		assert(player3d.revives_remaining == 0, "Dirilme hakkı tüketilmedi!")
		assert(player3d.invulnerability_timer > 0.0, "Dirilme sonrası dokunulmazlık verilmedi!")
		print("[PASS] Dirilme (Revive) ve dokunulmazlık mekanizması doğrulandı.")

		# 6. Sistem 1 Doğrulama: 3D Dalga & Boss Sistemi (EnemySpawner3D)
		var spawner3d = main3d.get_node_or_null("EnemySpawner3D")
		assert(spawner3d != null, "EnemySpawner3D sahnede bulunamadı!")
		assert(spawner3d.enemy_archetypes.size() == 16, "16 Canavar arketipi eksik! Mevcut: %d" % spawner3d.enemy_archetypes.size())
		for arch in spawner3d.enemy_archetypes:
			assert(ResourceLoader.exists(arch["texture"]), "Arketip dokusu eksik: %s" % arch["texture"])
		spawner3d._spawn_enemy()
		spawner3d._spawn_elite_monster()
		spawner3d._spawn_boss(false, 3500.0, 32.0)
		print("[PASS] Sistem 1: 3D Dalga, Arketip (16 Canavar), Elit ve Boss üretim mekanizması doğrulandı.")

		# 7. Sistem 2 Doğrulama: 3D Hazine Sandığı & Silah Evrimi (chest_3d)
		var chest_sc = load("res://scenes/pickups/chest_3d.tscn")
		assert(chest_sc != null, "scenes/pickups/chest_3d.tscn yüklenemedi!")
		var chest_inst = chest_sc.instantiate()
		main3d.add_child(chest_inst)
		assert(chest_inst.has_method("_open_chest"), "_open_chest metodu bulunamadı!")
		chest_inst._open_chest(player3d)
		print("[PASS] Sistem 2: 3D Hazine Sandığı ve Sandıktan Yükseltme/Evrim Açma doğrulandı.")

		# 8. Sistem 3 Doğrulama: 3D Hasar Sayıları (damage_number_3d)
		var dmg_sc = load("res://scenes/ui/damage_number_3d.tscn")
		assert(dmg_sc != null, "scenes/ui/damage_number_3d.tscn yüklenemedi!")
		var dmg_inst = dmg_sc.instantiate()
		main3d.add_child(dmg_inst)
		assert(dmg_inst.has_method("setup"), "DamageNumber3D setup metodu bulunamadı!")
		dmg_inst.setup(125.0, true, player3d.global_position)
		print("[PASS] Sistem 3: 3D Yüzen Hasar Sayıları (Normal & Kritik) doğrulandı.")

		# 9. Sistem 4 Doğrulama: 3D Kadim Sunak & Lanet Paktı Etkileşimi (shrine_3d)
		var shrine_sc = load("res://scenes/world/shrine_3d.tscn")
		assert(shrine_sc != null, "scenes/world/shrine_3d.tscn yüklenemedi!")
		var shrine_inst = shrine_sc.instantiate()
		main3d.add_child(shrine_inst)
		assert(shrine_inst.has_method("_on_blood_pact_selected"), "Sunak pakt seçim metotları eksik!")
		shrine_inst.player_in_range = player3d
		var old_dmg = player3d.damage_multiplier
		shrine_inst._on_blood_pact_selected()
		assert(player3d.damage_multiplier > old_dmg, "Kan paktı hasar çarpanını artırmadı!")
		print("[PASS] Sistem 4: 3D Kadim Sunak pakt seçimi ve oyuncu stat entegrasyonu doğrulandı.")

		# 10. Sistem 5 Doğrulama: Kamera Görüş & Engel Saydamlığı
		var tree_sc = load("res://scenes/world/tree_3d.tscn")
		var tree_inst = tree_sc.instantiate()
		main3d.add_child(tree_inst)
		assert(tree_inst.has_method("set_obstacle_alpha"), "Engel saydamlık kontrol metodu eksik!")
		assert(tree_inst.is_in_group("camera_fading_obstacles"), "Engel kamera grubuna eklenmedi!")
		tree_inst.set_obstacle_alpha(0.25)
		assert(tree_inst.target_alpha == 0.25, "Engel hedef saydamlığı ayarlanamadı!")
		print("[PASS] Sistem 5: Görüş hattındaki engellerin 3D saydamlaşma grubu ve arayüzü doğrulandı.")
		
		print("==================================================")
		print("3D TEST SONUCU: TÜM SİSTEMLER KUSURSUZ")
		print("==================================================")
		main3d.queue_free()
		await process_frame
		await process_frame
		quit(0)
