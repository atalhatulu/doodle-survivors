extends CharacterBody2D

signal health_changed(current_hp: float, max_hp: float)
signal xp_changed(current_xp: int, max_xp: int, level: int)
signal level_up(new_level: int)
signal player_died()
signal coins_changed(total_coins: int, gained_in_run: int)
signal dash_cooldown_updated(current_cd: float, max_cd: float)
signal dash_performed(dash_name: String)

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
var base_crit_chance: float = 0.05
var crit_chance: float = 0.05
var luck_mult: float = 1.0
var magnet_range_mult: float = 1.0
var xp_remainder: float = 0.0
var coin_remainder: float = 0.0

# 11 Yeni Pasif Statları (Vampire Survivors Mekanikleri)
var extra_projectiles: int = 0
var hp_regen: float = 0.0
var projectile_speed_mult: float = 1.0
var duration_mult: float = 1.0
var xp_multiplier: float = 1.0
var gold_multiplier: float = 1.0
var revives_remaining: int = 0
var invulnerability_duration: float = 0.35
var invulnerable_timer: float = 0.0
var curse_mult: float = 1.0
var frenzy_gold_bonus: float = 1.0

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
var base_scale: Vector2 = Vector2(0.35, 0.35)
var hit_flash_tween: Tween
var is_dead: bool = false

# Karakter ve Taktiksel Yetenek (Dash)
var current_character_id: String = "knight"
var character_id: String:
	get: return current_character_id
	set(v): current_character_id = v
var dash_base_cooldown: float = 4.5
var dash_timer: float = 0.0
var is_dashing: bool = false
var dash_duration_timer: float = 0.0
var dash_velocity: Vector2 = Vector2.ZERO
var afterimage_spawn_timer: float = 0.0

# Minion takibi (Gölge Çağırıcı)
var active_minions: Array[Node2D] = []
const MAX_MINIONS: int = 8
var minion_scene: PackedScene = preload("res://scenes/entities/minion_skeleton.tscn")

# İstatistik ve DPS Kaydı
var weapon_damage_tracker: Dictionary = {}
var total_enemies_killed: int = 0

# Usule Dayalı Canlılık (Procedural Animation)
var idle_cycle: float = 0.0
var dust_particles: CPUParticles2D = null

# Kamera Sarsıntısı ve TPS Perspektif Takibi
var trauma: float = 0.0
var max_shake_offset: float = 16.0

# TPS Over-The-Shoulder Kamera ve Perspektif Değişkenleri
# Prototype referansı: tpsDistance = 11, tpsHeight = 6.8 (2D piksel ölçeğinde ~180px mesafe, -80px yükseklik)
var tps_enabled: bool = true
var tps_target_offset: Vector2 = Vector2(0.0, -90.0)
var tps_look_lead: Vector2 = Vector2.ZERO
var tps_mouse_aim_angle: float = 0.0
var tps_aim_lead_distance: float = 160.0

# Merkezi Mıknatıs ve Toplama Alanları (Kristallerin fizik yükünü sıfırlar)
var magnet_area: Area2D = null
var magnet_shape: CollisionShape2D = null
var pickup_area: Area2D = null
var pickup_shape: CollisionShape2D = null

func _ready() -> void:
	add_to_group("player")
	_setup_dash_input()
	_setup_dust_particles()
	_setup_magnet_areas()
	
	# Kalıcı yükseltmeleri uygula (Atölyeden satın alınanlar)
	var meta := get_node_or_null("/root/MetaProgression")
	if meta:
		meta.apply_to_player(self)
		total_coins = meta.total_coins
		
	_apply_character_selection()
		
	current_health = max_health
	if sprite:
		sprite.scale = base_scale
	_update_hp_bar()

func _setup_dash_input() -> void:
	if not InputMap.has_action("dash"):
		InputMap.add_action("dash")
		var ev := InputEventKey.new()
		ev.keycode = KEY_SPACE
		InputMap.action_add_event("dash", ev)

