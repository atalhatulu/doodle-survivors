extends Node2D

@export var weapon_id: String = "weapon_evo_cosmic_archon"
@export var current_level: int = 1

@export var base_damage: float = 52.0
@export var fire_interval: float = 0.28
@export var beam_range: float = 480.0
@export var orb_orbit_radius: float = 85.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var damage: float = 52.0
var orbit_angle: float = 0.0
var fire_timer: float = 0.0
var active_beams: Array[Dictionary] = [] # [{start, end, alpha, width}]

func _ready() -> void:
	damage = base_damage
	if not player:
		player = get_tree().get_first_node_in_group("player")

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	global_position = player.global_position
	orbit_angle += delta * 2.8
	
	# Aktif lazer çizgilerini söndür
	for i in range(active_beams.size() - 1, -1, -1):
		active_beams[i]["alpha"] -= delta * 7.0
		if active_beams[i]["alpha"] <= 0.0:
			active_beams.remove_at(i)
			
	queue_redraw()
	
	var cd_mult: float = player.cooldown_mult if "cooldown_mult" in player else 1.0
	fire_timer += delta
	if fire_timer >= fire_interval * cd_mult:
		fire_timer = 0.0
		_fire_cosmic_beams()

func _fire_cosmic_beams() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
		
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var cur_orbit: float = orb_orbit_radius * area_scale
	var cur_range: float = beam_range * area_scale
	
	var dmg_mult: float = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var crit_prob: float = player.crit_chance if "crit_chance" in player else 0.05
	var is_crit: bool = randf() < crit_prob
	var final_dmg: float = damage * dmg_mult * (2.2 if is_crit else 1.0)
	
	# 3 Kürenin her biri bağımsız bir hedefe lazer sıkar
	var valid_enemies: Array[Node2D] = []
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			if global_position.distance_to(e.global_position) <= cur_range:
				valid_enemies.append(e)
				
	if valid_enemies.is_empty():
		return
		
	valid_enemies.shuffle()
	
	for o in range(3):
		if o >= valid_enemies.size():
			break
		var o_ang := orbit_angle + float(o) * (TAU / 3.0)
		var orb_world_pos := global_position + Vector2(cos(o_ang), sin(o_ang)) * cur_orbit
		var target: Node2D = valid_enemies[o]
		var target_pos := target.global_position
		
		# Lazeri yerel koordinata çevirerek çizim listesine ekle
		active_beams.append({
			"start": orb_world_pos - global_position,
			"end": target_pos - global_position,
			"alpha": 1.0,
			"is_crit": is_crit
		})
		
		# Hedefe ve çizgi boyunca geçen düşmanlara hasar ver
		var beam_dir := (target_pos - orb_world_pos).normalized()
		var beam_len := orb_world_pos.distance_to(target_pos)
		
		for e in valid_enemies:
			var to_e: Vector2 = e.global_position - orb_world_pos
			var proj_dist: float = to_e.dot(beam_dir)
			if proj_dist > 0.0 and proj_dist <= beam_len + 40.0:
				var perp_dist := (to_e - beam_dir * proj_dist).length()
				if perp_dist <= 35.0 * area_scale:
					e.take_damage(final_dmg, is_crit, orb_world_pos, weapon_id)
					if "knockback_velocity" in e:
						e.knockback_velocity += beam_dir * 80.0
						
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("laser", 0.05, 2.0)

func _draw() -> void:
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var cur_orbit: float = orb_orbit_radius * area_scale
	
	# 1. 3 Kozmik Süpernova Küresi
	for o in range(3):
		var o_ang := orbit_angle + float(o) * (TAU / 3.0)
		var orb_pos := Vector2(cos(o_ang), sin(o_ang)) * cur_orbit
		
		draw_circle(orb_pos, 7.0, Color(1.8, 1.2, 2.5, 0.95))
		draw_circle(orb_pos, 13.0, Color(0.8, 0.4, 1.8, 0.4))
		
	# 2. Aktif Lazer Işınları
	for beam in active_beams:
		var alpha: float = beam["alpha"]
		var beam_col := Color(1.6, 1.8, 2.5, alpha) if not beam["is_crit"] else Color(2.5, 1.2, 0.5, alpha)
		var glow_col := Color(0.6, 0.3, 1.8, alpha * 0.45)
		
		draw_line(beam["start"], beam["end"], glow_col, 8.0, true)
		draw_line(beam["start"], beam["end"], beam_col, 3.0, true)
		draw_circle(beam["end"], 8.0 * alpha, beam_col)
