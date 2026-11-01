extends Node2D

@export var weapon_id: String = "weapon_potion"
@export var current_level: int = 1

@export var throw_rate: float = 1.4
@export var damage: float = 30.0
@export var puddle_duration: float = 2.5
@export var range_radius: float = 320.0
@export var puddle_radius: float = 55.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var timer: float = 0.0
var base_damage: float = 30.0
var base_throw_rate: float = 1.4
var base_puddle_radius: float = 55.0

func _ready() -> void:
	base_damage = damage
	base_throw_rate = throw_rate
	base_puddle_radius = puddle_radius
	if not player:
		player = get_tree().get_first_node_in_group("player")

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)
	throw_rate = maxf(0.35, base_throw_rate * (1.0 - (current_level - 1) * 0.11))
	puddle_radius = base_puddle_radius * (1.0 + (current_level - 1) * 0.16)
	if current_level >= 7:
		damage *= 1.35
		puddle_radius *= 1.30 # 7. seviyede devasa asit havuzu

func _process(delta: float) -> void:
	var cd_mult: float = 1.0
	if player and "cooldown_mult" in player:
		cd_mult = player.cooldown_mult
		
	timer += delta
	if timer >= (throw_rate * cd_mult):
		timer = 0.0
		_throw_potion()

func _throw_potion() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var extra_proj: int = player.extra_projectiles if player and "extra_projectiles" in player else 0
	var total_potions: int = 1 + extra_proj
	
	var valid_enemies: Array[Node2D] = []
	var center_pos := player.global_position if (player and is_instance_valid(player)) else global_position
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead) and center_pos.distance_to(e.global_position) <= range_radius:
			valid_enemies.append(e)
			
	valid_enemies.sort_custom(func(a, b):
		return center_pos.distance_to(a.global_position) < center_pos.distance_to(b.global_position)
	)
	
	for i in range(total_potions):
		var target_pos := Vector2.ZERO
		if i < valid_enemies.size():
			target_pos = valid_enemies[i].global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		elif valid_enemies.size() > 0:
			var ref_pos: Vector2 = valid_enemies.pick_random().global_position
			target_pos = ref_pos + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(30, 80)
		else:
			target_pos = global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(60, 160)
			
		_spawn_puddle(target_pos)

func _spawn_puddle(pos: Vector2) -> void:
	var dmg_mult: float = 1.0
	var area_scale: float = 1.0
	var crit_prob: float = 0.05
	var dur_mult: float = 1.0
	if player:
		if "damage_multiplier" in player:
			dmg_mult = player.damage_multiplier
		if "area_mult" in player:
			area_scale = player.area_mult
		if "crit_chance" in player:
			crit_prob = player.crit_chance
		if "duration_mult" in player:
			dur_mult = player.duration_mult
			
	var is_crit: bool = randf() < crit_prob
	var final_damage: float = damage * dmg_mult * (2.0 if is_crit else 1.0)
	var final_radius: float = puddle_radius * area_scale
	var final_duration: float = puddle_duration * dur_mult

	var puddle := Area2D.new()
	puddle.z_index = -1
	puddle.global_position = pos
	puddle.collision_layer = 0
	puddle.collision_mask = 1
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = final_radius
	col.shape = shape
	puddle.add_child(col)
	
	var spr := Sprite2D.new()
	spr.texture = preload("res://assets/sprites/weapons/proj_ink_splash.png")
	spr.scale = Vector2(0.2, 0.2) * area_scale
	spr.modulate = Color(1.2, 0.45, 1.4, 0.85) # Büyülü zehirli mor gölet
	puddle.add_child(spr)
	
	var target_parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_parent.add_child(puddle)
	
	var tween := puddle.create_tween()
	tween.tween_property(spr, "scale", Vector2(0.48, 0.48) * area_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(spr, "modulate:a", 0.0, maxf(0.5, final_duration - 0.2))
	tween.tween_callback(puddle.queue_free)
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("potion_splash", 0.12)
		
	# İlk darbe hasarı
	var initial_timer := get_tree().create_timer(0.05)
	initial_timer.timeout.connect(func():
		_puddle_tick(puddle, final_damage * 0.75, is_crit)
	)
	
	# Yerde kaldığı süre boyunca periyodik hasar (DoT)
	var tick_interval: float = 0.4
	var elapsed_ticks: float = 0.4
	while elapsed_ticks < final_duration:
		var t := get_tree().create_timer(elapsed_ticks)
		t.timeout.connect(func():
			if is_instance_valid(puddle):
				_puddle_tick(puddle, final_damage * 0.40, is_crit)
		)
		elapsed_ticks += tick_interval

func _puddle_tick(puddle: Area2D, tick_damage: float, is_crit: bool) -> void:
	if not is_instance_valid(puddle):
		return
	var bodies := puddle.get_overlapping_bodies()
	for b in bodies:
		if b and is_instance_valid(b) and b.has_method("take_damage"):
			if "is_dead" in b and b.is_dead:
				continue
			if player and player.has_method("record_weapon_damage"):
				player.record_weapon_damage("weapon_potion", tick_damage)
			b.take_damage(tick_damage, is_crit, puddle.global_position, "weapon_potion")
			if b.has_method("apply_status"):
				b.apply_status("poison", 4.0, 12.0)
			if is_crit and player and player.has_method("add_camera_shake"):
				player.add_camera_shake(1.2)