func _setup_dust_particles() -> void:
	dust_particles = CPUParticles2D.new()
	dust_particles.emitting = false
	dust_particles.amount = 8
	dust_particles.lifetime = 0.35
	dust_particles.direction = Vector2(0, 1)
	dust_particles.spread = 40.0
	dust_particles.gravity = Vector2(0, 25)
	dust_particles.initial_velocity_min = 15.0
	dust_particles.initial_velocity_max = 35.0
	dust_particles.scale_amount_min = 2.0
	dust_particles.scale_amount_max = 4.0
	dust_particles.color = Color(0.65, 0.58, 0.48, 0.55)
	dust_particles.position = Vector2(0, 8)
	add_child(dust_particles)
	
	# Başlangıçta slotlardaki mevcut silahları kaydet
	call_deferred("_register_initial_weapons")
	call_deferred("_emit_initial_stats")

func _setup_magnet_areas() -> void:
	# Merkezi Mıknatıs Çekim Alanı (Layer 8 - XP kristalleri ve Altınlar)
	magnet_area = Area2D.new()
	magnet_area.name = "CentralMagnetArea"
	magnet_area.collision_layer = 0
	magnet_area.collision_mask = 8
	magnet_area.monitoring = true
	magnet_area.monitorable = false
	
	magnet_shape = CollisionShape2D.new()
	var c_shape := CircleShape2D.new()
	c_shape.radius = 180.0 * magnet_range_mult
	magnet_shape.shape = c_shape
	magnet_area.add_child(magnet_shape)
	add_child(magnet_area)
	magnet_area.area_entered.connect(_on_magnet_area_entered)
	
	# Doğrudan Dokunma / Toplama Alanı
	pickup_area = Area2D.new()
	pickup_area.name = "CentralPickupArea"
	pickup_area.collision_layer = 0
	pickup_area.collision_mask = 8
	pickup_area.monitoring = true
	pickup_area.monitorable = false
	
	pickup_shape = CollisionShape2D.new()
	var p_shape := CircleShape2D.new()
	p_shape.radius = 28.0
	pickup_shape.shape = p_shape
	pickup_area.add_child(pickup_shape)
	add_child(pickup_area)
	pickup_area.area_entered.connect(_on_pickup_area_entered)

func _update_magnet_radius() -> void:
	if magnet_shape and magnet_shape.shape is CircleShape2D:
		(magnet_shape.shape as CircleShape2D).radius = 180.0 * magnet_range_mult

func _on_magnet_area_entered(area: Area2D) -> void:
	if area and area.has_method("start_attraction"):
		area.start_attraction(self)
	elif area and "is_attracted" in area:
		area.is_attracted = true

func _on_pickup_area_entered(area: Area2D) -> void:
	if area and area.has_method("_collect"):
		area._collect(self)

func _apply_character_selection() -> void:
	var meta := get_node_or_null("/root/MetaProgression")
	if not meta or not ("selected_character_id" in meta):
		return
		
	var char_id: String = meta.selected_character_id
	if not meta.CHARACTERS.has(char_id):
		char_id = "knight"
	current_character_id = char_id
		
	var cdata: Dictionary = meta.CHARACTERS[char_id]
	
	if sprite:
		sprite.modulate = Color.WHITE
		
	var mods: Dictionary = cdata.get("stat_mods", {})
	if mods.has("max_health"):
		max_health += mods["max_health"]
		current_health = max_health
	if mods.has("armor"):
		armor += mods["armor"]
	if mods.has("move_speed_mult"):
		move_speed *= mods["move_speed_mult"]
	if mods.has("area_mult"):
		area_mult *= mods["area_mult"]
	if mods.has("cooldown_mult"):
		cooldown_mult *= mods["cooldown_mult"]
	if mods.has("luck"):
		luck_mult += mods["luck"]
		crit_chance = minf(1.0, base_crit_chance + (luck_mult - 1.0) * 0.4)
	if mods.has("projectile_speed_mult"):
		projectile_speed_mult *= mods["projectile_speed_mult"]
	if mods.has("duration_mult"):
		duration_mult *= mods["duration_mult"]
	if mods.has("extra_projectiles"):
		extra_projectiles += int(mods["extra_projectiles"])
	if mods.has("hp_regen"):
		hp_regen += mods["hp_regen"]
	if mods.has("xp_multiplier"):
		xp_multiplier *= mods["xp_multiplier"]
		
	# Seçilen karakterin başlangıç silahını Slot1'e yerleştir
	if cdata.has("weapon_scene") and weapon_slots:
		var slot1 = weapon_slots.get_node_or_null("Slot1_Right")
		if slot1:
			for ch in slot1.get_children():
				ch.queue_free()
			var w_scene: PackedScene = load(cdata["weapon_scene"])
			if w_scene:
				var w_node = w_scene.instantiate()
				slot1.add_child(w_node)
				var wid: String = cdata.get("weapon_id", "weapon_sword")
				owned_weapons[wid] = {"level": 1, "node": w_node}

