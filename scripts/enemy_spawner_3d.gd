extends Node3D

signal king_boss_defeated()

@export var spawn_interval: float = 0.85
@export var max_enemies: int = 150
@export var spawn_dist_min: float = 24.0
@export var spawn_dist_max: float = 38.0
@export var despawn_reposition_distance: float = 55.0

var timer: float = 0.0
var elapsed_game_time: float = 0.0
var reposition_timer: float = 0.0
var next_elite_spawn_time: float = 60.0

var boss_spawned_5min: bool = false
var boss_spawned_10min: bool = false
var boss_spawned_15min: bool = false
var boss_spawned_20min: bool = false

var event_spawned_4min: bool = false
var event_spawned_8min: bool = false
var event_spawned_14min: bool = false
var shrine_spawned_2min: bool = false
var shrine_spawned_7min: bool = false
var shrine_spawned_12min: bool = false

var player: Node3D = null
var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy_3d_base.tscn")
var shrine_scene: PackedScene = preload("res://scenes/world/shrine_3d.tscn")

# 16 Orijinal Dark Fantasy Canavar Arketipi (assets/sprites/enemies/)
var enemy_archetypes: Array[Dictionary] = [
	# 0: enemy_spider (Hızlı, zayıf sürü canavarı)
	{
		"texture": "res://assets/sprites/enemies/enemy_spider.png",
		"health": 20.0, "speed": 5.8, "damage": 8.0, "scale": 0.0075, "xp": 10, "name": "spider"
	},
	# 1: enemy_bat_flyer (Hızlı uçan saldırgan)
	{
		"texture": "res://assets/sprites/enemies/enemy_bat_flyer.png",
		"health": 18.0, "speed": 6.5, "damage": 9.0, "scale": 0.0068, "xp": 12, "name": "bat_flyer"
	},
	# 2: enemy_bee_gasmask (Zehirli uçucu)
	{
		"texture": "res://assets/sprites/enemies/enemy_bee_gasmask.png",
		"health": 24.0, "speed": 6.2, "damage": 10.0, "scale": 0.0072, "xp": 14, "name": "bee_gasmask"
	},
	# 3: enemy_slime_puddle (Bölünen/sızan balçık)
	{
		"texture": "res://assets/sprites/enemies/enemy_slime_puddle.png",
		"health": 32.0, "speed": 3.6, "damage": 11.0, "scale": 0.0078, "xp": 15, "name": "slime_puddle"
	},
	# 4: enemy_snail (Zırhlı yavaş defansif)
	{
		"texture": "res://assets/sprites/enemies/enemy_snail.png",
		"health": 70.0, "speed": 2.2, "damage": 14.0, "scale": 0.008, "xp": 22, "name": "snail"
	},
	# 5: enemy_spiky (Dikenli yaratık)
	{
		"texture": "res://assets/sprites/enemies/enemy_spiky.png",
		"health": 42.0, "speed": 4.6, "damage": 15.0, "scale": 0.0075, "xp": 18, "name": "spiky"
	},
	# 6: enemy_armored_turtle (Ağır zırhlı tank)
	{
		"texture": "res://assets/sprites/enemies/enemy_armored_turtle.png",
		"health": 120.0, "speed": 2.5, "damage": 20.0, "scale": 0.0085, "xp": 35, "name": "armored_turtle"
	},
	# 7: enemy_plant_monster (Korkunç orman bitkisi)
	{
		"texture": "res://assets/sprites/enemies/enemy_plant_monster.png",
		"health": 85.0, "speed": 3.2, "damage": 22.0, "scale": 0.0085, "xp": 28, "name": "plant_monster"
	},
	# 8: enemy_wasp_flying (İğneli avcı)
	{
		"texture": "res://assets/sprites/enemies/enemy_wasp_flying.png",
		"health": 35.0, "speed": 6.8, "damage": 13.0, "scale": 0.0072, "xp": 20, "name": "wasp_flying"
	},
	# 9: enemy_spiky_ghost (Uçuşan sivri hayalet)
	{
		"texture": "res://assets/sprites/enemies/enemy_spiky_ghost.png",
		"health": 48.0, "speed": 5.0, "damage": 16.0, "scale": 0.0075, "xp": 24, "name": "spiky_ghost"
	},
	# 10: enemy_alien_biped (İki ayaklı çevik yaratık)
	{
		"texture": "res://assets/sprites/enemies/enemy_alien_biped.png",
		"health": 60.0, "speed": 5.2, "damage": 18.0, "scale": 0.008, "xp": 26, "name": "alien_biped"
	},
	# 11: enemy_dino_biped (Yırtıcı dinozor)
	{
		"texture": "res://assets/sprites/enemies/enemy_dino_biped.png",
		"health": 95.0, "speed": 4.8, "damage": 24.0, "scale": 0.0085, "xp": 32, "name": "dino_biped"
	},
	# 12: enemy_wood_log_spiked (Dikenli kütük gardiyan)
	{
		"texture": "res://assets/sprites/enemies/enemy_wood_log_spiked.png",
		"health": 140.0, "speed": 2.8, "damage": 28.0, "scale": 0.0088, "xp": 40, "name": "wood_log_spiked"
	},
	# 13: enemy_octopus (Karanlık dokunaçlı yaratık)
	{
		"texture": "res://assets/sprites/enemies/enemy_octopus.png",
		"health": 160.0, "speed": 3.4, "damage": 26.0, "scale": 0.009, "xp": 48, "name": "octopus"
	},
	# 14: enemy_fury_cyclops (Öfkeli Tekgöz - Mini Boss / Elit)
	{
		"texture": "res://assets/sprites/enemies/enemy_fury_cyclops.png",
		"health": 220.0, "speed": 4.2, "damage": 34.0, "scale": 0.0095, "xp": 60, "name": "fury_cyclops"
	},
	# 15: enemy_brute_cyclops (Devasa Siklop - Ağır Yıkıcı / Boss)
	{
		"texture": "res://assets/sprites/enemies/enemy_brute_cyclops.png",
		"health": 450.0, "speed": 3.0, "damage": 42.0, "scale": 0.011, "xp": 90, "name": "brute_cyclops"
	}
]

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	elapsed_game_time += delta
	timer += delta
	reposition_timer += delta
	
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	# Kadim Sunaklar (2, 7, 12. dakikalar)
	if elapsed_game_time >= 120.0 and not shrine_spawned_2min:
		shrine_spawned_2min = true
		_spawn_pact_shrine()
	if elapsed_game_time >= 420.0 and not shrine_spawned_7min:
		shrine_spawned_7min = true
		_spawn_pact_shrine()
	if elapsed_game_time >= 720.0 and not shrine_spawned_12min:
		shrine_spawned_12min = true
		_spawn_pact_shrine()
		
	# Her 60 saniyede bir Elit Canavar doğar
	if elapsed_game_time >= next_elite_spawn_time:
		next_elite_spawn_time += 60.0
		_spawn_elite_monster()
		
	# Dakika Bazlı Özel Kuşatmalar
	if elapsed_game_time >= 240.0 and not event_spawned_4min:
		event_spawned_4min = true
		_trigger_bat_swarm()
	if elapsed_game_time >= 480.0 and not event_spawned_8min:
		event_spawned_8min = true
		_trigger_iron_circle()
	if elapsed_game_time >= 840.0 and not event_spawned_14min:
		event_spawned_14min = true
		_trigger_shadow_rush()
		
	# Boss kontrolleri (5, 10, 15 dk ara boss; 20 dk Final Boss)
	if elapsed_game_time >= 300.0 and not boss_spawned_5min:
		boss_spawned_5min = true
		_spawn_boss(false, 3500.0, 32.0)
	if elapsed_game_time >= 600.0 and not boss_spawned_10min:
		boss_spawned_10min = true
		_spawn_boss(false, 8500.0, 48.0)
	if elapsed_game_time >= 900.0 and not boss_spawned_15min:
		boss_spawned_15min = true
		_spawn_boss(false, 16000.0, 65.0)
	if elapsed_game_time >= 1200.0 and not boss_spawned_20min:
		boss_spawned_20min = true
		_spawn_boss(true, 30000.0, 85.0)
		
	# Uzaklaşan düşmanları oyuncunun önüne taşıma
	if reposition_timer >= 0.35:
		reposition_timer = 0.0
		_reposition_distant_enemies()
		
	# Dinamik Dalga Doğma Döngüsü
	var curse: float = player.curse_mult if player and "curse_mult" in player else 1.0
	var current_interval: float = maxf(0.18, (spawn_interval - (elapsed_game_time * 0.0012)) / curse)
	if timer >= current_interval:
		timer = 0.0
		var tree = get_tree()
		if not tree: return
		var current_enemy_count = tree.get_nodes_in_group("enemies").size()
		var spawn_batch_size: int = 1 + int(elapsed_game_time / 50.0)
		if curse > 1.0:
			spawn_batch_size = int(round(spawn_batch_size * curse))
		spawn_batch_size = mini(spawn_batch_size, 7)
		
		for b in range(spawn_batch_size):
			if current_enemy_count + b < max_enemies:
				_spawn_enemy()

