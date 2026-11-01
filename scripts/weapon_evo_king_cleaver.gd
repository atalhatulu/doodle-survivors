extends Node2D

@export var weapon_id: String = "weapon_evo_king_cleaver"
@export var current_level: int = 1

@export var base_damage: float = 95.0
@export var spin_cooldown: float = 0.55
@export var cleave_radius: float = 190.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var sword_sprite_1: Sprite2D = $Blade1
@onready var sword_sprite_2: Sprite2D = $Blade2

var damage: float = 95.0
var spin_timer: float = 0.0
var is_whirlwind: bool = false
var whirlwind_rot: float = 0.0
var slash_arc_anim: float = 0.0

func _ready() -> void:
	damage = base_damage
	if not player:
		player = get_tree().get_first_node_in_group("player")

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.4)
	cleave_radius = 190.0 * (1.0 + (current_level - 1) * 0.1)

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	global_position = player.global_position
	
	var cd_mult: float = player.cooldown_mult if "cooldown_mult" in player else 1.0
	spin_timer += delta
	
	if is_whirlwind:
		whirlwind_rot += delta * 24.0 # Çok hızlı fırıldak dönüşü
		slash_arc_anim = move_toward(slash_arc_anim, 1.0, delta * 3.5)
		if whirlwind_rot >= TAU * 2.0:
			is_whirlwind = false
			whirlwind_rot = 0.0
			slash_arc_anim = 0.0
	elif spin_timer >= spin_cooldown * cd_mult:
		spin_timer = 0.0
		_trigger_whirlwind()
		
	_update_blade_positions()
	queue_redraw()

func _update_blade_positions() -> void:
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var dist: float = 85.0 * area_scale
	var base_ang: float = whirlwind_rot if is_whirlwind else (spin_timer * 2.0)
	
	if sword_sprite_1:
		sword_sprite_1.position = Vector2(cos(base_ang), sin(base_ang)) * dist
		sword_sprite_1.rotation = base_ang + PI * 0.45
		sword_sprite_1.scale = Vector2(0.55, 0.55) * area_scale
	if sword_sprite_2:
		var ang2 := base_ang + PI
		sword_sprite_2.position = Vector2(cos(ang2), sin(ang2)) * dist
		sword_sprite_2.rotation = ang2 + PI * 0.45
		sword_sprite_2.scale = Vector2(0.55, 0.55) * area_scale

func _trigger_whirlwind() -> void:
	is_whirlwind = true
	whirlwind_rot = 0.0
	slash_arc_anim = 0.0
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.05, 1.8)
		
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
		
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var final_radius := cleave_radius * area_scale
	var dmg_mult: float = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var crit_prob: float = (player.crit_chance + 0.35) if "crit_chance" in player else 0.40
	var is_crit: bool = randf() < crit_prob
	var final_dmg: float = damage * dmg_mult * (2.5 if is_crit else 1.0)
	
	for e in enemies:
		if not is_instance_valid(e) or ("is_dead" in e and e.is_dead):
			continue
		var to_e: Vector2 = e.global_position - global_position
		if to_e.length() <= final_radius:
			if e.has_method("take_damage"):
				e.take_damage(final_dmg, is_crit, global_position, weapon_id)
				if e.has_method("apply_status"):
					e.apply_status("stun", 0.6)
				if "knockback_velocity" in e:
					e.knockback_velocity += to_e.normalized() * 260.0

func _draw() -> void:
	if not is_whirlwind:
		return
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var r := cleave_radius * area_scale
	# Çift beyaz-kızıl kesiş izi
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.5, 0.2, 0.2, 0.65), 5.0, true)
	draw_arc(Vector2.ZERO, r * 0.75, 0.0, TAU, 40, Color(1.8, 1.8, 1.8, 0.85), 3.0, true)
