extends Node2D

@export var weapon_id: String = "weapon_aura"
@export var current_level: int = 1

@export var base_damage: float = 18.0
@export var base_radius: float = 110.0
@export var tick_interval: float = 0.35

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var hitbox: Area2D = $Hitbox
@onready var collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var damage: float = 18.0
var radius: float = 110.0
var tick_timer: float = 0.0
var pulse_time: float = 0.0
var rotation_angle: float = 0.0

func _ready() -> void:
	z_index = -1 # Her zaman karakterin ve düşmanların altında, zemin katmanında çizilir
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
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)
	radius = base_radius * (1.0 + (current_level - 1) * 0.14)
	tick_interval = maxf(0.20, 0.35 - (current_level - 1) * 0.025)
	
	if current_level >= 7:
		damage *= 1.35
		radius *= 1.25 # 7. seviyede dev göksel ilahi mühür
		
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
	
	pulse_time += delta * 2.8
	rotation_angle += delta * 0.75
	queue_redraw()
		
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_deal_aura_damage()

func _draw() -> void:
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var current_rad: float = radius * area_scale
	var pulse: float = sin(pulse_time) * (current_rad * 0.025)
	var final_rad: float = current_rad + pulse
	
	var is_evolved: bool = current_level >= 7
	var base_color := Color(1.0, 0.86, 0.32, 0.75) # İlahi Parlak Altın
	var glow_color := Color(1.2, 1.0, 0.5, 0.40)
	var bg_tint := Color(1.0, 0.85, 0.3, 0.05)
	
	if is_evolved:
		base_color = Color(0.4, 0.95, 1.6, 0.85) # 7. seviyede Göksel İlahi Mavi
		glow_color = Color(0.7, 1.2, 2.0, 0.50)
		bg_tint = Color(0.3, 0.8, 1.4, 0.07)
		
	# 1. Zemin Hafif Işıma (Karakterin altı tamamen saydam kalır, çember alanı hafif aydınlanır)
	draw_circle(Vector2.ZERO, final_rad, bg_tint)
	
	# 2. Dış İlahi Çember (Ana Işıltılı Bariyer)
	draw_arc(Vector2.ZERO, final_rad, 0.0, TAU, 72, base_color, 2.8, true)
	draw_arc(Vector2.ZERO, final_rad + 2.0, 0.0, TAU, 64, glow_color, 1.2, true)
	
	# 3. İç Eşmerkezli Geometrik Çember (İnce Kutsal Çizgi)
	var inner_rad: float = final_rad * 0.82
	draw_arc(Vector2.ZERO, inner_rad, 0.0, TAU, 56, Color(base_color.r, base_color.g, base_color.b, 0.35), 1.4, true)
	
	# 4. Çevre Boyunca Dönen Kutsal Rün İmleri (Elmas rün sembolleri)
	var num_glyphs: int = 12 if is_evolved else 8
	var glyph_size: float = 4.5 if is_evolved else 3.5
	for i in range(num_glyphs):
		var ang: float = rotation_angle + float(i) * (TAU / float(num_glyphs))
		var pt := Vector2(cos(ang), sin(ang)) * final_rad
		
		# Dönen geometrik elmas sembolü
		var p1 := pt + Vector2(cos(ang), sin(ang)) * glyph_size
		var p2 := pt + Vector2(-sin(ang), cos(ang)) * (glyph_size * 0.7)
		var p3 := pt - Vector2(cos(ang), sin(ang)) * glyph_size
		var p4 := pt + Vector2(sin(ang), -cos(ang)) * (glyph_size * 0.7)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), base_color)
		
	# 5. Dış Yörüngede Dönen Işık Küreleri (Ateşböceği / İlahi Parçacık Hissi)
	var num_wisps: int = 6 if is_evolved else 4
	for w in range(num_wisps):
		var w_ang: float = -rotation_angle * 1.6 + float(w) * (TAU / float(num_wisps))
		var w_pos := Vector2(cos(w_ang), sin(w_ang)) * (inner_rad + (final_rad - inner_rad) * 0.5)
		draw_circle(w_pos, 3.0, Color(1.5, 1.3, 0.8, 0.95) if not is_evolved else Color(1.2, 1.8, 2.2, 0.95))
		draw_circle(w_pos, 5.5, glow_color)

func _deal_aura_damage() -> void:
	if not hitbox:
		return
	var bodies := hitbox.get_overlapping_bodies()
	if bodies.is_empty():
		return
		
	var dmg_mult: float = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var crit_prob: float = player.crit_chance if "crit_chance" in player else 0.05
	var regen_bonus: float = (player.hp_regen * 12.0) if ("hp_regen" in player and current_level >= 7) else 0.0
	
	var is_crit: bool = randf() < crit_prob
	var final_dmg: float = (damage + regen_bonus) * dmg_mult * (2.0 if is_crit else 1.0)
	
	for body in bodies:
		if body and is_instance_valid(body) and body.has_method("take_damage"):
			if "is_dead" in body and body.is_dead:
				continue
			var push_dir: Vector2 = (body.global_position - global_position).normalized()
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.UP
			body.take_damage(final_dmg, is_crit, global_position, "weapon_aura")
			if "knockback_velocity" in body:
				body.knockback_velocity += push_dir * 90.0
				
	var audio = get_node_or_null("/root/AudioManager")
	if audio and randf() < 0.25:
		audio.play_sfx("spell_cast", 0.08, 1.4)