func _get_offscreen_spawn_pos() -> Vector3:
	var angle := randf() * TAU
	var dist := randf_range(spawn_dist_min, spawn_dist_max)
	return player.global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

func _spawn_enemy() -> void:
	if not player: return
	var minute: int = int(elapsed_game_time / 60.0)
	
	# Dakika Bazlı Arketip Dağılımı (16 Canavar Türü)
	var pool_indices: Array[int] = []
	if minute == 0:
		pool_indices = [0, 0, 1] # Spider, Bat flyer
	elif minute == 1:
		pool_indices = [0, 2, 3] # Spider, Bee gasmask, Slime puddle
	elif minute == 2:
		pool_indices = [4, 5, 2] # Snail, Spiky, Bee gasmask
	elif minute == 3:
		pool_indices = [6, 7, 5] # Armored turtle, Plant monster, Spiky
	elif minute == 4:
		pool_indices = [8, 9, 1] # Wasp flying, Spiky ghost, Bat flyer
	elif minute == 5:
		pool_indices = [10, 11, 6] # Alien biped, Dino biped, Armored turtle
	elif minute in [6, 7, 8]:
		pool_indices = [7, 8, 12, 13] # Plant monster, Wasp, Wood log spiked, Octopus
	elif minute in [9, 10, 11]:
		pool_indices = [11, 12, 13, 14] # Dino biped, Wood log spiked, Octopus, Fury cyclops
	else:
		pool_indices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
		
	var chosen_idx: int = pool_indices[randi() % pool_indices.size()]
	var arch: Dictionary = enemy_archetypes[chosen_idx]
	
	var spawn_pos := _get_offscreen_spawn_pos()
	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_pos
	
	# İlerleyen dakikalarda canavar ölçeklenmesi ve renk varyantları
	var hp_scale: float = 1.0 + (elapsed_game_time * 0.0035)
	var dmg_scale: float = 1.0 + (elapsed_game_time * 0.002)
	enemy.max_health = arch["health"] * hp_scale
	enemy.move_speed = arch["speed"]
	enemy.contact_damage = arch["damage"] * dmg_scale
	enemy.xp_value = arch["xp"]
	
	var sp = enemy.get_node_or_null("Sprite3D")
	var tex: Texture2D = load(arch["texture"])
	if sp and tex:
		sp.texture = tex
		sp.pixel_size = arch["scale"]
		
		# Renkli Formlar (Mürekkep Evrimleri)
		if minute >= 10 and randf() < 0.45:
			sp.modulate = Color(0.75, 0.35, 1.2, 1.0) # Mor Lanetli
			enemy.max_health *= 1.8
			sp.pixel_size *= 1.2
		elif minute >= 6 and randf() < 0.35:
			sp.modulate = Color(1.2, 0.4, 0.35, 1.0) # Kızıl Öfkeli
			enemy.max_health *= 1.4
			sp.pixel_size *= 1.12
			
	get_parent().add_child(enemy)

