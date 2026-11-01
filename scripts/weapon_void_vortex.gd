extends Node2D

@export var weapon_id: String = "weapon_void_vortex"
@export var current_level: int = 1

@export var base_damage: float = 16.0
@export var base_duration: float = 3.0
@export var base_cooldown: float = 3.8
@export var vortex_radius: float = 140.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var timer: float = 0.0
var damage: float = 16.0

func _ready() -> void:
	damage = base_damage
	if not player:
		player = get_tree().get_first_node_in_group("player")

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)
	vortex_radius = 140.0 * (1.0 + (current_level - 1) * 0.12)
	base_duration = 3.0 * (1.0 + (current_level - 1) * 0.08)
	base_cooldown = maxf(1.8, 3.8 * (1.0 - (current_level - 1) * 0.08))
	if current_level >= 7:
		damage *= 1.45
		vortex_radius *= 1.25

func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var cd_mult: float = player.cooldown_mult if "cooldown_mult" in player else 1.0
	timer += delta
	if timer >= (base_cooldown * cd_mult):
		timer = 0.0
		_spawn_vortices()

func _spawn_vortices() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var extra_proj: int = player.extra_projectiles if "extra_projectiles" in player else 0
	var count: int = 1 + int(extra_proj * 0.5) # 1-2 girdap
	
	var candidates: Array[Node2D] = []
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= 450.0:
			if not ("is_dead" in e and e.is_dead):
				candidates.append(e)
				
	for i in range(count):
		var target_pos := Vector2.ZERO
		if candidates.size() > i:
			target_pos = candidates[i].global_position
		elif candidates.size() > 0:
			target_pos = candidates.pick_random().global_position + Vector2.RIGHT.rotated(randf() * TAU) * 60.0
		else:
			target_pos = global_position + Vector2.RIGHT.rotated(randf() * TAU) * 120.0
			
		_create_vortex_node(target_pos)

const VORTEX_SCENE = preload("res://scenes/weapons/proj_void_vortex.tscn")

func _create_vortex_node(pos: Vector2) -> void:
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var dur_mult: float = player.duration_mult if player and "duration_mult" in player else 1.0
	var dmg_mult: float = player.damage_multiplier if player and "damage_multiplier" in player else 1.0
	var crit_prob: float = player.crit_chance if player and "crit_chance" in player else 0.05
	var is_crit: bool = randf() < crit_prob
	
	var final_radius := vortex_radius * area_scale
	var final_duration := base_duration * dur_mult
	var tick_damage := damage * dmg_mult * (2.0 if is_crit else 1.0)
	
	var vortex_inst = VORTEX_SCENE.instantiate()
	vortex_inst.initialize(pos, final_radius, final_duration, tick_damage, is_crit)
	
	var target_parent: Node = get_tree().current_scene if (get_tree() and get_tree().current_scene) else (get_tree().root if get_tree() else null)
	if target_parent:
		target_parent.add_child(vortex_inst)
