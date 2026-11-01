extends Node2D

@export var weapon_id: String = "weapon_evo_hellfire_storm"
@export var current_level: int = 1

@export var base_damage: float = 38.0
@export var flame_range: float = 210.0
@export var rotation_speed: float = 3.6

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var damage: float = 38.0
var spin_angle: float = 0.0
var tick_timer: float = 0.0
var magma_timer: float = 0.0
var magma_pool_scene: PackedScene = preload("res://scenes/weapons/magma_pool.tscn")

func _ready() -> void:
	damage = base_damage
	if not player:
		player = get_tree().get_first_node_in_group("player")

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)
	flame_range = 210.0 * (1.0 + (current_level - 1) * 0.12)

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	global_position = player.global_position
	spin_angle += rotation_speed * delta
	queue_redraw()
	
	tick_timer += delta
	if tick_timer >= 0.14:
		tick_timer = 0.0
		_deal_cyclone_damage()
		
	magma_timer += delta
	if magma_timer >= 0.32:
		magma_timer = 0.0
		_spawn_magma_pool()

func _draw() -> void:
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var cur_range: float = flame_range * area_scale
	
	# 4 Dönen Alev Kolu (360 Derece Cehennem Kasırgası)
	for i in range(4):
		var arm_ang: float = spin_angle + float(i) * (PI * 0.5)
		var dir := Vector2(cos(arm_ang), sin(arm_ang))
		var norm := Vector2(-dir.y, dir.x)
		
		# Alev dili konisi
		var tip := dir * cur_range
		var side1 := dir * (cur_range * 0.6) + norm * 26.0
		var side2 := dir * (cur_range * 0.6) - norm * 26.0
		
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, side1, tip, side2]), Color(1.4, 0.45, 0.1, 0.45))
		
		# İç kor çekirdeği
		var inner_tip := dir * (cur_range * 0.8)
		var in_side1 := dir * (cur_range * 0.4) + norm * 14.0
		var in_side2 := dir * (cur_range * 0.4) - norm * 14.0
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, in_side1, inner_tip, in_side2]), Color(1.8, 1.2, 0.3, 0.75))

func _deal_cyclone_damage() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
		
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var cur_range: float = flame_range * area_scale
	var dmg_mult: float = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var crit_prob: float = player.crit_chance if "crit_chance" in player else 0.05
	var is_crit: bool = randf() < crit_prob
	var final_dmg: float = damage * dmg_mult * (2.0 if is_crit else 1.0)
	
	for e in enemies:
		if not is_instance_valid(e) or ("is_dead" in e and e.is_dead):
			continue
		var to_e: Vector2 = e.global_position - global_position
		var dist: float = to_e.length()
		if dist > cur_range:
			continue
			
		var angle_to_e: float = to_e.angle()
		# 4 koldan herhangi birine yakın mı kontrol et (açı farkı <= 28 derece)
		var in_flame := false
		for i in range(4):
			var arm_ang: float = spin_angle + float(i) * (PI * 0.5)
			var diff := absf(wrapf(angle_to_e - arm_ang, -PI, PI))
			if diff <= deg_to_rad(30.0):
				in_flame = true
				break
				
		if in_flame and e.has_method("take_damage"):
			e.take_damage(final_dmg, is_crit, global_position, weapon_id)
			if e.has_method("apply_status"):
				e.apply_status("burn", 3.0, 22.0)
			if "knockback_velocity" in e:
				e.knockback_velocity += to_e.normalized() * 75.0

func _spawn_magma_pool() -> void:
	if not magma_pool_scene:
		return
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var cur_range: float = flame_range * area_scale
	var pool = magma_pool_scene.instantiate()
	var arm_index := randi() % 4
	var arm_ang: float = spin_angle + float(arm_index) * (PI * 0.5) + randf_range(-0.3, 0.3)
	var spawn_dist := randf_range(cur_range * 0.35, cur_range * 0.85)
	pool.global_position = global_position + Vector2(cos(arm_ang), sin(arm_ang)) * spawn_dist
	
	var target_scene: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_scene.add_child(pool)