func _spawn_elite_monster() -> void:
	if not player: return
	var spawn_pos := _get_offscreen_spawn_pos()
	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_pos
	
	# Fury Cyclops (indis 14) veya Wood Log Spiked (indis 12) elit olarak doğar
	var arch_idx: int = 14 if randf() < 0.6 else 12
	var arch: Dictionary = enemy_archetypes[arch_idx]
	
	var minute: float = maxf(1.0, elapsed_game_time / 60.0)
	var elite_hp: float = 650.0 * pow(minute, 0.95)
	var elite_dmg: float = 22.0 + (minute * 3.0)
	
	if enemy.has_method("setup_elite"):
		enemy.setup_elite(elite_hp, elite_dmg)
	else:
		enemy.is_elite = true
		enemy.max_health = elite_hp
		enemy.contact_damage = elite_dmg
		
	enemy.move_speed = 3.8
	var sp = enemy.get_node_or_null("Sprite3D")
	var tex: Texture2D = load(arch["texture"])
	if sp and tex:
		sp.texture = tex
		sp.pixel_size = arch["scale"] * 2.0
		sp.modulate = Color(1.3, 0.9, 0.4, 1.0) # Altın Elit Aurası
		
	get_parent().add_child(enemy)

func _spawn_boss(is_final_boss: bool = false, hp: float = 3500.0, dmg: float = 32.0) -> void:
	if not player: return
	var spawn_pos := _get_offscreen_spawn_pos()
	var boss = enemy_scene.instantiate()
	boss.position = spawn_pos
	
	# Brute Cyclops (indis 15) karanlık fantezi boss'u olarak doğar
	var arch: Dictionary = enemy_archetypes[15]
	if boss.has_method("setup_boss"):
		boss.setup_boss(hp, dmg)
	else:
		boss.is_boss = true
		boss.max_health = hp
		boss.contact_damage = dmg
		
	boss.move_speed = 3.4
	var sp = boss.get_node_or_null("Sprite3D")
	var tex: Texture2D = load(arch["texture"])
	if sp and tex:
		sp.texture = tex
		sp.pixel_size = arch["scale"] * (1.8 if not is_final_boss else 2.5)
		sp.modulate = Color(1.2, 0.35, 0.35, 1.0) if is_final_boss else Color.WHITE
		
	if is_final_boss and boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(func(): emit_signal("king_boss_defeated"))
		
	var hud = get_tree().current_scene.get_node_or_null("HUD") if get_tree().current_scene else null
	if hud and hud.has_method("show_announcement"):
		var title: String = "KADİM BRUTE SİKLOP UYANDI!" if is_final_boss else "BÖLGE LORDU YAKLAŞIYOR!"
		hud.show_announcement(title, Color(1.0, 0.2, 0.2))
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("boss_spawn", 0.05, 0.85)
		
	if player and player.has_method("shake_camera"):
		player.shake_camera(0.45, 0.6)
		
	get_parent().add_child(boss)

