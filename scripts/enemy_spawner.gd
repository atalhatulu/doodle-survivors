extends Node2D

signal king_boss_defeated()

@export var spawn_interval: float = 0.6
@export var max_active_enemies: int = 280

# Ekran dışı doğma ve taşıma mesafeleri
# Kamera 0.7 zoom ile görünür ekran köşesi ~1050px
@export var spawn_distance_min: float = 1100.0
@export var spawn_distance_max: float = 1250.0
@export var despawn_reposition_distance: float = 1550.0

@export var debug_draw_zones: bool = false

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var enemy_scenes: Array[PackedScene] = [
	preload("res://scenes/enemies/enemy_eyeball.tscn"),  # 0: Tek Göz / Eyeball
	preload("res://scenes/enemies/enemy_noodles.tscn"),  # 1: Çok Kollu / Noodles
	preload("res://scenes/enemies/enemy_bee.tscn"),      # 2: Gözlüklü Arı / Fast Bee
	preload("res://scenes/enemies/enemy_chomper.tscn"),  # 3: Sivri Diş / Chomper
	preload("res://scenes/enemies/enemy_snail.tscn"),    # 4: Zırhlı Salyangoz / Snail
	preload("res://scenes/enemies/enemy_brute.tscn"),    # 5: Kutu Golem / Brute
	preload("res://scenes/enemies/enemy_ghost.tscn"),    # 6: Hayalet / Ghost (engellerden geçer)
	preload("res://scenes/enemies/enemy_bat.tscn"),      # 7: Yarasa / Swarm Bat
	preload("res://scenes/enemies/enemy_frog.tscn"),     # 8: Kurbağa / Fast Leaper
	preload("res://scenes/enemies/enemy_flower.tscn"),   # 9: Çiçek / Heavy Plant
	preload("res://scenes/enemies/enemy_wingeye.tscn"),  # 10: Kanatlı Göz / Wing Eye
	preload("res://scenes/enemies/enemy_king.tscn")      # 11: Taçlı Kral / Mini Boss
]

# 16 Asıl Dark Fantasy Düşman Arketipi (assets/sprites/enemies/)
var dark_fantasy_archetypes: Array[Dictionary] = [
	{"texture": "res://assets/sprites/enemies/enemy_spider.png", "health": 20.0, "speed": 115.0, "damage": 8.0, "scale": 0.42, "name": "spider"},
	{"texture": "res://assets/sprites/enemies/enemy_bat_flyer.png", "health": 18.0, "speed": 135.0, "damage": 9.0, "scale": 0.40, "name": "bat_flyer"},
	{"texture": "res://assets/sprites/enemies/enemy_bee_gasmask.png", "health": 24.0, "speed": 125.0, "damage": 10.0, "scale": 0.42, "name": "bee_gasmask"},
	{"texture": "res://assets/sprites/enemies/enemy_slime_puddle.png", "health": 32.0, "speed": 72.0, "damage": 11.0, "scale": 0.44, "name": "slime_puddle"},
	{"texture": "res://assets/sprites/enemies/enemy_snail.png", "health": 70.0, "speed": 45.0, "damage": 14.0, "scale": 0.45, "name": "snail"},
	{"texture": "res://assets/sprites/enemies/enemy_spiky.png", "health": 42.0, "speed": 92.0, "damage": 15.0, "scale": 0.43, "name": "spiky"},
	{"texture": "res://assets/sprites/enemies/enemy_armored_turtle.png", "health": 120.0, "speed": 50.0, "damage": 20.0, "scale": 0.48, "name": "armored_turtle"},
	{"texture": "res://assets/sprites/enemies/enemy_plant_monster.png", "health": 85.0, "speed": 65.0, "damage": 22.0, "scale": 0.48, "name": "plant_monster"},
	{"texture": "res://assets/sprites/enemies/enemy_wasp_flying.png", "health": 35.0, "speed": 138.0, "damage": 13.0, "scale": 0.40, "name": "wasp_flying"},
	{"texture": "res://assets/sprites/enemies/enemy_spiky_ghost.png", "health": 48.0, "speed": 105.0, "damage": 16.0, "scale": 0.44, "name": "spiky_ghost"},
	{"texture": "res://assets/sprites/enemies/enemy_alien_biped.png", "health": 60.0, "speed": 105.0, "damage": 18.0, "scale": 0.46, "name": "alien_biped"},
	{"texture": "res://assets/sprites/enemies/enemy_dino_biped.png", "health": 95.0, "speed": 98.0, "damage": 24.0, "scale": 0.48, "name": "dino_biped"},
	{"texture": "res://assets/sprites/enemies/enemy_wood_log_spiked.png", "health": 140.0, "speed": 58.0, "damage": 28.0, "scale": 0.50, "name": "wood_log_spiked"},
	{"texture": "res://assets/sprites/enemies/enemy_octopus.png", "health": 160.0, "speed": 68.0, "damage": 26.0, "scale": 0.50, "name": "octopus"},
	{"texture": "res://assets/sprites/enemies/enemy_fury_cyclops.png", "health": 220.0, "speed": 85.0, "damage": 34.0, "scale": 0.54, "name": "fury_cyclops"},
	{"texture": "res://assets/sprites/enemies/enemy_brute_cyclops.png", "health": 450.0, "speed": 60.0, "damage": 42.0, "scale": 0.62, "name": "brute_cyclops"}
]