func _register_initial_weapons() -> void:
	if not weapon_slots:
		return
	for slot in weapon_slots.get_children():
		for child in slot.get_children():
			if not is_instance_valid(child) or child.is_queued_for_deletion():
				continue
			var wid: String = child.weapon_id if "weapon_id" in child else child.name.to_snake_case()
			if not owned_weapons.has(wid):
				owned_weapons[wid] = {"level": 1, "node": child}

func _emit_initial_stats() -> void:
	emit_signal("health_changed", current_health, max_health)
	emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)
	emit_signal("coins_changed", total_coins, coins_in_run)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Atılma bekleme süresi sayacı
	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
		var max_cd: float = dash_base_cooldown * cooldown_mult
		emit_signal("dash_cooldown_updated", dash_timer, max_cd)
		
	if Input.is_action_just_pressed("dash"):
		_try_dash()
		
	if is_dashing:
		dash_duration_timer -= delta
		afterimage_spawn_timer += delta
		if afterimage_spawn_timer >= 0.04:
			afterimage_spawn_timer = 0.0
			_spawn_afterimage()
			
		velocity = dash_velocity
		move_and_slide()
		
		if current_character_id == "knight":
			_check_shield_rush_impact()
			
		if dash_duration_timer <= 0.0:
			is_dashing = false
	else:
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
	
	if dust_particles:
		dust_particles.emitting = velocity.length() > 30.0
		if velocity.x != 0.0:
			dust_particles.direction = Vector2(-sign(velocity.x), -0.2)
	
	# Can yenileme (Pummarola / Doodle Bandajı)
	if hp_regen > 0.0 and current_health < max_health:
		current_health = minf(max_health, current_health + hp_regen * delta)
		_update_hp_bar()
		emit_signal("health_changed", current_health, max_health)
		
	# Dokunulmazlık süresi sayacı (Parm Aegis / Cetvel Kalkan)
	if invulnerable_timer > 0.0:
		invulnerable_timer = maxf(0.0, invulnerable_timer - delta)
		
	_check_enemy_contacts()
	_process_camera_shake(delta)

func add_camera_shake(amount: float) -> void:
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var meta = tree.root.get_node_or_null("MetaProgression") if (tree and tree.root) else null
	var mult: float = float(meta.settings.get("screen_shake", 1.0)) if meta else 1.0
	trauma = clampf(trauma + amount * 0.05 * mult, 0.0, 0.6)

func _process_camera_shake(delta: float) -> void:
	if not camera:
		return
		
	var shake_offset := Vector2.ZERO
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - delta * 3.5)
		var shake_power := trauma * trauma
		shake_offset = Vector2(
			randf_range(-1.0, 1.0) * (max_shake_offset * 0.4) * shake_power,
			randf_range(-1.0, 1.0) * (max_shake_offset * 0.4) * shake_power
		)
		
	if tps_enabled and is_inside_tree():
		# TPS Hedefleme: Farenin ekrandaki konumuna göre ileri ufuk / omuz üstü önleme açısı hesapla
		var vp := get_viewport()
		if vp:
			var mouse_pos := vp.get_mouse_position()
			var vp_size := vp.get_visible_rect().size
			if vp_size.x > 0.0 and vp_size.y > 0.0:
				var center := vp_size * 0.5
				var mouse_norm := Vector2(
					clampf((mouse_pos.x - center.x) / (vp_size.x * 0.5), -1.0, 1.0),
					clampf((mouse_pos.y - center.y) / (vp_size.y * 0.5), -1.0, 1.0)
				)
				# HTML TPS mantığı: cameraAngleX ve lookTarget.y (+2.2 yükseklik ve ileri görüş)
				var target_lead := Vector2(mouse_norm.x * tps_aim_lead_distance, mouse_norm.y * (tps_aim_lead_distance * 0.45))
				tps_look_lead = tps_look_lead.lerp(target_lead, delta * 8.0)
				
		# TPS Omuz Üstü Temel Görüş: Karakterin arkasından hafif yukarıya ufka bakış
		camera.offset = tps_target_offset + tps_look_lead + shake_offset
	else:
		camera.offset = shake_offset


