extends Node2D

@export var weapon_id: String = "weapon_earthquake"
@export var current_level: int = 1

@export var base_damage: float = 32.0
@export var base_cooldown: float = 2.6
@export var base_radius: float = 160.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var timer: float = 0.0
var damage: float = 32.0
var last_player_hp: float = 100.0

func _ready() -> void:
	damage = base_damage
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if player and "current_health" in player:
		last_player_hp = player.current_health

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)
	base_radius = 160.0 * (1.0 + (current_level - 1) * 0.12)
	base_cooldown = maxf(1.2, 2.6 * (1.0 - (current_level - 1) * 0.08))
	if current_level >= 7:
		damage *= 1.40
		base_radius *= 1.25

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	global_position = player.global_position
	
	# Misilleme (Retaliation): Oyuncu hasar aldığında anında tetiklenir
	if "current_health" in player:
		if player.current_health < last_player_hp - 1.0:
			timer = 999.0 # Anında tetikle
		last_player_hp = player.current_health
		
	var cd_mult: float = player.cooldown_mult if "cooldown_mult" in player else 1.0
	timer += delta
	if timer >= (base_cooldown * cd_mult):
		timer = 0.0
		_trigger_earthquake()

func _trigger_earthquake() -> void:
	var area_scale: float = player.area_mult if player and "area_mult" in player else 1.0
	var final_radius := base_radius * area_scale
	
	var dmg_mult: float = player.damage_multiplier if "damage_multiplier" in player else 1.0
	var crit_prob: float = player.crit_chance if "crit_chance" in player else 0.05
	var is_crit: bool = randf() < crit_prob
	
	# Zırh ve Maks Can sinerjisi
	var armor_bonus: float = (player.armor * 80.0) if ("armor" in player) else 0.0
	var hp_bonus: float = maxf(0.0, (player.max_health - 100.0) * 0.25) if ("max_health" in player) else 0.0
	var final_dmg: float = (damage + armor_bonus + hp_bonus) * dmg_mult * (2.0 if is_crit else 1.0)
	
	_spawn_shockwave_visual(global_position, final_radius, is_crit)
	_hit_enemies_in_radius(global_position, final_radius, final_dmg, is_crit)
	
	# Lv.7'de 0.25sn sonra İkincil Artçı Şok Dalgası (Aftershock)
	if current_level >= 7:
		var aftershock_timer := get_tree().create_timer(0.25)
		aftershock_timer.timeout.connect(func():
			if is_instance_valid(player):
				_spawn_shockwave_visual(player.global_position, final_radius * 1.3, is_crit)
				_hit_enemies_in_radius(player.global_position, final_radius * 1.3, final_dmg * 0.7, is_crit)
		)

func _spawn_shockwave_visual(pos: Vector2, radius: float, is_crit: bool = false) -> void:
	var spr := Sprite2D.new()
	spr.z_index = -1
	spr.texture = preload("res://assets/sprites/weapons/proj_orb.png")
	spr.global_position = pos
	spr.scale = Vector2.ZERO
	spr.modulate = Color(1.5, 1.2, 0.5, 0.55) # Zemin seviyesi sismik şok dalgası
	
	var target_parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_parent.add_child(spr)
	
	var target_scale: float = (radius * 2.0) / 128.0
	var tw := spr.create_tween()
	tw.parallel().tween_property(spr, "scale", Vector2(target_scale, target_scale), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.28)
	tw.tween_callback(spr.queue_free)
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("flame_burst", 0.16, 0.6)
		
	if player and player.has_method("add_camera_shake"):
		player.add_camera_shake(3.2 if is_crit else 2.0)

func _hit_enemies_in_radius(pos: Vector2, radius: float, dmg: float, is_crit: bool) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			if "is_dead" in e and e.is_dead:
				continue
			var dist: float = pos.distance_to(e.global_position)
			if dist <= radius:
				var push_dir: Vector2 = (e.global_position - pos).normalized()
				if push_dir == Vector2.ZERO:
					push_dir = Vector2.UP
				e.take_damage(dmg, is_crit, pos, "weapon_earthquake")
				if "knockback_velocity" in e:
					e.knockback_velocity += push_dir * 320.0
