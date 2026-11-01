extends Node2D

@export var weapon_id: String = "weapon_evo_divine_sun"
@export var current_level: int = 1

@export var base_damage: float = 48.0
@export var base_radius: float = 230.0
@export var tick_interval: float = 0.22

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var hitbox: Area2D = $Hitbox
@onready var collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var damage: float = 48.0
var radius: float = 230.0
var tick_timer: float = 0.0
var pulse_time: float = 0.0
var rotation_angle: float = 0.0
var heal_tick_counter: int = 0

func _ready() -> void:
	z_index = -1
	damage = base_damage
	radius = base_radius
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if hitbox:
		hitbox.collision_layer = 0
		hitbox.collision_mask = 1
	_update_dimensions()

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.4)
	radius = base_radius * (1.0 + (current_level - 1) * 0.1)
	_update_dimensions()

func _update_dimensions() -> void:
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var final_radius: float = radius * area_scale
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = final_radius
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	global_position = player.global_position
	pulse_time += delta * 4.2
	rotation_angle += delta * 1.2
	queue_redraw()
	
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_deal_sun_damage()

func _draw() -> void:
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var current_rad: float = radius * area_scale
	var pulse: float = sin(pulse_time) * (current_rad * 0.04)
	var final_rad: float = current_rad + pulse
	
	# Güneş aurası - Altın ve kor alevi tonları
	var sun_gold := Color(1.3, 0.95, 0.35, 0.85)
	var solar_glow := Color(1.5, 0.65, 0.2, 0.45)
	var corona_tint := Color(1.0, 0.4, 0.1, 0.12)
	
	# 1. Kor Zemin Alanı
	draw_circle(Vector2.ZERO, final_rad, corona_tint)
	
	# 2. Dış Parlayan Güneş Çemberi
	draw_arc(Vector2.ZERO, final_rad, 0.0, TAU, 72, sun_gold, 3.5, true)
	draw_arc(Vector2.ZERO, final_rad + 3.0, 0.0, TAU, 64, solar_glow, 2.0, true)
	
	# 3. İç Eşmerkezli Kutsal Hat
	var inner_rad: float = final_rad * 0.75
	draw_arc(Vector2.ZERO, inner_rad, 0.0, TAU, 56, Color(1.2, 0.8, 0.2, 0.5), 2.0, true)
	
	# 4. Dönen 16 Güneş Işını (Solar Flares)
	var ray_count := 16
	for i in range(ray_count):
		var ang := rotation_angle + float(i) * (TAU / float(ray_count))
		var r_start := Vector2(cos(ang), sin(ang)) * (inner_rad * 0.9)
		var r_end := Vector2(cos(ang), sin(ang)) * (final_rad + 12.0 + sin(pulse_time + float(i)) * 6.0)
		draw_line(r_start, r_end, solar_glow, 2.5, true)
		
	# 5. Yörüngede Dönen 6 Kutsal Ateş Küresi
	var orb_count := 6
	for o in range(orb_count):
		var o_ang := -rotation_angle * 1.8 + float(o) * (TAU / float(orb_count))
		var o_pos := Vector2(cos(o_ang), sin(o_ang)) * (final_rad * 0.88)
		draw_circle(o_pos, 5.0, Color(1.6, 1.4, 0.8, 0.95))
		draw_circle(o_pos, 8.0, solar_glow)

func _deal_sun_damage() -> void:
	if not hitbox:
		return
	var bodies := hitbox.get_overlapping_bodies()
	if bodies.is_empty():
		return
		
	var dmg_mult: float = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var crit_prob: float = player.crit_chance if "crit_chance" in player else 0.05
	var is_crit: bool = randf() < crit_prob
	var final_dmg: float = damage * dmg_mult * (2.2 if is_crit else 1.0)
	
	for body in bodies:
		if body and is_instance_valid(body) and body.has_method("take_damage"):
			if "is_dead" in body and body.is_dead:
				continue
			var push_dir: Vector2 = (body.global_position - global_position).normalized()
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.UP
			body.take_damage(final_dmg, is_crit, global_position, weapon_id)
			if body.has_method("apply_status"):
				body.apply_status("burn", 3.0, 18.0)
			if "knockback_velocity" in body:
				body.knockback_velocity += push_dir * 120.0
				
	# Her 3 vuruşta oyuncuya +1 HP İlahi Şifa
	heal_tick_counter += 1
	if heal_tick_counter >= 3:
		heal_tick_counter = 0
		if player and "current_health" in player and "max_health" in player:
			player.current_health = minf(player.max_health, player.current_health + 1.0)
			if player.has_method("_update_hp_bar"):
				player._update_hp_bar()
				
	var audio = get_node_or_null("/root/AudioManager")
	if audio and randf() < 0.25:
		audio.play_sfx("spell_cast", 0.05, 1.6)