func _check_enemy_contacts() -> void:
	if not hurtbox or is_dead or invulnerable_timer > 0.0:
		return
	var overlapping := hurtbox.get_overlapping_bodies()
	for body in overlapping:
		if body and body.is_in_group("enemies"):
			var dead_status: bool = body.get("is_dead") if "is_dead" in body else false
			if not dead_status:
				var dmg: float = float(body.get("damage")) if "damage" in body else 10.0
				if dmg > 0.0:
					take_damage(dmg)
					break

func _animate_procedural(delta: float) -> void:
	if not sprite or is_dead:
		return
		
	var speed_ratio := velocity.length() / move_speed
	
	if speed_ratio > 0.05:
		# Hareket halinde: Lean tilt (öne eğilme) ve adım esnemesi (squash & stretch)
		walk_cycle += delta * 16.0 * clampf(speed_ratio, 0.4, 1.4)
		var step_squash := absf(sin(walk_cycle))
		var lean: float = (velocity.x / move_speed) * 0.16
		var target_rot: float = lean + cos(walk_cycle) * 0.09 * facing_direction
		
		sprite.rotation = lerp_angle(sprite.rotation, target_rot, delta * 14.0)
		sprite.scale.x = base_scale.x * (1.0 + (step_squash - 0.5) * 0.16)
		sprite.scale.y = base_scale.y * (1.0 - (step_squash - 0.5) * 0.16)
		sprite.position.y = -absf(cos(walk_cycle)) * 4.0
	else:
		# Dururken: Nefes alma hareketi (breathing bob)
		idle_cycle += delta * 2.8
		var breath := sin(idle_cycle)
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, delta * 10.0)
		sprite.scale.x = base_scale.x * (1.0 + breath * 0.04)
		sprite.scale.y = base_scale.y * (1.0 - breath * 0.04)
		sprite.position.y = lerp(sprite.position.y, -breath * 1.5, delta * 8.0)

func take_damage(amount: float) -> void:
	if is_dead or invulnerable_timer > 0.0:
		return
		
	invulnerable_timer = invulnerability_duration
		
	# Zırh hasar indirimi
	var reduced_damage: float = maxf(1.0, amount * (1.0 - armor))
	current_health = max(0.0, current_health - reduced_damage)
	_update_hp_bar()
	emit_signal("health_changed", current_health, max_health)
	add_camera_shake(2.5)
	
	if sprite:
		if hit_flash_tween and hit_flash_tween.is_valid():
			hit_flash_tween.kill()
		hit_flash_tween = create_tween()
		sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
		hit_flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.4), 0.1)
		hit_flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1.0), maxf(0.05, invulnerability_duration - 0.1))
	
	if current_health <= 0.0:
		_die()

func _update_hp_bar() -> void:
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health

func heal(amount: float) -> void:
	if is_dead or current_health <= 0.0:
		return
	current_health = minf(max_health, current_health + amount)
	_update_hp_bar()
	emit_signal("health_changed", current_health, max_health)

