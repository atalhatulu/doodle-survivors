extends Node2D

@export var weapon_id: String = "weapon_ranged"
@export var current_level: int = 1

@export var fire_rate: float = 0.65
@export var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")
@export var range_radius: float = 400.0
@export var damage: float = 16.0
@export var projectiles_count: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Sprite2D/Muzzle
@onready var player: Node2D = get_tree().get_first_node_in_group("player")

@export var targeting_mode: String = "SECTOR" # SECTOR, CLOSEST, STRONGEST, FARTHEST, MOVEMENT_DIR

var fire_timer: float = 0.0
var target_scan_timer: float = 0.0
var current_target: Node2D = null
var base_sprite_pos_x: float = 0.0

# Temel değerleri yükseltme çarpanları için saklayalım
var base_damage: float = 16.0
var base_fire_rate: float = 0.65
var base_projectiles_count: int = 1

func _ready() -> void:
	base_damage = damage
	base_fire_rate = fire_rate
	base_projectiles_count = projectiles_count
	if sprite:
		base_sprite_pos_x = sprite.position.x
	if not player:
		player = get_tree().get_first_node_in_group("player")

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	# Seviye başına +%35 hasar, +%10 atış hızı
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)
	fire_rate = maxf(0.10, base_fire_rate * (1.0 - (current_level - 1) * 0.10))
	range_radius = 400.0 * (1.0 + (current_level - 1) * 0.05)
	
	if current_level >= 7:
		damage *= 1.25 # 7. seviye zirve bonusu
		
	# Yükselme efekti (Silah küçük bir zıplama yapsın)
	if sprite:
		var tw := create_tween()
		tw.tween_property(sprite, "scale", sprite.scale * 1.35, 0.15)
		tw.tween_property(sprite, "scale", sprite.scale, 0.15)

func _process(delta: float) -> void:
	var cd_mult: float = 1.0
	if player and "cooldown_mult" in player:
		cd_mult = player.cooldown_mult
		
	fire_timer += delta
	target_scan_timer += delta
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		
	if target_scan_timer >= 0.10 or current_target == null or not is_instance_valid(current_target) or ("is_dead" in current_target and current_target.is_dead):
		target_scan_timer = 0.0
		_find_target()
	
	if current_target and is_instance_valid(current_target) and not ("is_dead" in current_target and current_target.is_dead):
		var target_dir := (current_target.global_position - global_position).normalized()
		var target_angle := target_dir.angle()
		global_rotation = target_angle
		
		var is_facing_left: bool = abs(fposmod(global_rotation + PI, TAU) - PI) > PI * 0.5
		scale.y = -1.0 if is_facing_left else 1.0
			
		if fire_timer >= (fire_rate * cd_mult):
			fire_timer = 0.0
			_shoot(target_dir)
	else:
		current_target = null
		global_rotation = lerp_angle(global_rotation, 0.0, delta * 5.0)
		scale.y = 1.0

