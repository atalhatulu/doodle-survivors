extends Node2D

@export var weapon_id: String = "weapon_spellbook"
@export var current_level: int = 1

@export var damage: float = 24.0
@export var orbit_speed: float = 3.5
@export var orbit_radius: float = 120.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var hitbox: Area2D = $Hitbox
@onready var sprite: Sprite2D = $Sprite2D

var angle: float = 0.0
var damage_cooldowns: Dictionary = {}
var base_damage: float = 24.0
var base_orbit_speed: float = 3.5
var base_orbit_radius: float = 120.0

func _ready() -> void:
	base_damage = damage
	base_orbit_speed = orbit_speed
	base_orbit_radius = orbit_radius
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if hitbox:
		hitbox.collision_layer = 0
		hitbox.collision_mask = 1
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)
	orbit_speed = base_orbit_speed * (1.0 + (current_level - 1) * 0.15)
	orbit_radius = base_orbit_radius * (1.0 + (current_level - 1) * 0.08)
	if current_level >= 7:
		damage *= 1.40
		orbit_speed *= 1.30 # 7. seviyede süpersonik girdap
	
	if sprite:
		var tw := create_tween()
		tw.tween_property(sprite, "scale", sprite.scale * 1.35, 0.15)
		tw.tween_property(sprite, "scale", sprite.scale, 0.15)

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var area_scale: float = 1.0
	if player and "area_mult" in player:
		area_scale = player.area_mult
		
	angle += orbit_speed * delta
	var current_radius := orbit_radius * area_scale
	var offset := Vector2(cos(angle), sin(angle)) * current_radius
	global_position = player.global_position + Vector2(0, -30) + offset
	
	if sprite:
		sprite.rotation = angle + PI * 0.5
		
	# Hasar bekleme süresini azalt
	for id in damage_cooldowns.keys():
		damage_cooldowns[id] -= delta
		if damage_cooldowns[id] <= 0:
			damage_cooldowns.erase(id)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body and body.has_method("take_damage"):
		var id := body.get_instance_id()
		if not damage_cooldowns.has(id):
			var dmg_mult: float = 1.0
			var crit_prob: float = 0.05
			if player:
				if "damage_multiplier" in player:
					dmg_mult = player.damage_multiplier
				if "crit_chance" in player:
					crit_prob = player.crit_chance
			var is_crit: bool = randf() < crit_prob
			var final_dmg: float = damage * dmg_mult * (2.0 if is_crit else 1.0)
			
			damage_cooldowns[id] = 0.40
			body.take_damage(final_dmg, is_crit)
