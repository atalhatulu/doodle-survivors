extends Node2D

@export var move_speed: float = 175.0
@export var damage: float = 28.0
@export var max_lifetime: float = 25.0

@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D = null
var current_target: Node2D = null
var attack_cooldown: float = 0.0
var lifetime: float = 0.0
var walk_anim: float = 0.0
var base_scale: Vector2 = Vector2(0.35, 0.35)

@export var max_health: float = 35.0
var health: float = 35.0

func _init() -> void:
	add_to_group("allies")
	add_to_group("minions")

func _enter_tree() -> void:
	add_to_group("allies")
	add_to_group("minions")

func _ready() -> void:
	add_to_group("allies")
	add_to_group("minions")
	player = get_tree().get_first_node_in_group("player")
	if sprite:
		sprite.scale = base_scale
	# Giriş zıplama efekti
	scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		_fade_and_die()
		return
		
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		
	# Hedef kontrolü
	if not current_target or not is_instance_valid(current_target) or ("is_dead" in current_target and current_target.is_dead):
		current_target = _find_nearest_enemy()
		
	var dest := player.global_position
	var is_hunting := false
	if current_target and is_instance_valid(current_target):
		dest = current_target.global_position
		is_hunting = true
	else:
		# Oyuncunun yakınında gezin
		if global_position.distance_to(player.global_position) < 80.0:
			dest = global_position
			
	var to_dest: Vector2 = dest - global_position
	var dist: float = to_dest.length()
	
	if dist > 26.0:
		var dir := to_dest.normalized()
		global_position += dir * move_speed * delta
		walk_anim += delta * 14.0
		if sprite:
			sprite.rotation = sin(walk_anim) * 0.15
			sprite.scale.x = base_scale.x * (1.0 + sin(walk_anim) * 0.1)
			sprite.scale.y = base_scale.y * (1.0 - sin(walk_anim) * 0.1)
			if dir.x != 0.0:
				sprite.flip_h = dir.x < 0.0
	else:
		# Saldırı mesafesinde
		if is_hunting and current_target and attack_cooldown <= 0.0:
			_attack(current_target)

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_d: float = 420.0
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			var d := global_position.distance_to(e.global_position)
			if d < min_d:
				min_d = d
				nearest = e
	return nearest

func _attack(target: Node2D) -> void:
	attack_cooldown = 0.45
	var mult: float = player.damage_multiplier if (player and "damage_multiplier" in player) else 1.0
	var is_crit: bool = (randf() < (player.crit_chance if player and "crit_chance" in player else 0.05))
	var final_dmg: float = damage * mult * (2.0 if is_crit else 1.0)
	
	if player and player.has_method("record_weapon_damage"):
		player.record_weapon_damage("char_necromancer", final_dmg)
		
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(final_dmg, is_crit, global_position)
		if "knockback_velocity" in target:
			var push_dir: Vector2 = (target.global_position - global_position).normalized()
			target.knockback_velocity += push_dir * 120.0
			
	# Kemik savurma animasyonu
	if sprite:
		var tw := create_tween()
		tw.tween_property(sprite, "rotation", 0.4 if not sprite.flip_h else -0.4, 0.1)
		tw.tween_property(sprite, "rotation", 0.0, 0.1)

func _fade_and_die() -> void:
	set_physics_process(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)

func take_damage(amount: float, _is_crit: bool = false, _source_pos: Vector2 = Vector2.ZERO, _source_weapon_id: String = "") -> void:
	health -= amount
	if health <= 0.0:
		_fade_and_die()