var pact_shrine_scene: PackedScene = preload("res://scenes/world/pact_shrine.tscn")

var timer: float = 0.0
var elapsed_game_time: float = 0.0
var reposition_check_timer: float = 0.0
var boss_spawned_5min: bool = false
var boss_spawned_10min: bool = false
var boss_spawned_15min: bool = false
var boss_spawned_20min: bool = false
var next_elite_spawn_time: float = 60.0

var event_spawned_4min: bool = false
var event_spawned_8min: bool = false
var event_spawned_14min: bool = false
var shrine_spawned_2min: bool = false
var shrine_spawned_7min: bool = false
var shrine_spawned_12min: bool = false

func _process(delta: float) -> void:
	elapsed_game_time += delta
	timer += delta
	reposition_check_timer += delta
	
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	# Kadim Sunaklar (Pact Shrines)
	if elapsed_game_time >= 120.0 and not shrine_spawned_2min:
		shrine_spawned_2min = true
		_spawn_pact_shrine()
	if elapsed_game_time >= 420.0 and not shrine_spawned_7min:
		shrine_spawned_7min = true
		_spawn_pact_shrine()
	if elapsed_game_time >= 720.0 and not shrine_spawned_12min:
		shrine_spawned_12min = true
		_spawn_pact_shrine()
		
	# Her 1 dakikada bir (60 sn) Elit Canavar doğar
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
		_spawn_boss(false, 8500.0, 35.0)
	if elapsed_game_time >= 600.0 and not boss_spawned_10min:
		boss_spawned_10min = true
		_spawn_boss(false, 18000.0, 50.0)
	if elapsed_game_time >= 900.0 and not boss_spawned_15min:
		boss_spawned_15min = true
		_spawn_boss(false, 32000.0, 65.0)
	if elapsed_game_time >= 1200.0 and not boss_spawned_20min:
		boss_spawned_20min = true
		_spawn_boss(true, 55000.0, 85.0)
		
	# 1. Uzaklaşan düşmanları taşıma
	if reposition_check_timer >= 0.25:
		reposition_check_timer = 0.0
		_reposition_distant_enemies()
		
	# 2. Yeni doğma döngüsü (Süre arttıkça ve Lanet/Curse ile düşmanlar hızlanır)
	var curse: float = player.curse_mult if player and "curse_mult" in player else 1.0
	var current_interval: float = maxf(0.06, (spawn_interval - (elapsed_game_time * 0.0018)) / curse)
	if timer >= current_interval:
		timer = 0.0
		var current_enemy_count := get_tree().get_nodes_in_group("enemies").size()
		var spawn_batch_size: int = 1 + int(elapsed_game_time / 45.0)
		if curse > 1.0:
			spawn_batch_size = int(round(spawn_batch_size * curse))
		spawn_batch_size = mini(spawn_batch_size, 8) # Tek tetiklemede 1-8 arası doğar
		
		for b in range(spawn_batch_size):
			if current_enemy_count + b < max_active_enemies:
				_spawn_enemy()
			
	if debug_draw_zones:
		queue_redraw()

