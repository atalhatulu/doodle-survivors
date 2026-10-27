extends CharacterBody2D

signal health_changed(current_hp: float, max_hp: float)
signal xp_changed(current_xp: int, max_xp: int, level: int)
signal level_up(new_level: int)
signal player_died()
signal coins_changed(total_coins: int, gained_in_run: int)

@export var move_speed: float = 230.0
@export var acceleration: float = 1800.0
@export var friction: float = 2000.0

@export var max_health: float = 100.0
var current_health: float = 100.0

# Pasif Stat Çarpanları
var damage_multiplier: float = 1.0
var cooldown_mult: float = 1.0
var area_mult: float = 1.0
var armor: float = 0.0
var crit_chance: float = 0.05
var magnet_range_mult: float = 1.0

# Sahip Olunan Silahlar ve Seviyeleri (id -> {level: int, node: Node2D})
var owned_weapons: Dictionary = {}
const MAX_WEAPON_LEVEL: int = 7

# Sahip Olunan Pasifler ve Seviyeleri (id -> level: int)
var owned_passives: Dictionary = {}
const MAX_PASSIVE_LEVEL: int = 5

# Seviye ve XP
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 45 # Başlangıç XP barı

# Kalıcı Altın / Kağıt Ataş (Coins)
const SAVE_PATH: String = "user://doodle_save.json"
var coins_in_run: int = 0
var total_coins: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon_slots: Node2D = $WeaponSlots
@onready var hp_bar: ProgressBar = $HPBar
@onready var hurtbox: Area2D = $Hurtbox
@onready var camera: Camera2D = $Camera2D

var facing_direction: float = 1.0
var walk_cycle: float = 0.0
var base_scale: Vector2 = Vector2(0.18, 0.18)
var hit_flash_tween: Tween
var is_dead: bool = false

# Kamera Sarsıntısı (Screen Shake)
var trauma: float = 0.0
var max_shake_offset: float = 14.0

func _ready() -> void:
	add_to_group("player")
	
	# Kalıcı yükseltmeleri uygula (Atölyeden satın alınanlar)
	var meta := get_node_or_null("/root/MetaProgression")
	if meta:
		meta.apply_to_player(self)
		total_coins = meta.total_coins
		
	current_health = max_health
	if sprite:
		sprite.scale = base_scale
	_update_hp_bar()
	
	# Başlangıçta slotlardaki mevcut silahları kaydet (ör. WeaponAxe)
	call_deferred("_register_initial_weapons")
	call_deferred("_emit_initial_stats")

func _register_initial_weapons() -> void:
	if not weapon_slots:
		return
	for slot in weapon_slots.get_children():
		for child in slot.get_children():
			if "weapon_id" in child:
				owned_weapons[child.weapon_id] = {"level": 1, "node": child}
			else:
				# Sahne adına göre varsayılan id eşle
				var sname: String = child.name.to_snake_case()
				owned_weapons[sname] = {"level": 1, "node": child}

func _emit_initial_stats() -> void:
	emit_signal("health_changed", current_health, max_health)
	emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)
	emit_signal("coins_changed", total_coins, coins_in_run)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * move_speed, acceleration * delta)
		if input_vector.x != 0.0:
			facing_direction = sign(input_vector.x)
			sprite.flip_h = facing_direction < 0.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	move_and_slide()
	_animate_procedural(delta)
	_check_enemy_contacts()
	_process_camera_shake(delta)

func add_camera_shake(amount: float) -> void:
	trauma = clampf(trauma + amount * 0.05, 0.0, 0.6)

func _process_camera_shake(delta: float) -> void:
	if not camera:
		return
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - delta * 3.5)
		var shake_power := trauma * trauma
		camera.offset = Vector2(
			randf_range(-1.0, 1.0) * (max_shake_offset * 0.4) * shake_power,
			randf_range(-1.0, 1.0) * (max_shake_offset * 0.4) * shake_power
		)
	else:
		camera.offset = Vector2.ZERO

func _check_enemy_contacts() -> void:
	if not hurtbox or is_dead:
		return
	var overlapping := hurtbox.get_overlapping_bodies()
	for body in overlapping:
		if body and body.is_in_group("enemies"):
			take_damage(0.4)

func _animate_procedural(delta: float) -> void:
	if not sprite or is_dead:
		return
		
	var speed_ratio := velocity.length() / move_speed
	
	if speed_ratio > 0.05:
		walk_cycle += delta * 15.0 * speed_ratio
		var bob := sin(walk_cycle)
		var tilt := cos(walk_cycle * 0.5) * 0.12 * facing_direction
		
		sprite.rotation = tilt
		sprite.scale.x = base_scale.x * (1.0 + bob * 0.08)
		sprite.scale.y = base_scale.y * (1.0 - bob * 0.08)
	else:
		walk_cycle += delta * 3.5
		var breath := sin(walk_cycle)
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, delta * 10.0)
		sprite.scale.x = base_scale.x * (1.0 + breath * 0.03)
		sprite.scale.y = base_scale.y * (1.0 - breath * 0.03)

