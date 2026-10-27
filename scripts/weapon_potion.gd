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
	var target_pos := global_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * 140.0
	
	if enemies.size() > 0:
		var nearest: Node2D = null
		var nearest_dist := range_radius
		for e in enemies:
			if is_instance_valid(e):
				var d := global_position.distance_to(e.global_position)
				if d < nearest_dist:
					nearest_dist = d
					nearest = e
		if nearest:
			target_pos = nearest.global_position
			
	_spawn_puddle(target_pos)

func _spawn_puddle(pos: Vector2) -> void:
	var dmg_mult: float = 1.0
	var area_scale: float = 1.0
	var crit_prob: float = 0.05
	if player:
		if "damage_multiplier" in player:
			dmg_mult = player.damage_multiplier
		if "area_mult" in player:
			area_scale = player.area_mult
		if "crit_chance" in player:
			crit_prob = player.crit_chance
			
	var is_crit: bool = randf() < crit_prob
	var final_damage: float = damage * dmg_mult * (2.0 if is_crit else 1.0)
	var final_radius: float = puddle_radius * area_scale

	var puddle := Area2D.new()
	puddle.global_position = pos
	puddle.collision_layer = 0
	puddle.collision_mask = 1
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = final_radius
	col.shape = shape
	puddle.add_child(col)
	
	var spr := Sprite2D.new()
	spr.texture = preload("res://assets/sprites/weapons/weapon_potion.png")
	spr.scale = Vector2(0.25, 0.25) * area_scale
	puddle.add_child(spr)
	
	get_tree().current_scene.add_child(puddle)
	
	# Alan hasarı periyodik
	var tween := puddle.create_tween()
	spr.modulate = Color(1.5, 0.6, 2.0, 0.9)
	tween.tween_property(spr, "scale", Vector2(0.4, 0.4) * area_scale, 0.25)
	tween.tween_property(spr, "modulate:a", 0.0, puddle_duration)
	tween.tween_callback(puddle.queue_free)
	
	# Kısa bir gecikmeyle patlama hasarı uygula
	var p_timer := get_tree().create_timer(0.05)
	p_timer.timeout.connect(func():
		if is_instance_valid(puddle):
			var bodies := puddle.get_overlapping_bodies()
			for b in bodies:
				if b and b.has_method("take_damage"):
					b.take_damage(final_damage, is_crit)
					var p := get_tree().get_first_node_in_group("player")
					if p and p.has_method("add_camera_shake"):
						p.add_camera_shake(2.0 if is_crit else 1.0)
	)