func _draw() -> void:
	if not debug_draw_zones or not player or not is_instance_valid(player):
		return
		
	var center := player.global_position
	var cam_w := 1280.0 / 0.9
	var cam_h := 720.0 / 0.9
	var cam_rect := Rect2(center - Vector2(cam_w * 0.5, cam_h * 0.5), Vector2(cam_w, cam_h))
	draw_rect(cam_rect, Color(0.2, 0.6, 1.0, 0.9), false, 4.0)
	draw_arc(center, spawn_distance_min, 0, TAU, 64, Color(0.2, 1.0, 0.4, 0.7), 3.0)
	draw_arc(center, spawn_distance_max, 0, TAU, 64, Color(1.0, 0.9, 0.2, 0.7), 3.0)
	draw_arc(center, despawn_reposition_distance, 0, TAU, 64, Color(1.0, 0.2, 0.2, 0.8), 4.0)

func _get_offscreen_spawn_position() -> Vector2:
	var angle := randf() * TAU
	var dist := randf_range(spawn_distance_min, spawn_distance_max)
	return player.global_position + Vector2(cos(angle), sin(angle)) * dist

func _spawn_boss(is_final_boss: bool = false, hp: float = 8500.0, dmg: float = 35.0) -> void:
	var spawn_pos := _get_offscreen_spawn_position()
	var boss = enemy_scenes[11].instantiate()
	boss.global_position = spawn_pos
	
	if boss.has_method("setup_boss"):
		boss.setup_boss(hp, dmg)
	else:
		boss.is_boss = true
		boss.max_health = hp
		boss.health = hp
		boss.damage = dmg
		
	boss.move_speed = 75.0
	if "base_scale" in boss:
		boss.base_scale = boss.base_scale * 1.6
	boss.scale = boss.scale * 1.6
	
	if is_final_boss:
		if boss.has_signal("boss_defeated"):
			boss.boss_defeated.connect(func(): emit_signal("king_boss_defeated"))
	_add_enemy_to_scene(boss)

func _spawn_elite_monster() -> void:
	var spawn_pos := _get_offscreen_spawn_position()
	# Golem / Brute (indis 5) veya Chomper (indis 3) elit olarak doğsun
	var elite_scene: PackedScene = enemy_scenes[5] if randf() < 0.6 else enemy_scenes[3]
	var elite = elite_scene.instantiate()
	elite.global_position = spawn_pos
	
	# Dakikaya göre dengeli mini-boss canı:
	# 1. dk: 1,400 HP | 2. dk: 2,500 HP | 3. dk: 3,800 HP | 4. dk: 5,400 HP
	var minute: float = maxf(1.0, elapsed_game_time / 60.0)
	var elite_hp: float = 1400.0 * pow(minute, 0.95)
	var elite_dmg: float = 24.0 + (minute * 3.5)
	
	if elite.has_method("setup_elite"):
		elite.setup_elite(elite_hp, elite_dmg)
	else:
		elite.is_elite = true
		elite.max_health = elite_hp
		elite.health = elite_hp
		elite.damage = elite_dmg
		
	elite.move_speed = 80.0
	
	# Görsel olarak devasa boyutta ve hafif altın/kırmızı ışıltılı
	if "base_scale" in elite:
		elite.base_scale = elite.base_scale * 2.2
	elite.scale = elite.scale * 2.2
	elite.modulate = Color(1.3, 0.9, 0.4, 1.0) # Altın Elit Aurası
	_add_enemy_to_scene(elite)