func _find_target() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	current_target = null
	if enemies.is_empty():
		return
		
	var center_pos := player.global_position if (player and is_instance_valid(player)) else global_position
	var candidate_enemies: Array[Dictionary] = []
	var closest_candidate: Node2D = null
	var min_dist: float = 999999.0
	
	for e in enemies:
		var enemy: Node2D = e as Node2D
		if is_instance_valid(enemy):
			if "is_dead" in enemy and enemy.is_dead:
				continue
			var to_enemy: Vector2 = enemy.global_position - center_pos
			var d: float = to_enemy.length()
			if d <= range_radius:
				var hp: float = enemy.health if "health" in enemy else 10.0
				candidate_enemies.append({"enemy": enemy, "dist": d, "hp": hp, "to_enemy": to_enemy})
				if d < min_dist:
					min_dist = d
					closest_candidate = enemy
				
	if candidate_enemies.is_empty():
		return
		
	# KRİTİK KORUMA: Oyuncunun dibinde (acil tehlike menzili <= 160px) düşman varsa,
	# diğer modlar ne olursa olsun mutlak öncelikle dibimizdeki tehdide odaklan!
	if closest_candidate and min_dist <= 160.0:
		current_target = closest_candidate
		return
		
	match targeting_mode:
		"CLOSEST": # Hançer: En yakındaki acil tehdit
			candidate_enemies.sort_custom(func(a, b): return a["dist"] < b["dist"])
			current_target = candidate_enemies[0]["enemy"]
			
		"STRONGEST": # Büyü Asası: En yüksek canlı / Tank düşmanlar
			candidate_enemies.sort_custom(func(a, b):
				if a["hp"] != b["hp"]:
					return a["hp"] > b["hp"]
				return a["dist"] < b["dist"]
			)
			current_target = candidate_enemies[0]["enemy"]
			
		"FARTHEST": # Bumerang: Menzil ucundaki uzak hedefler
			candidate_enemies.sort_custom(func(a, b): return a["dist"] > b["dist"])
			current_target = candidate_enemies[0]["enemy"]
			
		"MOVEMENT_DIR": # Şövalye Kılıcı: Oyuncunun koştuğu/baktığı yöndeki hedefler
			var move_dir := Vector2.RIGHT
			if player is CharacterBody2D and player.velocity.length() > 10.0:
				move_dir = player.velocity.normalized()
			elif player and "facing_direction" in player:
				move_dir = Vector2(player.facing_direction, 0.0)
				
			candidate_enemies.sort_custom(func(a, b):
				var dot_a: float = move_dir.dot(a["to_enemy"].normalized())
				var dot_b: float = move_dir.dot(b["to_enemy"].normalized())
				return dot_a > dot_b
			)
			current_target = candidate_enemies[0]["enemy"]
			
		"SECTOR", _: # Avcı Yayı: Kendi sektörünü koruma
			var my_slot_angle: float = get_parent().position.angle() if get_parent() and get_parent() is Marker2D else 0.0
			candidate_enemies.sort_custom(func(a, b):
				var diff_a: float = abs(wrapf(a["to_enemy"].angle() - my_slot_angle, -PI, PI))
				var diff_b: float = abs(wrapf(b["to_enemy"].angle() - my_slot_angle, -PI, PI))
				var score_a: float = a["dist"] + diff_a * 150.0
				var score_b: float = b["dist"] + diff_b * 150.0
				return score_a < score_b
			)
			current_target = candidate_enemies[0]["enemy"]

func _shoot(dir: Vector2) -> void:
	if not bullet_scene:
		return
		
	var dmg_mult: float = 1.0
	var area_scale: float = 1.0
	var crit_prob: float = 0.05
	var extra_proj: int = 0
	var speed_mult: float = 1.0
	if player:
		if "damage_multiplier" in player:
			dmg_mult = player.damage_multiplier
		if "area_mult" in player:
			area_scale = player.area_mult
		if "crit_chance" in player:
			crit_prob = player.crit_chance
		if "extra_projectiles" in player:
			extra_proj = player.extra_projectiles
		if "projectile_speed_mult" in player:
			speed_mult = player.projectile_speed_mult
			
	var is_crit: bool = randf() < crit_prob
	var final_damage: float = damage * dmg_mult * (2.0 if is_crit else 1.0)
	
	var count: int = max(1, projectiles_count + extra_proj)
	var spawn_pos: Vector2 = muzzle.global_position if muzzle else global_position
	
	# Mermi yayılımı (Çoklu atışlarda fan şeklinde yayılma)
	var spread_angle: float = 0.16
	var base_angle: float = dir.angle()
	var start_angle: float = base_angle - (float(count - 1) * spread_angle * 0.5)
	
	for i in range(count):
		var b = bullet_scene.instantiate()
		var fire_ang: float = start_angle + i * spread_angle
		var cur_dir := Vector2(cos(fire_ang), sin(fire_ang))
		
		b.global_position = spawn_pos
		b.direction = cur_dir
		b.damage = final_damage
		b.rotation = fire_ang
		if "is_crit" in b:
			b.is_crit = is_crit
		if "speed" in b:
			b.speed = b.speed * speed_mult
		
		if "source_weapon_id" in b:
			b.source_weapon_id = weapon_id
		if "scale" in b:
			b.scale = b.scale * area_scale
		var target_node: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
		target_node.add_child(b)
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		if weapon_id == "weapon_sword":
			audio.play_sfx("pencil_slash", 0.12)
		else:
			audio.play_sfx("shoot", 0.10)
	
	if sprite:
		var tween := create_tween()
		sprite.position.x = base_sprite_pos_x - 8.0
		tween.tween_property(sprite, "position:x", base_sprite_pos_x, 0.1)