func take_damage(amount: float) -> void:
	if is_dead:
		return
		
	# Zırh hasar indirimi
	var reduced_damage: float = maxf(1.0, amount * (1.0 - armor))
	current_health = max(0.0, current_health - reduced_damage)
	_update_hp_bar()
	emit_signal("health_changed", current_health, max_health)
	add_camera_shake(2.5)
	
	if hit_flash_tween and hit_flash_tween.is_valid():
		hit_flash_tween.kill()
		
	hit_flash_tween = create_tween()
	sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	hit_flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)
	
	if current_health <= 0.0:
		_die()

func _update_hp_bar() -> void:
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("game_over", 0.0, 1.0)
	emit_signal("player_died")
	
	# Ölüm görseli (Kağıt solması ve düşüş)
	var tween := create_tween()
	tween.parallel().tween_property(sprite, "rotation", PI * 0.5 * facing_direction, 0.4)
	tween.parallel().tween_property(sprite, "modulate", Color(0.4, 0.4, 0.4, 0.5), 0.4)

func add_xp(amount: int) -> void:
	if is_dead:
		return
	current_xp += amount
	var audio = get_node_or_null("/root/AudioManager")
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		# 20 dakikalık dengeli VS tipi XP gereksinimi:
		# 4-5. dakikada ~12-16 seviye, 10. dakikada ~35-40 seviye, 20. dakikada ~70-75 seviye
		if current_level <= 5:
			xp_to_next_level = int(40 + current_level * 35)
		elif current_level <= 15:
			xp_to_next_level = int(140 + current_level * 55 + pow(current_level, 1.45) * 12)
		elif current_level <= 35:
			xp_to_next_level = int(350 + current_level * 80 + pow(current_level, 1.6) * 18)
		else:
			xp_to_next_level = int(800 + current_level * 110 + pow(current_level, 1.75) * 25)
			
		if audio:
			audio.play_sfx("level_up", 0.05, 1.0)
		emit_signal("level_up", current_level)
		
	emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

func apply_upgrade(data: Dictionary) -> void:
	if data["type"] == "weapon":
		var weapon_id: String = data["id"]
		if owned_weapons.has(weapon_id):
			# Mevcut silahı yükselt
			var w_info: Dictionary = owned_weapons[weapon_id]
			w_info["level"] = mini(w_info["level"] + 1, MAX_WEAPON_LEVEL)
			var w_node: Node2D = w_info["node"]
			if is_instance_valid(w_node) and w_node.has_method("upgrade_level"):
				w_node.upgrade_level(w_info["level"])
		else:
			# Yeni silah ekle
			var scene_path: String = data["scene"]
			var weapon_scene = load(scene_path)
			if weapon_scene:
				var weapon_inst = weapon_scene.instantiate()
				if equip_weapon(weapon_inst):
					owned_weapons[weapon_id] = {"level": 1, "node": weapon_inst}
	elif data["type"] == "stat":
		var passive_id: String = data.get("id", "")
		if passive_id != "":
			owned_passives[passive_id] = owned_passives.get(passive_id, 0) + 1
			
		var stat_name: String = data["stat"]
		if stat_name == "move_speed":
			move_speed *= float(data["value"])
		elif stat_name == "max_health":
			max_health += float(data["value"])
			current_health = minf(current_health + float(data["value"]), max_health)
			_update_hp_bar()
		elif stat_name == "damage_mult":
			damage_multiplier *= float(data["value"])
		elif stat_name == "cooldown_mult":
			cooldown_mult = maxf(0.35, cooldown_mult * float(data["value"]))
		elif stat_name == "area_mult":
			area_mult *= float(data["value"])
		elif stat_name == "armor":
			armor = minf(0.70, armor + float(data["value"])) # Maksimum %70 zırh
		elif stat_name == "crit_chance":
			crit_chance = minf(1.0, crit_chance + float(data["value"]))
		elif stat_name == "magnet_range":
			magnet_range_mult *= float(data["value"])

func equip_weapon(weapon_node: Node2D) -> bool:
	if not weapon_slots:
		return false
	for slot in weapon_slots.get_children():
		if slot.get_child_count() == 0:
			slot.add_child(weapon_node)
			weapon_node.position = Vector2.ZERO
			return true
	return false

func has_weapon(weapon_id: String) -> bool:
	return owned_weapons.has(weapon_id)

func get_weapon_level(weapon_id: String) -> int:
	if owned_weapons.has(weapon_id):
		return owned_weapons[weapon_id]["level"]
	return 0

func has_free_weapon_slot() -> bool:
	if not weapon_slots:
		return false
	for slot in weapon_slots.get_children():
		if slot.get_child_count() == 0:
			return true
	return false

func has_passive(passive_id: String) -> bool:
	return owned_passives.has(passive_id)

func get_passive_level(passive_id: String) -> int:
	return owned_passives.get(passive_id, 0)

func has_free_passive_slot() -> bool:
	# Maksimum 6 farklı pasif alınabilir
	return owned_passives.keys().size() < 6

func add_coins(amount: int) -> void:
	coins_in_run += amount
	var meta := get_node_or_null("/root/MetaProgression")
	if meta:
		meta.total_coins += amount
		meta.save_data()
		total_coins = meta.total_coins
	else:
		total_coins += amount
	emit_signal("coins_changed", total_coins, coins_in_run)