func _spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		return
		
	var spawn_pos := _get_offscreen_spawn_position()
	var roll := randf()
	var picked_scene: PackedScene
	
	# 20 Dakikalık Kademeli Havuz ve Renk/Stat Varyantı Sistemi
	var minute: int = int(elapsed_game_time / 60.0)
	
	# Dakika Bazlı Düşman Havuzları (16 Dark Fantasy Arketipi ve Düşman Sahneleri Harmanı):
	# 0: Spider, Bat flyer, Eyeball (Hafif başlangıç)
	# 1: Bee gasmask, Slime puddle, Frog (Hızlı ve zehirli)
	# 2: Snail, Spiky, Chomper (Zırhlı ve dikenli)
	# 3: Armored turtle, Plant monster, Snail (Ağır tanklar ve bitkiler)
	# 4: Wasp flying, Spiky ghost, Ghost (Uçan iğneliler ve hayaletler)
	# 5: Alien biped, Dino biped, Brute (İki ayaklı çevik yırtıcılar)
	# 6-8: Plant monster, Wasp, Wood log spiked, Octopus (Orman gardiyanları ve dokunaçlılar)
	# 9-11: Dino biped, Wood log, Octopus, Fury cyclops (Ağır baskı ve elitler)
	# 12+: 16 Canavar Türünün Tamamı ve Kaos Dalgaları
	var pool_indices: Array[int] = []
	if minute == 0:
		pool_indices = [0, 0, 1] # spider, spider, bat_flyer
	elif minute == 1:
		pool_indices = [0, 2, 3] # spider, bee_gasmask, slime_puddle
	elif minute == 2:
		pool_indices = [4, 5, 2] # snail, spiky, bee_gasmask
	elif minute == 3:
		pool_indices = [6, 7, 5] # armored_turtle, plant_monster, spiky
	elif minute == 4:
		pool_indices = [8, 9, 1] # wasp_flying, spiky_ghost, bat_flyer
	elif minute == 5:
		pool_indices = [10, 11, 6] # alien_biped, dino_biped, armored_turtle
	elif minute in [6, 7, 8]:
		pool_indices = [7, 8, 12, 13] # plant_monster, wasp, wood_log_spiked, octopus
	elif minute in [9, 10, 11]:
		pool_indices = [11, 12, 13, 14] # dino_biped, wood_log, octopus, fury_cyclops
	else:
		pool_indices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
		
	var chosen_idx: int = pool_indices[randi() % pool_indices.size()]
	var arch: Dictionary = dark_fantasy_archetypes[chosen_idx]
	
	# Temel sahne olarak eyeball (0) veya uygun sahneyi örnekle ve arketip uygula
	var enemy = enemy_scenes[0].instantiate()
	enemy.global_position = spawn_pos
	if enemy.has_method("setup_archetype"):
		enemy.setup_archetype(arch["name"], arch["texture"], arch["scale"], arch["health"], arch["speed"], arch["damage"])
	
	# İlerleyen dakikalarda Renkli Güçlü Formlar (Doodle Ink Variants):
	# 0-2 dk: Klasik Kağıt Beyazı
	# 3-5 dk: Turuncu Mürekkep (%25 şans, +%40 Can, +%20 Hasar, 1.1x Boyut)
	# 6-9 dk: Kızıl Çini Mürekkebi (%35 şans, +%80 Can, +%35 Hasar, 1.15x Boyut)
	# 10+ dk: Mor Mühür / Lanetli (%45 şans, +%130 Can, +%50 Hasar, 1.25x Boyut)
	var tint_color := Color(1, 1, 1, 1)
	var scale_bonus := 1.0
	var extra_hp_mult := 1.0
	var extra_dmg_mult := 1.0
	
	var variant_roll := randf()
	if minute >= 10 and variant_roll < 0.45:
		tint_color = Color(0.75, 0.35, 1.2, 1.0) # Mor Lanetli Form
		scale_bonus = 1.22
		extra_hp_mult = 2.3
		extra_dmg_mult = 1.5
	elif minute >= 6 and variant_roll < 0.35:
		tint_color = Color(1.2, 0.4, 0.35, 1.0) # Kızıl Öfkeli Form
		scale_bonus = 1.15
		extra_hp_mult = 1.8
		extra_dmg_mult = 1.35
	elif minute >= 3 and variant_roll < 0.25:
		tint_color = Color(1.2, 0.8, 0.3, 1.0) # Turuncu Güçlü Form
		scale_bonus = 1.08
		extra_hp_mult = 1.4
		extra_dmg_mult = 1.20
		
	# Dakikaya ve Lanet (Curse) durumuna göre temel can, hasar ve hız artışı
	var curse_stat: float = player.curse_mult if player and "curse_mult" in player else 1.0
	var time_hp_mult: float = (1.0 + (elapsed_game_time / 60.0) * 0.14) * extra_hp_mult * curse_stat
	enemy.max_health *= time_hp_mult
	enemy.health = enemy.max_health
	enemy.damage *= extra_dmg_mult * (1.0 + (curse_stat - 1.0) * 0.5)
	
	var speed_bonus: float = minf(0.35, (elapsed_game_time / 60.0) * 0.02 + (curse_stat - 1.0) * 0.1)
	enemy.move_speed *= (1.0 + speed_bonus)
	
	_add_enemy_to_scene(enemy)
	if enemy.has_method("set_variant"):
		enemy.set_variant(tint_color, scale_bonus)

