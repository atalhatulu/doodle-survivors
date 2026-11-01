extends Node2D

@export var weapon_id: String = "weapon_lightning"
@export var current_level: int = 1

@export var base_damage: float = 45.0
@export var base_cooldown: float = 1.8
@export var strike_radius: float = 45.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var timer: float = 0.0
var damage: float = 45.0
var cooldown: float = 1.8
var base_strikes: int = 1

func _ready() -> void:
	damage = base_damage
	cooldown = base_cooldown
	if not player:
		player = get_tree().get_first_node_in_group("player")

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)
	cooldown = maxf(0.6, base_cooldown * (1.0 - (current_level - 1) * 0.09))
	if current_level >= 3:
		base_strikes = 2
	if current_level >= 5:
		base_strikes = 3
	if current_level >= 7:
		base_strikes = 5
		damage *= 1.4

func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var cd_mult: float = player.cooldown_mult if "cooldown_mult" in player else 1.0
	timer += delta
	if timer >= (cooldown * cd_mult):
		timer = 0.0
		_cast_lightning()

func _cast_lightning() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
		
	var extra_proj: int = player.extra_projectiles if "extra_projectiles" in player else 0
	var total_strikes: int = base_strikes + extra_proj
	
	# Ekrana yakın düşmanları filtrele (~700px)
	var candidates: Array[Node2D] = []
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= 750.0:
			if not ("is_dead" in e and e.is_dead):
				candidates.append(e)
				
	if candidates.is_empty():
		return
		
	candidates.shuffle()
	var strike_count := mini(total_strikes, candidates.size())
	
	for i in range(strike_count):
		var target := candidates[i]
		if is_instance_valid(target):
			_strike_enemy(target.global_position, i * 0.08)

func _strike_enemy(pos: Vector2, delay: float) -> void:
	var tw := get_tree().create_timer(delay)
	tw.timeout.connect(func():
		_execute_strike(pos)
	)

func _execute_strike(pos: Vector2) -> void:
	var dmg_mult: float = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var crit_prob: float = player.crit_chance if "crit_chance" in player else 0.05
	var area_scale: float = player.area_mult if "area_mult" in player else 1.0
	var is_crit: bool = randf() < crit_prob
	var final_dmg: float = damage * dmg_mult * (2.0 if is_crit else 1.0)
	var final_radius: float = strike_radius * area_scale
	
	# 1. Prosedürel Şimşek Çizgisi (Line2D)
	var line := Line2D.new()
	line.width = 7.0 * area_scale
	line.default_color = Color(1.3, 1.4, 1.8, 1.0)
	var start_pt := pos + Vector2(randf_range(-60, 60), -550)
	var segments := 6
	var pts: Array[Vector2] = [start_pt]
	for s in range(1, segments):
		var ratio := float(s) / float(segments)
		var mid := start_pt.lerp(pos, ratio) + Vector2(randf_range(-25, 25), randf_range(-10, 10))
		pts.append(mid)
	pts.append(pos)
	line.points = PackedVector2Array(pts)
	
	# 2. Yere Şok Dalgası Görseli (Sprite2D)
	var shock := Sprite2D.new()
	shock.texture = preload("res://assets/sprites/weapons/proj_orb.png")
	shock.global_position = pos
	shock.scale = Vector2(0.2, 0.2) * area_scale
	shock.modulate = Color(1.4, 1.4, 2.0, 0.9)
	
	var target_parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_parent.add_child(line)
	target_parent.add_child(shock)
	
	# Görsel kaybolma
	var l_tween := line.create_tween()
	l_tween.tween_property(line, "modulate:a", 0.0, 0.16)
	l_tween.tween_callback(line.queue_free)
	
	var s_tween := shock.create_tween()
	s_tween.tween_property(shock, "scale", Vector2(0.7, 0.7) * area_scale, 0.22)
	s_tween.parallel().tween_property(shock, "modulate:a", 0.0, 0.22)
	s_tween.tween_callback(shock.queue_free)
	
	# Hasar Uygulama
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			if pos.distance_to(e.global_position) <= final_radius:
				if "is_dead" in e and e.is_dead:
					continue
				if player and player.has_method("record_weapon_damage"):
					player.record_weapon_damage("weapon_lightning", final_dmg)
				e.take_damage(final_dmg, is_crit, pos, "weapon_lightning")
				if e.has_method("apply_status"):
					e.apply_status("shock", 3.0)
					
	var vortices := get_tree().get_nodes_in_group("void_vortices")
	for v in vortices:
		if is_instance_valid(v) and pos.distance_to(v.global_position) <= final_radius + 60.0:
			if v.has_method("trigger_superconduct"):
				v.trigger_superconduct(player)
				break
				
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("spell_cast", 0.15, 0.8)
		
	if player and player.has_method("add_camera_shake"):
		player.add_camera_shake(2.0 if is_crit else 1.2)