func _die() -> void:
	if is_dead:
		return
		
	# Yeniden Doğma Hakkı (Tirajisú / Yedek Silgi)
	if revives_remaining > 0:
		revives_remaining -= 1
		current_health = max_health * 0.5
		invulnerable_timer = 2.5 # 2.5 saniye koruma kalkanı
		_update_hp_bar()
		emit_signal("health_changed", current_health, max_health)
		
		# Şok dalgası: Çevredeki düşmanları savur
		var tree := get_tree()
		if tree:
			var enemies := tree.get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) < 320.0:
					var push_dir: Vector2 = (e.global_position - global_position).normalized()
					if "knockback_velocity" in e:
						e.knockback_velocity = push_dir * 600.0
					
		var audio = _get_audio()
		if audio:
			audio.play_sfx("level_up", 0.05, 1.6)
			
		if sprite:
			var tw := create_tween()
			tw.tween_property(sprite, "modulate", Color(3.0, 3.0, 0.5, 1.0), 0.2)
			tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)
		return
		
	is_dead = true
	var audio = _get_audio()
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
	var raw_xp: float = float(amount) * xp_multiplier + xp_remainder
	var gained_xp: int = int(floor(raw_xp))
	xp_remainder = raw_xp - float(gained_xp)
	if gained_xp < 1:
		return
	current_xp += gained_xp
	var audio = _get_audio()
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
	if data.get("type", "") == "evolution":
		var base_id: String = data.get("base_weapon_id", "")
		evolve_weapon(base_id, data)
	elif data["type"] == "weapon":
		var weapon_id: String = data["id"]
		if owned_weapons.has(weapon_id) and is_instance_valid(owned_weapons[weapon_id].get("node")):
			# Mevcut silahı yükselt
			var w_info: Dictionary = owned_weapons[weapon_id]
			w_info["level"] = mini(w_info["level"] + 1, MAX_WEAPON_LEVEL)
			var w_node: Node2D = w_info["node"]
			if is_instance_valid(w_node) and w_node.has_method("upgrade_level"):
				w_node.upgrade_level(w_info["level"])
		else:
			# Yeni silah ekle
			var scene_path: String = data.get("scene", "")
			if scene_path != "" and ResourceLoader.exists(scene_path):
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
		elif stat_name == "crit_chance" or stat_name == "luck":
			luck_mult += float(data.get("value", 0.15))
			crit_chance = minf(1.0, base_crit_chance + (luck_mult - 1.0) * 0.4)
		elif stat_name == "magnet_range":
			magnet_range_mult *= float(data["value"])
			_update_magnet_radius()
		elif stat_name == "extra_projectiles":
			# Karbon Kağıdı (Duplicator): Maksimum +2 ekstra mermi
			extra_projectiles = mini(2, extra_projectiles + 1)
		elif stat_name == "hp_regen":
			# Doodle Bandajı (Pummarola): Saniyede +0.3 HP yenilenmesi
			hp_regen += float(data["value"])
		elif stat_name == "projectile_speed":
			# Paket Lastiği (Bracer): Mermi hızı +%15
			projectile_speed_mult *= float(data["value"])
		elif stat_name == "duration":
			# Kum Saati (Spellbinder): Etki süresi +%20
			duration_mult *= float(data["value"])
		elif stat_name == "xp_mult":
			# Mezuniyet Şapkası (Crown): XP kazanımı +%12
			xp_multiplier *= float(data["value"])
		elif stat_name == "gold_mult":
			# Kağıt Kumbara (Stone Mask): Altın kazanımı +%20
			gold_multiplier *= float(data["value"])
		elif stat_name == "revive":
			# Yedek Silgi (Tirajisú): Maksimum +2 yeniden doğma hakkı
			revives_remaining = mini(2, revives_remaining + 1)
		elif stat_name == "invulnerability":
			# Cetvel Kalkan (Parm Aegis): Dokunulmazlık süresi +0.12sn
			invulnerability_duration += float(data["value"])
		elif stat_name == "curse":
			# Mürekkep Kurukafa (Skull O'Maniac): Düşmanlar güçlenir, ödüller katlanır
			curse_mult *= 1.10
			xp_multiplier *= 1.15
			gold_multiplier *= 1.15
		elif stat_name == "torrona":
			# Origami Kutusu (Torrona's Box): Çok yönlü bonus, 5. seviyede lanet
			var lvl: int = owned_passives.get(passive_id, 1)
			if lvl == 5:
				curse_mult *= 1.25
				xp_multiplier *= 1.25
			else:
				damage_multiplier *= 1.05
				projectile_speed_mult *= 1.05
				area_mult *= 1.05
				duration_mult *= 1.05
		elif stat_name == "sharpener":
			# İkili Kalemtıraş (Karoma's Mana): Akın sıklığı ve altın şansı
			curse_mult *= 1.12
			frenzy_gold_bonus *= 1.35
	elif data["type"] == "consumable":
		var stat_name: String = data.get("stat", "")
		if stat_name == "heal":
			current_health = minf(max_health, current_health + float(data.get("value", 35.0)))
			_update_hp_bar()
			emit_signal("health_changed", current_health, max_health)
		elif stat_name == "gold":
			add_coins(int(data.get("value", 50)))

