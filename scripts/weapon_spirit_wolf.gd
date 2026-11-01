extends Node2D

@export var weapon_id: String = "weapon_spirit_wolf"
@export var current_level: int = 1

@export var base_damage: float = 35.0
@export var base_wolf_speed: float = 280.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var damage: float = 35.0
var active_wolves: Array[Node2D] = []

func _ready() -> void:
	damage = base_damage
	if not player:
		player = get_tree().get_first_node_in_group("player")

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)
	base_wolf_speed = 280.0 * (1.0 + (current_level - 1) * 0.10)
	if current_level >= 7:
		damage *= 1.45
		base_wolf_speed *= 1.25

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var extra_proj: int = player.extra_projectiles if "extra_projectiles" in player else 0
	var desired_wolves: int = 1 + extra_proj
	
	_sync_wolves(desired_wolves)
	
	var spd_mult: float = player.projectile_speed_mult if "projectile_speed_mult" in player else 1.0
	var current_speed := base_wolf_speed * spd_mult
	
	for wolf in active_wolves:
		if is_instance_valid(wolf):
			_update_wolf_ai(wolf, current_speed, delta)

func _sync_wolves(desired: int) -> void:
	active_wolves = active_wolves.filter(func(w): return is_instance_valid(w))
	while active_wolves.size() < desired:
		var wolf := _spawn_wolf_node()
		active_wolves.append(wolf)
	while active_wolves.size() > desired and active_wolves.size() > 1:
		var last: Node2D = active_wolves.pop_back()
		if is_instance_valid(last):
			last.queue_free()

func _spawn_wolf_node() -> Node2D:
	var wolf := Node2D.new()
	wolf.name = "SpiritWolf"
	wolf.global_position = player.global_position + Vector2(randf_range(-70, 70), randf_range(-70, 70))
	
	var spr := Sprite2D.new()
	# Şık ruhani kurt silueti ve die-cut çıkartması
	spr.texture = preload("res://assets/sprites/weapons/spirit_wolf.png")
	spr.scale = Vector2(0.42, 0.42)
	spr.modulate = Color(0.7, 1.3, 2.2, 0.95) # Ethereal Parlak Mavi
	wolf.add_child(spr)
	
	# Kurt değişkenleri
	wolf.set_meta("bite_cooldown", 0.0)
	wolf.set_meta("howl_timer", randf_range(4.0, 8.0))
	wolf.set_meta("walk_anim", 0.0)
	wolf.set_meta("current_target", null)
	
	var target_parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_parent.add_child(wolf)
	return wolf

func _update_wolf_ai(wolf: Node2D, move_speed: float, delta: float) -> void:
	var bite_cd: float = wolf.get_meta("bite_cooldown", 0.0)
	if bite_cd > 0.0:
		bite_cd -= delta
		wolf.set_meta("bite_cooldown", bite_cd)
		
	# Uluma sayacı ve kritik an kontrolü
	var howl_cd: float = wolf.get_meta("howl_timer", 10.0) - delta
	wolf.set_meta("howl_timer", howl_cd)
	if howl_cd <= 0.0:
		wolf.set_meta("howl_timer", 13.0)
		_wolf_howl(wolf)
		return
		
	var target: Node2D = wolf.get_meta("current_target")
	if not target or not is_instance_valid(target) or ("is_dead" in target and target.is_dead):
		target = _find_nearest_enemy_for_wolf(wolf.global_position)
		wolf.set_meta("current_target", target)
		
	var dest_pos := player.global_position
	if target and is_instance_valid(target):
		dest_pos = target.global_position
		
	var to_dest: Vector2 = dest_pos - wolf.global_position
	var dist: float = to_dest.length()
	
	# Koşma animasyonu (hafif zıplama)
	var spr: Sprite2D = wolf.get_child(0) as Sprite2D
	if spr:
		var walk_val: float = wolf.get_meta("walk_anim", 0.0) + delta * 12.0
		wolf.set_meta("walk_anim", walk_val)
		spr.scale.y = 0.42 * (1.0 + sin(walk_val) * 0.15)
		spr.scale.x = 0.42 * (1.0 - sin(walk_val) * 0.1)
		if to_dest.x != 0.0:
			spr.flip_h = to_dest.x < 0.0
			
	if dist > 24.0:
		var move_step := to_dest.normalized() * move_speed * delta
		wolf.global_position += move_step
	else:
		# Isırma menzilinde
		if target and is_instance_valid(target) and bite_cd <= 0.0:
			wolf.set_meta("bite_cooldown", 0.35)
			_wolf_bite(wolf, target)