func _reposition_distant_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var p_pos := player.global_position
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
			
		var dist := p_pos.distance_to(enemy.global_position)
		if dist > despawn_reposition_distance:
			var target_angle := randf() * TAU
			if player is CharacterBody2D and player.velocity != Vector2.ZERO:
				if randf() < 0.7:
					target_angle = player.velocity.angle() + randf_range(-PI * 0.35, PI * 0.35)
					
			var new_pos := p_pos + Vector2(cos(target_angle), sin(target_angle)) * randf_range(spawn_distance_min, spawn_distance_max)
			enemy.global_position = new_pos

func _add_enemy_to_scene(enemy_node: Node) -> void:
	var target_scene: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	var entities := target_scene.get_node_or_null("YSortEntities")
	if entities:
		entities.add_child(enemy_node)
	else:
		target_scene.add_child(enemy_node)

func _trigger_bat_swarm() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("show_announcement"):
		hud.show_announcement("DİKKAT: YARASA AKINI YAKLAŞIYOR!", Color(1.0, 0.3, 0.2))
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.05, 3.0)
		
	var side_sign := 1.0 if randf() < 0.5 else -1.0
	var base_x := player.global_position.x + side_sign * spawn_distance_min
	for i in range(35):
		var bat = enemy_scenes[7].instantiate() # enemy_bat
		var offset_y := randf_range(-600.0, 600.0)
		var offset_x := randf_range(-120.0, 120.0)
		bat.global_position = Vector2(base_x + offset_x, player.global_position.y + offset_y)
		bat.move_speed = 185.0
		if "max_health" in bat:
			bat.max_health = 18.0
			bat.health = 18.0
		_add_enemy_to_scene(bat)

func _trigger_iron_circle() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("show_announcement"):
		hud.show_announcement("UYARI: DEMİR ÇEMBER KUŞATMASI!", Color(0.95, 0.75, 0.2))
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.05, 2.5)
		
	var count := 36
	var radius := spawn_distance_min * 0.95
	for i in range(count):
		var angle := (TAU / float(count)) * float(i)
		var pos := player.global_position + Vector2(cos(angle), sin(angle)) * radius
		var brute = enemy_scenes[5].instantiate() # enemy_brute
		brute.global_position = pos
		if "max_health" in brute:
			brute.max_health = 120.0
			brute.health = 120.0
		if brute.has_method("set_variant"):
			brute.set_variant(Color(0.8, 0.85, 0.95), 1.1)
		_add_enemy_to_scene(brute)

func _trigger_shadow_rush() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("show_announcement"):
		hud.show_announcement("TEHLİKE: GÖLGE HÜCUMU BAŞLADI!", Color(0.85, 0.25, 0.95))
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.05, 3.2)
		
	for i in range(28):
		var spawn_pos := _get_offscreen_spawn_position()
		var ghost = enemy_scenes[6].instantiate() # enemy_ghost
		ghost.global_position = spawn_pos
		ghost.move_speed = 195.0
		if "max_health" in ghost:
			ghost.max_health = 80.0
			ghost.health = 80.0
		if ghost.has_method("set_variant"):
			ghost.set_variant(Color(0.65, 0.2, 0.9, 0.85), 1.15)
		_add_enemy_to_scene(ghost)

func _spawn_pact_shrine() -> void:
	if not pact_shrine_scene or not player:
		return
	var shrine = pact_shrine_scene.instantiate()
	var angle := randf() * TAU
	var dist := randf_range(250.0, 420.0)
	shrine.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var target_scene: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_scene.add_child(shrine)
	
	var hud = get_tree().current_scene.get_node_or_null("HUD") if get_tree().current_scene else null
	if hud and hud.has_method("show_announcement"):
		hud.show_announcement("KADİM BİR SUNAK BELİRDİ! [E] İLE ETKİLEŞİME GEÇ", Color(0.85, 0.45, 1.0))
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("upgrade", 0.0, 1.2)