func equip_weapon(weapon_node: Node2D) -> bool:
	if not weapon_slots:
		return false
	for slot in weapon_slots.get_children():
		if slot.get_child_count() == 0:
			slot.add_child(weapon_node)
			weapon_node.position = Vector2.ZERO
			return true
	return false

func evolve_weapon(base_weapon_id: String, evo_data: Dictionary) -> bool:
	var evo_id: String = evo_data.get("id", "")
	var scene_path: String = evo_data.get("scene", "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return false
		
	var parent_slot: Node = null
	if owned_weapons.has(base_weapon_id):
		var old_info: Dictionary = owned_weapons[base_weapon_id]
		var old_node = old_info.get("node")
		if is_instance_valid(old_node):
			parent_slot = old_node.get_parent()
			old_node.queue_free()
		owned_weapons.erase(base_weapon_id)
		
	var evo_scene = load(scene_path)
	var evo_inst = evo_scene.instantiate()
	if parent_slot:
		parent_slot.add_child(evo_inst)
		evo_inst.position = Vector2.ZERO
	else:
		if not equip_weapon(evo_inst):
			add_child(evo_inst)
			
	owned_weapons[evo_id] = {"level": 1, "node": evo_inst, "is_evolution": true}
	
	var hud = get_tree().current_scene.get_node_or_null("HUD") if get_tree().current_scene else null
	if hud and hud.has_method("show_announcement"):
		hud.show_announcement("EFSANEVİ EVRİM: " + evo_data.get("title", ""), Color(1.0, 0.85, 0.2))
		
	var audio = _get_audio()
	if audio:
		audio.play_sfx("level_up", 0.0, 2.5)
	return true

func has_weapon(weapon_id: String) -> bool:
	if not owned_weapons.has(weapon_id):
		return false
	var w_node = owned_weapons[weapon_id].get("node")
	if w_node != null and not is_instance_valid(w_node):
		owned_weapons.erase(weapon_id)
		return false
	return true

func get_weapon_level(weapon_id: String) -> int:
	if has_weapon(weapon_id):
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
	var raw_coins: float = float(amount) * gold_multiplier * frenzy_gold_bonus + coin_remainder
	var gained_coins: int = int(floor(raw_coins))
	coin_remainder = raw_coins - float(gained_coins)
	if gained_coins < 1:
		return
	coins_in_run += gained_coins
	var meta := get_node_or_null("/root/MetaProgression")
	if meta:
		meta.total_coins += gained_coins
		meta.save_data()
		total_coins = meta.total_coins
	else:
		total_coins += gained_coins
	emit_signal("coins_changed", total_coins, coins_in_run)

func get_stats_sheet() -> Dictionary:
	return {
		# 11 Temel Savaş İstatistiği
		"max_health": {"name": "Maks. Can", "val": "%d HP" % int(max_health), "cat": "combat"},
		"recovery": {"name": "Yenilenme", "val": "+%.1f HP/sn" % hp_regen, "cat": "combat"},
		"armor": {"name": "Zırh", "val": "%%%d" % int(armor * 100), "cat": "combat"},
		"move_speed": {"name": "Hareket Hızı", "val": "%%%d" % int((move_speed / 230.0) * 100), "cat": "combat"},
		"might": {"name": "Hasar Gücü", "val": "%%%d" % int(damage_multiplier * 100), "cat": "combat"},
		"area": {"name": "Alan", "val": "%%%d" % int(area_mult * 100), "cat": "combat"},
		"speed": {"name": "Mermi Hızı", "val": "%%%d" % int(projectile_speed_mult * 100), "cat": "combat"},
		"duration": {"name": "Etki Süresi", "val": "%%%d" % int(duration_mult * 100), "cat": "combat"},
		"amount": {"name": "Mermi Miktarı", "val": "+%d" % extra_projectiles, "cat": "combat"},
		"cooldown": {"name": "Bekleme Süresi", "val": "%%%d" % int(cooldown_mult * 100), "cat": "combat"},
		"luck": {"name": "Şans", "val": "%%%d" % int(luck_mult * 100), "cat": "combat"},
		
		# 5 İlerleme ve Özel İstatistik
		"growth": {"name": "Büyüme (XP)", "val": "%%%d" % int(xp_multiplier * 100), "cat": "progression"},
		"greed": {"name": "Açgözlülük (Altın)", "val": "%%%d" % int(gold_multiplier * 100), "cat": "progression"},
		"curse": {"name": "Lanet", "val": "%%%d" % int(curse_mult * 100), "cat": "progression"},
		"magnet": {"name": "Mıknatıs", "val": "%%%d" % int(magnet_range_mult * 100), "cat": "progression"},
		"revival": {"name": "Yeniden Doğma", "val": "%d Can" % revives_remaining, "cat": "progression"}
	}

func record_weapon_damage(w_id: String, amount: float) -> void:
	weapon_damage_tracker[w_id] = weapon_damage_tracker.get(w_id, 0.0) + amount

func _get_audio() -> Node:
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	return tree.root.get_node_or_null("AudioManager") if (tree and tree.root) else null

func _try_dash() -> void:
	if is_dead or is_dashing or dash_timer > 0.0:
		return
		
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dash_dir := input_vector.normalized()
	if dash_dir == Vector2.ZERO:
		dash_dir = Vector2(facing_direction, 0.0)
		
	var max_cd: float = dash_base_cooldown * cooldown_mult
	dash_timer = max_cd
	is_dashing = true
	afterimage_spawn_timer = 0.0
	
	var audio = _get_audio()
	
	if current_character_id == "knight":
		# Sürgün Şövalye: Kalkanla Hücum (Shield Rush)
		dash_duration_timer = 0.35
		dash_velocity = dash_dir * 720.0
		invulnerable_timer = maxf(invulnerable_timer, 0.40)
		if audio:
			audio.play_sfx("axe_throw", 0.1, 1.4)
		emit_signal("dash_performed", "Kalkanla Hücum")
	elif current_character_id == "ranger":
		# Orman Korucusu: Gölge Taklası (Shadow Roll)
		dash_duration_timer = 0.32
		dash_velocity = dash_dir * 700.0
		invulnerable_timer = maxf(invulnerable_timer, 0.38)
		if sprite:
			var tw := create_tween()
			tw.tween_property(sprite, "rotation", TAU * facing_direction, 0.32)
			tw.tween_callback(func(): sprite.rotation = 0.0)
		_spawn_shadow_traps()
		if audio:
			audio.play_sfx("pencil_slash", 0.15, 1.8)
		emit_signal("dash_performed", "Gölge Taklası")
	elif current_character_id == "mage":
		# Karanlık Büyücü: Boyut Sıçraması (Arcane Blink)
		is_dashing = false
		dash_duration_timer = 0.0
		invulnerable_timer = maxf(invulnerable_timer, 0.35)
		_perform_arcane_blink(dash_dir)
		emit_signal("dash_performed", "Boyut Sıçraması")
	elif current_character_id == "alchemist":
		# Kızıl Simyager: Zehir Sisi (Toxic Flash)
		dash_duration_timer = 0.34
		dash_velocity = dash_dir * 580.0
		invulnerable_timer = maxf(invulnerable_timer, 0.45)
		_spawn_toxic_cloud()
		if audio:
			audio.play_sfx("potion_splash", 0.12, 1.2)
		emit_signal("dash_performed", "Zehir Sisi")
	elif current_character_id == "necromancer":
		# Gölge Çağırıcı: Ruh Sıçraması (Soul Shift)
		dash_duration_timer = 0.28
		dash_velocity = dash_dir * 640.0
		invulnerable_timer = maxf(invulnerable_timer, 0.40)
		_perform_soul_shift()
		emit_signal("dash_performed", "Ruh Sıçraması")
	else:
		dash_duration_timer = 0.30
		dash_velocity = dash_dir * 600.0
		invulnerable_timer = maxf(invulnerable_timer, 0.35)
		emit_signal("dash_performed", "Atılma")
		
	emit_signal("dash_cooldown_updated", dash_timer, max_cd)

func _spawn_afterimage() -> void:
	if not sprite:
		return
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.global_position = sprite.global_position
	ghost.rotation = sprite.rotation
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	
	var ghost_tint := Color(1.0, 1.0, 1.0, 0.6)
	if current_character_id == "knight":
		ghost_tint = Color(0.8, 0.9, 1.2, 0.65)
	elif current_character_id == "ranger":
		ghost_tint = Color(0.4, 1.2, 0.6, 0.65)
	elif current_character_id == "mage":
		ghost_tint = Color(1.4, 0.6, 2.0, 0.65)
	elif current_character_id == "alchemist":
		ghost_tint = Color(1.8, 0.4, 0.5, 0.65)
	elif current_character_id == "necromancer":
		ghost_tint = Color(0.5, 1.8, 1.2, 0.65)
	ghost.modulate = ghost_tint
	
	var target_parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_parent.add_child(ghost)
	
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.24)
	tw.tween_callback(ghost.queue_free)