func _find_nearest_enemy_for_wolf(from_pos: Vector2) -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_d: float = 450.0
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			var d: float = from_pos.distance_to(e.global_position)
			if d < min_d:
				min_d = d
				nearest = e
	return nearest

func _wolf_howl(wolf: Node2D) -> void:
	var spr: Sprite2D = wolf.get_child(0) as Sprite2D
	if spr:
		var tw := create_tween()
		tw.tween_property(spr, "scale", Vector2(0.55, 0.65), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(spr, "scale", Vector2(0.42, 0.42), 0.25)
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("level_up", 0.2, 1.8) # Mistik tiz uluma rezonansı
		
	if player and player.has_method("add_camera_shake"):
		player.add_camera_shake(2.0)
		
	# Ruhani Uluma Şok Dalgası
	var wave := Node2D.new()
	wave.global_position = wolf.global_position
	wave.set_script(load("res://scripts/toxic_blast_fx.gd"))
	get_tree().current_scene.call_deferred("add_child", wave)
	
	var dmg_mult: float = player.damage_multiplier if (player and "damage_multiplier" in player) else 1.0
	var howl_dmg: float = damage * 1.5 * dmg_mult
	
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			var dist := wolf.global_position.distance_to(e.global_position)
			if dist <= 240.0:
				if player and player.has_method("record_weapon_damage"):
					player.record_weapon_damage("weapon_spirit_wolf", howl_dmg)
				if e.has_method("take_damage"):
					e.take_damage(howl_dmg, true, wolf.global_position, "weapon_spirit_wolf")
				# Korku / Geri Kaçırma (Fear / Heavy Knockback & Stun)
				if "knockback_velocity" in e:
					var flee_dir: Vector2 = (e.global_position - wolf.global_position).normalized()
					e.knockback_velocity += flee_dir * 450.0
				if e.has_method("apply_status"):
					e.apply_status("stun", 1.5)

func _wolf_bite(wolf: Node2D, target: Node2D) -> void:
	var dmg_mult: float = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var crit_prob: float = player.crit_chance if "crit_chance" in player else 0.05
	var is_crit: bool = randf() < crit_prob
	var final_dmg: float = damage * dmg_mult * (2.0 if is_crit else 1.0)
	
	if player and player.has_method("record_weapon_damage"):
		player.record_weapon_damage("weapon_spirit_wolf", final_dmg)
		
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(final_dmg, is_crit, wolf.global_position, "weapon_spirit_wolf")
		if "knockback_velocity" in target:
			var push_dir: Vector2 = (target.global_position - wolf.global_position).normalized()
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.UP
			target.knockback_velocity += push_dir * 140.0
			
	# Lv.7'de yakındaki diğer düşmanları da parçalar (Cleave)
	if current_level >= 7:
		var enemies := get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if e != target and is_instance_valid(e) and e.has_method("take_damage"):
				if wolf.global_position.distance_to(e.global_position) <= 80.0:
					e.take_damage(final_dmg * 0.6, is_crit, wolf.global_position, "weapon_spirit_wolf")
					
	var audio = get_node_or_null("/root/AudioManager")
	if audio and randf() < 0.4:
		audio.play_sfx("pencil_slash", 0.08, 1.3)
