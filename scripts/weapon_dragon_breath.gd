extends Node2D

@export var weapon_id: String = "weapon_dragon_breath"
@export var current_level: int = 1

@export var base_damage: float = 22.0
@export var base_burst_duration: float = 1.4
@export var base_cooldown: float = 2.0
@export var cone_range: float = 180.0
@export var cone_angle_deg: float = 48.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var is_breathing: bool = false
var state_timer: float = 0.0
var tick_timer: float = 0.0
var damage: float = 22.0
var puff_spawn_timer: float = 0.0

func _ready() -> void:
	damage = base_damage
	if not player:
		player = get_tree().get_first_node_in_group("player")

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)
	cone_range = 180.0 * (1.0 + (current_level - 1) * 0.12)
	cone_angle_deg = minf(75.0, 48.0 + (current_level - 1) * 4.0)
	if current_level >= 7:
		damage *= 1.45
		cone_range *= 1.25

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	global_position = player.global_position + Vector2(0, -20)
	
	# Karakterin yönünü al
	var aim_dir := Vector2.RIGHT
	if player is CharacterBody2D and player.velocity.length_squared() > 100.0:
		aim_dir = player.velocity.normalized()
	elif "facing_direction" in player:
		aim_dir = Vector2(player.facing_direction, 0.0)
	global_rotation = aim_dir.angle()
	
	state_timer += delta
	var dur_mult: float = player.duration_mult if "duration_mult" in player else 1.0
	var cd_mult: float = player.cooldown_mult if "cooldown_mult" in player else 1.0
	var current_burst_time := base_burst_duration * dur_mult
	var current_cd_time := base_cooldown * cd_mult
	
	if is_breathing:
		tick_timer += delta
		puff_spawn_timer += delta
		
		# Ateş görsel pufu doğur
		if puff_spawn_timer >= 0.04:
			puff_spawn_timer = 0.0
			_spawn_flame_puff()
			
		# Düzenli hasar periyodu (0.16 sn)
		var tick_rate: float = 0.12 if current_level >= 7 else 0.16
		if tick_timer >= tick_rate:
			tick_timer = 0.0
			_deal_cone_damage(aim_dir)
			
		if state_timer >= current_burst_time:
			is_breathing = false
			state_timer = 0.0
	else:
		if state_timer >= current_cd_time:
			is_breathing = true
			state_timer = 0.0
			tick_timer = 0.0
			var audio = get_node_or_null("/root/AudioManager")
			if audio:
				audio.play_sfx("flame_burst", 0.14, 0.9)

func _spawn_flame_puff() -> void:
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var puff := Sprite2D.new()
	puff.texture = preload("res://assets/sprites/weapons/proj_flame_puff.png")
	
	var r_ang := randf_range(-deg_to_rad(cone_angle_deg * 0.5), deg_to_rad(cone_angle_deg * 0.5))
	var puff_dir := Vector2.RIGHT.rotated(global_rotation + r_ang)
	var speed := randf_range(280.0, 440.0)
	var final_dist := cone_range * area_scale
	
	puff.global_position = global_position + puff_dir * 38.0
	puff.scale = Vector2(0.12, 0.12) * area_scale
	
	# Renk paleti: 7. seviyede Mavi Ejder Alevi, normalde Kızıl/Turuncu
	if current_level >= 7:
		puff.modulate = Color(0.4, 0.9, 1.8, 0.9)
	else:
		var colors := [Color(1.6, 0.8, 0.2, 0.9), Color(1.8, 0.35, 0.15, 0.9), Color(1.2, 0.1, 0.1, 0.8)]
		puff.modulate = colors[randi() % colors.size()]
		
	var target_parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_parent.add_child(puff)
	
	var travel_time := final_dist / speed
	var tw := puff.create_tween()
	tw.parallel().tween_property(puff, "global_position", puff.global_position + puff_dir * final_dist, travel_time)
	tw.parallel().tween_property(puff, "scale", Vector2(0.38, 0.38) * area_scale, travel_time)
	tw.parallel().tween_property(puff, "modulate:a", 0.0, travel_time).set_ease(Tween.EASE_IN)
	tw.tween_callback(puff.queue_free)

func _deal_cone_damage(facing_dir: Vector2) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
		
	var area_scale: float = player.area_mult if "area_mult" in player else 1.0
	var final_range := cone_range * area_scale
	var max_cos := cos(deg_to_rad(cone_angle_deg * 0.5))
	var dmg_mult: float = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var crit_prob: float = player.crit_chance if "crit_chance" in player else 0.05
	var is_crit: bool = randf() < crit_prob
	var final_dmg: float = damage * dmg_mult * (2.0 if is_crit else 1.0)
	
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			if "is_dead" in e and e.is_dead:
				continue
			var to_e: Vector2 = e.global_position - global_position
			var dist: float = to_e.length()
			if dist <= final_range:
				var to_e_norm: Vector2 = to_e.normalized()
				var dot: float = facing_dir.dot(to_e_norm)
				if dot >= max_cos:
					if player and player.has_method("record_weapon_damage"):
						player.record_weapon_damage("weapon_dragon_breath", final_dmg)
					e.take_damage(final_dmg, is_crit, global_position, "weapon_dragon_breath")
					if e.has_method("apply_status"):
						e.apply_status("burn", 3.0, 10.0)
					if "knockback_velocity" in e:
						e.knockback_velocity += facing_dir * 45.0