func _trigger_bat_swarm() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD") if get_tree().current_scene else null
	if hud and hud.has_method("show_announcement"):
		hud.show_announcement("DİKKAT: YARASA AKINI YAKLAŞIYOR!", Color(1.0, 0.3, 0.2))
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.05, 3.0)
		
	var side_sign := 1.0 if randf() < 0.5 else -1.0
	var base_x := player.global_position.x + side_sign * spawn_dist_min
	for i in range(24):
		var bat = enemy_scene.instantiate()
		var offset_z := randf_range(-14.0, 14.0)
		var offset_x := randf_range(-3.0, 3.0)
		bat.position = Vector3(base_x + offset_x, 0.0, player.global_position.z + offset_z)
		bat.max_health = 16.0
		bat.move_speed = 7.2
		bat.contact_damage = 7.0
		var sp = bat.get_node_or_null("Sprite3D")
		var tex: Texture2D = load(enemy_archetypes[1]["texture"])
		if sp and tex:
			sp.texture = tex
			sp.pixel_size = enemy_archetypes[1]["scale"]
		get_parent().add_child(bat)

func _trigger_iron_circle() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD") if get_tree().current_scene else null
	if hud and hud.has_method("show_announcement"):
		hud.show_announcement("UYARI: DEMİR ÇEMBER KUŞATMASI!", Color(0.95, 0.75, 0.2))
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.05, 2.5)
		
	var count := 20
	var radius := spawn_dist_min * 0.95
	for i in range(count):
		var angle := (TAU / float(count)) * float(i)
		var pos := player.global_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var brute = enemy_scene.instantiate()
		brute.position = pos
		brute.max_health = 75.0
		brute.move_speed = 3.2
		brute.contact_damage = 22.0
		var sp = brute.get_node_or_null("Sprite3D")
		var tex: Texture2D = load(enemy_archetypes[5]["texture"])
		if sp and tex:
			sp.texture = tex
			sp.pixel_size = enemy_archetypes[5]["scale"]
			sp.modulate = Color(0.8, 0.85, 0.95)
		get_parent().add_child(brute)