func _check_shield_rush_impact() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var hit_dmg: float = 65.0 * damage_multiplier
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			if global_position.distance_to(e.global_position) <= 46.0:
				record_weapon_damage("dash_kalkan_hucumu", hit_dmg)
				if e.has_method("take_damage"):
					e.take_damage(hit_dmg, true, global_position, "dash_kalkan_hucumu")
				if "knockback_velocity" in e:
					var p_dir: Vector2 = (e.global_position - global_position).normalized()
					if p_dir == Vector2.ZERO:
						p_dir = dash_velocity.normalized()
					e.knockback_velocity += p_dir * 520.0
				if e.has_method("apply_status"):
					e.apply_status("stun", 1.2)

func _spawn_shadow_traps() -> void:
	var trap_script = preload("res://scripts/shadow_trap.gd")
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var target_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	for i in range(3):
		var trap := Area2D.new()
		trap.set_script(trap_script)
		trap.global_position = global_position - dash_velocity.normalized() * (i * 28.0)
		if target_parent:
			target_parent.call_deferred("add_child", trap)

func _perform_arcane_blink(dir: Vector2) -> void:
	var wave_pos := global_position
	var shock_dmg: float = 75.0 * damage_multiplier
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var enemies: Array = tree.get_nodes_in_group("enemies") if tree else []
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			if wave_pos.distance_to(e.global_position) <= 140.0:
				record_weapon_damage("dash_boyut_sicramasi", shock_dmg)
				if e.has_method("take_damage"):
					e.take_damage(shock_dmg, true, wave_pos, "dash_boyut_sicramasi")
				if "knockback_velocity" in e:
					var p_dir: Vector2 = (e.global_position - wave_pos).normalized()
					e.knockback_velocity += p_dir * 380.0
					
	var audio = _get_audio()
	if audio:
		audio.play_sfx("shoot", 0.15, 2.5)
	add_camera_shake(2.0)
	
	var fx := Node2D.new()
	fx.global_position = wave_pos
	fx.set_script(load("res://scripts/toxic_blast_fx.gd"))
	var target_p: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if target_p:
		target_p.call_deferred("add_child", fx)
	
	global_position += dir * 240.0

func _spawn_toxic_cloud() -> void:
	var cloud_script = preload("res://scripts/toxic_cloud.gd")
	var cloud := Node2D.new()
	cloud.set_script(cloud_script)
	cloud.global_position = global_position
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var target_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if target_parent:
		target_parent.call_deferred("add_child", cloud)

func _perform_soul_shift() -> void:
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var target_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	for i in range(2):
		if active_minions.size() < MAX_MINIONS:
			var skel = minion_scene.instantiate()
			skel.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			if target_parent:
				target_parent.call_deferred("add_child", skel)
			active_minions.append(skel)

func on_enemy_killed_near(enemy_pos: Vector2) -> void:
	if current_character_id != "necromancer":
		return
	active_minions = active_minions.filter(func(m): return is_instance_valid(m))
	if active_minions.size() >= MAX_MINIONS:
		return
	if randf() < 0.30 and global_position.distance_to(enemy_pos) <= 380.0:
		var target_parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
		var skel = minion_scene.instantiate()
		skel.global_position = enemy_pos
		target_parent.call_deferred("add_child", skel)
		active_minions.append(skel)
