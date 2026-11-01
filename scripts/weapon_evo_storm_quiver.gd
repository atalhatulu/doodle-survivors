extends Node2D

@export var weapon_id: String = "weapon_evo_storm_quiver"
@export var current_level: int = 1

@export var base_damage: float = 42.0
@export var fire_rate: float = 0.58
@export var arrows_count: int = 7
@export var range_radius: float = 550.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var sprite: Sprite2D = $Sprite2D

var damage: float = 42.0
var fire_timer: float = 0.0
var arrow_scene: PackedScene = preload("res://scenes/weapons/proj_storm_arrow.tscn")

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
	
	var cd_mult: float = player.cooldown_mult if "cooldown_mult" in player else 1.0
	fire_timer += delta
	if fire_timer >= fire_rate * cd_mult:
		fire_timer = 0.0
		_fire_storm_volley()

func _fire_storm_volley() -> void:
	if not arrow_scene:
		return
		
	var target_dir := Vector2.RIGHT
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest_dist := range_radius
	var found_target: Node2D = null
	
	for e in enemies:
		if not is_instance_valid(e) or ("is_dead" in e and e.is_dead):
			continue
		var d := global_position.distance_to(e.global_position)
		if d < closest_dist:
			closest_dist = d
			found_target = e
			
	if found_target:
		target_dir = (found_target.global_position - global_position).normalized()
	elif player is CharacterBody2D and player.velocity.length_squared() > 10.0:
		target_dir = player.velocity.normalized()
		
	if sprite:
		sprite.rotation = target_dir.angle()
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector2(0.4, 0.4), 0.1)
		tw.tween_property(sprite, "scale", Vector2(0.3, 0.3), 0.1)
		
	var base_angle := target_dir.angle()
	var spread_total := deg_to_rad(65.0)
	var step := spread_total / float(arrows_count - 1)
	var start_angle := base_angle - (spread_total * 0.5)
	
	var dmg_mult: float = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var crit_prob: float = player.crit_chance if "crit_chance" in player else 0.05
	var is_crit: bool = randf() < crit_prob
	var final_dmg: float = damage * dmg_mult * (2.2 if is_crit else 1.0)
	
	var target_scene: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	for i in range(arrows_count):
		var ang := start_angle + float(i) * step
		var dir := Vector2(cos(ang), sin(ang))
		var arrow = arrow_scene.instantiate()
		arrow.global_position = global_position + dir * 25.0
		arrow.direction = dir
		arrow.damage = final_dmg
		arrow.is_crit = is_crit
		target_scene.add_child(arrow)
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("spell_cast", 0.05, 1.8)
