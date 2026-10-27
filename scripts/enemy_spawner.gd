extends Node2D

signal king_boss_defeated()

@export var spawn_interval: float = 0.6
@export var max_active_enemies: int = 280

# Ekran dışı doğma ve taşıma mesafeleri
# Normal görünür kamera alanı yarıçapı: ~710x400 (köşe ~815px)
@export var spawn_distance_min: float = 850.0
@export var spawn_distance_max: float = 950.0
@export var despawn_reposition_distance: float = 1350.0

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

var timer: float = 0.0
var elapsed_game_time: float = 0.0
var reposition_check_timer: float = 0.0
var boss_spawned_5min: bool = false
var boss_spawned_10min: bool = false
var next_elite_spawn_time: float = 60.0

func _process(delta: float) -> void:
	elapsed_game_time += delta
	timer += delta
	reposition_check_timer += delta
	
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	# Her 1 dakikada bir (60 sn) Elit Canavar doğar
	if elapsed_game_time >= next_elite_spawn_time:
		next_elite_spawn_time += 60.0
		_spawn_elite_monster()
		
	# Boss kontrolleri (5. ve 10. dakikalar)
	if elapsed_game_time >= 300.0 and not boss_spawned_5min:
		boss_spawned_5min = true
		_spawn_boss()
	if elapsed_game_time >= 600.0 and not boss_spawned_10min:
		boss_spawned_10min = true
		_spawn_boss()
		
	# 1. Uzaklaşan düşmanları taşıma
	if reposition_check_timer >= 0.25:
		reposition_check_timer = 0.0
		_reposition_distant_enemies()
		
	# 2. Yeni doğma döngüsü (Süre arttıkça tek seferde birden fazla düşman doğar)
	var current_interval: float = maxf(0.08, spawn_interval - (elapsed_game_time * 0.0018))
	if timer >= current_interval:
		timer = 0.0
		var current_enemy_count := get_tree().get_nodes_in_group("enemies").size()
		var spawn_batch_size: int = 1 + int(elapsed_game_time / 45.0)
		spawn_batch_size = mini(spawn_batch_size, 6) # Tek tetiklemede 1-6 arası doğar
		
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

func _spawn_boss() -> void:
	var spawn_pos := _get_offscreen_spawn_position()
	var boss = enemy_scenes[11].instantiate()
	boss.global_position = spawn_pos
	
	# 5. dk bossu 8,500 HP, 10. dk final bossu 24,000 HP
	var boss_hp: float = 8500.0 if elapsed_game_time < 500.0 else 24000.0
	var boss_dmg: float = 35.0 if elapsed_game_time < 500.0 else 55.0
	
	if boss.has_method("setup_boss"):
		boss.setup_boss(boss_hp, boss_dmg)
	else:
		boss.is_boss = true
		boss.max_health = boss_hp
		boss.health = boss_hp
		boss.damage = boss_dmg
		
	boss.move_speed = 75.0
	if "base_scale" in boss:
		boss.base_scale = boss.base_scale * 1.6
	boss.scale = boss.scale * 1.6
	
	if boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(func(): emit_signal("king_boss_defeated"))
	var entities := get_tree().current_scene.get_node_or_null("YSortEntities")
	if entities:
		entities.add_child(boss)
	else:
		get_tree().current_scene.add_child(boss)

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
	
	var entities := get_tree().current_scene.get_node_or_null("YSortEntities")
	if entities:
		entities.add_child(elite)
	else:
		get_tree().current_scene.add_child(elite)

func _spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		return
		
	var spawn_pos := _get_offscreen_spawn_position()
	var roll := randf()
	var picked_scene: PackedScene
	
	# 20 Dakikalık Kademeli Havuz ve Renk/Stat Varyantı Sistemi
	var minute: int = int(elapsed_game_time / 60.0)
	
	# Dakika Bazlı Düşman Havuzları (Her dakikanın belirgin bir teması var):
	# 0: Eyeball & Bat (Hafif başlangıç)
	# 1: Bee & Frog (Hızlı hareket edenler)
	# 2: Chomper & Noodles (Orta hız, dişli yırtıcılar)
	# 3: Snail & Flower (Zırhlı tanklar ve alan kaplayanlar)
	# 4: Ghost & WingEye (Engellerden sızanlar ve uçanlar)
	# 5: Brute & Snail (Ağır zırhlı kuşatma)
	# 6-8: Hızlılar + Yırtıcılar (Bee, Frog, Chomper, WingEye)
	# 9-11: Tanklar + Hayaletler (Flower, Brute, Ghost, Snail)
	# 12+: Tam Karışım ve Baskın Dalgalar
	var pool_indices: Array[int] = []
	if minute == 0:
		pool_indices = [0, 0, 7] # Eyeball, Bat
	elif minute == 1:
		pool_indices = [2, 8, 0] # Bee, Frog, Eyeball
	elif minute == 2:
		pool_indices = [3, 1, 8] # Chomper, Noodles, Frog
	elif minute == 3:
		pool_indices = [4, 9, 3] # Snail, Flower, Chomper
	elif minute == 4:
		pool_indices = [6, 10, 2] # Ghost, WingEye, Bee
	elif minute == 5:
		pool_indices = [5, 4, 1] # Brute, Snail, Noodles
	elif minute in [6, 7, 8]:
		pool_indices = [2, 3, 8, 10] # Bee, Chomper, Frog, WingEye (Hızlı Saldırı)
	elif minute in [9, 10, 11]:
		pool_indices = [5, 9, 6, 4] # Brute, Flower, Ghost, Snail (Ağır Baskı)
	else:
		pool_indices = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] # Kaos Dalgaları
		
	var chosen_idx: int = pool_indices[randi() % pool_indices.size()]
	picked_scene = enemy_scenes[chosen_idx]
			
	var enemy = picked_scene.instantiate()
	enemy.global_position = spawn_pos
	
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
		
	# Dakikaya göre temel can ve hız artışı
	var time_hp_mult: float = (1.0 + (elapsed_game_time / 60.0) * 0.14) * extra_hp_mult
	enemy.max_health *= time_hp_mult
	enemy.health = enemy.max_health
	enemy.damage *= extra_dmg_mult
	
	var speed_bonus: float = minf(0.25, (elapsed_game_time / 60.0) * 0.02)
	enemy.move_speed *= (1.0 + speed_bonus)
	
	if enemy.has_method("set_variant"):
		enemy.set_variant(tint_color, scale_bonus)
	
	var entities := get_tree().current_scene.get_node_or_null("YSortEntities")
	if entities:
		entities.add_child(enemy)
	else:
		get_tree().current_scene.add_child(enemy)

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