func _trigger_shadow_rush() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD") if get_tree().current_scene else null
	if hud and hud.has_method("show_announcement"):
		hud.show_announcement("TEHLİKE: GÖLGE HÜCUMU BAŞLADI!", Color(0.85, 0.25, 0.95))
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.05, 3.2)
		
	for i in range(18):
		var spawn_pos := _get_offscreen_spawn_pos()
		var ghost = enemy_scene.instantiate()
		ghost.position = spawn_pos
		ghost.max_health = 45.0
		ghost.move_speed = 7.5
		ghost.contact_damage = 18.0
		var sp = ghost.get_node_or_null("Sprite3D")
		var tex: Texture2D = load(enemy_archetypes[9]["texture"])
		if sp and tex:
			sp.texture = tex
			sp.pixel_size = enemy_archetypes[9]["scale"] * 1.15
			sp.modulate = Color(0.65, 0.2, 0.9, 0.85)
		get_parent().add_child(ghost)

func _spawn_pact_shrine() -> void:
	if not shrine_scene or not player:
		return
	var shrine = shrine_scene.instantiate()
	var angle := randf() * TAU
	var dist := randf_range(16.0, 28.0)
	shrine.position = player.global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	get_parent().add_child(shrine)
	
	var hud = get_tree().current_scene.get_node_or_null("HUD") if get_tree().current_scene else null
	if hud and hud.has_method("show_announcement"):
		hud.show_announcement("KADİM BİR SUNAK BELİRDİ! [E] İLE ETKİLEŞİME GEÇ", Color(0.85, 0.45, 1.0))
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("upgrade", 0.0, 1.2)

func _reposition_distant_enemies() -> void:
	var tree = get_tree()
	if not tree: return
	var enemies = tree.get_nodes_in_group("enemies")
	var p_pos := player.global_position
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.get("is_boss") == true:
			continue
			
		var dist := p_pos.distance_to(enemy.global_position)
		if dist > despawn_reposition_distance:
			var target_angle := randf() * TAU
			if player is CharacterBody3D and player.velocity != Vector3.ZERO:
				if randf() < 0.7:
					var p_vel_2d := Vector2(player.velocity.x, player.velocity.z)
					target_angle = p_vel_2d.angle() + randf_range(-PI * 0.35, PI * 0.35)
					
			var new_dist := randf_range(spawn_dist_min, spawn_dist_max)
			enemy.global_position = p_pos + Vector3(cos(target_angle) * new_dist, 0.0, sin(target_angle) * new_dist)
