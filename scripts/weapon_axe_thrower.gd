extends Node2D

@export var weapon_id: String = "weapon_axe"
@export var current_level: int = 1

@export var fire_rate: float = 1.6
@export var damage: float = 50.0
@export var axes_count: int = 1
@export var axe_proj_scene: PackedScene = preload("res://scenes/weapons/proj_axe.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var timer: float = 0.0
var base_damage: float = 50.0
var base_fire_rate: float = 1.6

func _ready() -> void:
	base_damage = damage
	base_fire_rate = fire_rate
	if not player:
		player = get_tree().get_first_node_in_group("player")

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.40)
	fire_rate = maxf(0.5, base_fire_rate * (1.0 - (current_level - 1) * 0.11))
	
	if current_level >= 7:
		damage *= 1.30 # 7. seviye zirve bonusu
		
	if sprite:
		var tw := create_tween()
		tw.tween_property(sprite, "scale", sprite.scale * 1.35, 0.15)
		tw.tween_property(sprite, "scale", sprite.scale, 0.15)

func _process(delta: float) -> void:
	var cd_mult: float = 1.0
	if player and "cooldown_mult" in player:
		cd_mult = player.cooldown_mult
		
	timer += delta
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		
	# Boşta hafif tatlı bir salınım
	if sprite:
		sprite.rotation = sin(timer * 4.0) * 0.15
		
	if timer >= (fire_rate * cd_mult):
		timer = 0.0
		_throw_axe()

func _throw_axe() -> void:
	if not axe_proj_scene:
		return
		
	var dmg_mult: float = 1.0
	var area_scale: float = 1.0
	var crit_prob: float = 0.05
	var extra_proj: int = 0
	var speed_mult: float = 1.0
	if player:
		if "damage_multiplier" in player:
			dmg_mult = player.damage_multiplier
		if "area_mult" in player:
			area_scale = player.area_mult
		if "crit_chance" in player:
			crit_prob = player.crit_chance
		if "extra_projectiles" in player:
			extra_proj = player.extra_projectiles
		if "projectile_speed_mult" in player:
			speed_mult = player.projectile_speed_mult
			
	var is_crit: bool = randf() < crit_prob
	var final_damage: float = damage * dmg_mult * (2.0 if is_crit else 1.0)
	
	# En yakın düşmanı hedefle veya hareket yönüne fırlat
	var target_dir: Vector2 = _get_target_direction()
	
	# Birden fazla balta varsa koni şeklinde (fan spread) dağıt
	var spread_angle_deg: float = 18.0
	var count: int = maxi(1, axes_count + extra_proj)
	var start_offset: float = - (float(count - 1) * 0.5) * spread_angle_deg
	
	for i in range(count):
		var angle_offset: float = deg_to_rad(start_offset + float(i) * spread_angle_deg)
		var fire_dir: Vector2 = target_dir.rotated(angle_offset)
		
		var axe = axe_proj_scene.instantiate()
		axe.damage = final_damage
		if "is_crit" in axe:
			axe.is_crit = is_crit
		if "scale" in axe:
			axe.scale = axe.scale * area_scale
			
		var target_node: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
		target_node.add_child(axe)
		axe.global_position = global_position
		axe.launch(fire_dir, 460.0 * speed_mult)
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("axe_throw", 0.12)
	
	# Silahın kendisinde savurma tepkisi
	if sprite:
		var tw := create_tween()
		sprite.scale = Vector2(0.24, 0.24)
		tw.tween_property(sprite, "scale", Vector2(0.32, 0.32), 0.15)

func _get_target_direction() -> Vector2:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest_dist: float = 650.0
	var closest_enemy: Node2D = null
	var center_pos := player.global_position if (player and is_instance_valid(player)) else global_position
	
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy):
			if "is_dead" in enemy and enemy.is_dead:
				continue
			var dist: float = center_pos.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = enemy
				
	if closest_enemy:
		return (closest_enemy.global_position - center_pos).normalized()
		
	# Yakında düşman yoksa oyuncunun hareket ettiği yöne at
	if player and "velocity" in player and player.velocity.length_squared() > 10.0:
		return player.velocity.normalized()
		
	return Vector2.RIGHT

