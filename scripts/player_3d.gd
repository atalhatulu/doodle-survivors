extends CharacterBody3D

signal health_changed(current: float, max_h: float)
signal level_up(new_lvl: int)
signal xp_changed(cur_xp: int, next_xp: int, cur_lvl: int)
signal coins_changed(tot: int, run_c: int)
signal dash_cooldown_updated(remaining: float, total: float)
signal player_died()

@export var move_speed: float = 7.5
@export var max_health: float = 125.0
@export var attack_interval: float = 0.45

@onready var sprite: Sprite3D = $Sprite3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var projectiles_node: Node3D = $Projectiles3D
@onready var weapon_slots_node: Node3D = get_node_or_null("OrbitingWeaponSlots")

var current_health: float = 125.0
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 25
var coins_in_run: int = 0
var total_coins: int = 0

var is_dead: bool = false
var facing_dir: Vector3 = Vector3.FORWARD
var attack_timer: float = 0.0

# 6 Döner Silah Slotu (Orbiting Weapons) & Envanter
var weapon_orbit_angle: float = 0.0
var weapon_orbit_speed: float = 2.4 # Radyan/sn
var owned_weapons: Dictionary = {}
var owned_passives: Dictionary = {}

# Savaş, Karakter ve Meta İstatistikleri (19 Pasif Eşya ile %100 Uyumlu)
var damage_multiplier: float = 1.0
var armor: float = 0.0
var crit_chance: float = 0.05
var base_crit_chance: float = 0.05
var luck_mult: float = 1.0
var magnet_range_mult: float = 1.0
var hp_regen: float = 0.0
var cooldown_mult: float = 1.0
var area_mult: float = 1.0
var projectile_speed_mult: float = 1.0
var extra_projectiles: int = 0
var duration_mult: float = 1.0
var xp_multiplier: float = 1.0
var gold_multiplier: float = 1.0
var revives_remaining: int = 0
var invulnerability_duration: float = 0.35
var invulnerability_timer: float = 0.0
var curse_mult: float = 1.0
var frenzy_gold_bonus: float = 1.0

# Dash / Dodge Roll
var dash_cooldown: float = 1.6
var dash_timer: float = 0.0
var is_dashing: bool = false
var dash_duration: float = 0.22
var dash_elapsed: float = 0.0
var dash_vector: Vector3 = Vector3.ZERO
var dash_ghost_timer: float = 0.0

# Kontrollü Kamera Sarsıntısı (Screen Shake)
var trauma: float = 0.0
var trauma_power: float = 2.0
var max_shake_offset: float = 0.28
var max_shake_roll: float = 0.04

# Fare ile Doğrudan TPS Kamera Hareketi (MouseX & MouseY)
var mouse_sensitivity: float = 0.0025
var camera_pitch: float = deg_to_rad(-22.0) # Varsayılan arkadan yukarı bakış (-22°)

# Kamera Zoom Sınırları (Mouse Wheel)
var target_zoom: float = 9.5
const MIN_ZOOM: float = 3.5
const MAX_ZOOM: float = 16.0

# Kamera Dikey Açı Sınırları
var min_pitch_rad: float = deg_to_rad(-75.0)
var max_pitch_rad: float = deg_to_rad(-4.0)

# 14 Silah ve 5 Evrim Silahının Tam 3D Mermi & Atış Konfigürasyonu
const WEAPON_CONFIGS: Dictionary = {
	"weapon_sword": {
		"proj_tex": "res://assets/sprites/weapons/proj_sword_heavy_slash.png",
		"damage": 55.0,
		"speed": 0.0,
		"interval": 0.85,
		"scale": 0.0075,
		"spin": 0.0,
		"pierce": 99,
		"lifetime": 0.30,
		"behavior": "melee_arc",
		"sfx": "pencil_slash"
	},
	"weapon_bow": {
		"proj_tex": "res://assets/sprites/weapons/proj_arrow.png",
		"damage": 35.0,
		"speed": 34.0,
		"interval": 0.95,
		"scale": 0.0052,
		"spin": 0.0,
		"pierce": 1,
		"lifetime": 2.2,
		"behavior": "targeted",
		"sfx": "shoot"
	},
	"weapon_staff": {
		"proj_tex": "res://assets/sprites/weapons/proj_orb.png",
		"damage": 65.0,
		"speed": 18.0,
		"interval": 1.60,
		"scale": 0.0068,
		"spin": 8.0,
		"pierce": 2,
		"lifetime": 2.5,
		"behavior": "targeted",
		"sfx": "shoot"
	},
	"weapon_axe": {
		"proj_tex": "res://assets/sprites/weapons/proj_axe_head.png",
		"damage": 75.0,
		"speed": 20.0,
		"interval": 1.85,
		"scale": 0.0075,
		"spin": 25.0,
		"pierce": 4,
		"lifetime": 1.4,
		"behavior": "parabolic_lob",
		"sfx": "axe_throw"
	},
	"weapon_dagger": {
		"proj_tex": "res://assets/sprites/weapons/proj_dagger.png",
		"damage": 25.0,
		"speed": 36.0,
		"interval": 0.65,
		"scale": 0.0048,
		"spin": 0.0,
		"pierce": 1,
		"lifetime": 1.5,
		"behavior": "targeted",
		"sfx": "shoot"
	},
	"weapon_potion": {
		"proj_tex": "res://assets/sprites/weapons/proj_potion.png",
		"damage": 50.0,
		"speed": 18.0,
		"interval": 1.60,
		"scale": 0.007,
		"spin": 14.0,
		"pierce": 99,
		"lifetime": 1.3,
		"behavior": "parabolic_lob",
		"sfx": "shoot"
	},
	"weapon_boomerang": {
		"proj_tex": "res://assets/sprites/weapons/proj_boomerang.png",
		"damage": 45.0,
		"speed": 22.0,
		"interval": 1.30,
		"scale": 0.0065,
		"spin": 30.0,
		"pierce": 6,
		"lifetime": 2.6,
		"behavior": "boomerang",
		"sfx": "axe_throw"
	},
	"weapon_spellbook": {
		"proj_tex": "res://assets/sprites/weapons/proj_rune.png",
		"damage": 30.0,
		"speed": 15.0,
		"interval": 0.85,
		"scale": 0.0055,
		"spin": 12.0,
		"pierce": 3,
		"lifetime": 2.4,
		"behavior": "radial",
		"sfx": "shoot"
	},
	"weapon_aura": {
		"proj_tex": "res://assets/sprites/weapons/weapon_aura.png",
		"damage": 50.0,
		"speed": 0.0,
		"interval": 1.10,
		"scale": 0.0065,
		"spin": 3.0,
		"pierce": 99,
		"lifetime": 0.8,
		"behavior": "area_blast",
		"sfx": "pencil_slash"
	},
	"weapon_lightning": {
		"proj_tex": "res://assets/sprites/weapons/proj_lightning_bolt.png",
		"damage": 85.0,
		"speed": 55.0,
		"interval": 1.70,
		"scale": 0.0085,
		"spin": 0.0,
		"pierce": 1,
		"lifetime": 0.4,
		"behavior": "sky_strike",
		"sfx": "shoot"
	},
	"weapon_dragon_breath": {
		"proj_tex": "res://assets/sprites/weapons/proj_flamethrower_stream.png",
		"damage": 32.0,
		"speed": 28.0,
		"interval": 0.35,
		"scale": 0.0068,
		"spin": 6.0,
		"pierce": 2,
		"lifetime": 1.2,
		"behavior": "facing_flame",
		"sfx": "shoot"
	},
	"weapon_void_vortex": {
		"proj_tex": "res://assets/sprites/weapons/proj_void_swirl.png",
		"damage": 65.0,
		"speed": 12.0,
		"interval": 2.20,
		"scale": 0.009,
		"spin": 22.0,
		"pierce": 15,
		"lifetime": 3.2,
		"behavior": "vortex",
		"sfx": "shoot"
	},
	"weapon_spirit_wolf": {
		"proj_tex": "res://assets/sprites/weapons/spirit_wolf.png",
		"damage": 42.0,
		"speed": 26.0,
		"interval": 1.35,
		"scale": 0.006,
		"spin": 0.0,
		"pierce": 3,
		"lifetime": 2.5,
		"behavior": "targeted",
		"sfx": "shoot"
	},
	"weapon_earthquake": {
		"proj_tex": "res://assets/sprites/weapons/weapon_earthquake.png",
		"damage": 95.0,
		"speed": 0.0,
		"interval": 2.20,
		"scale": 0.0065,
		"spin": 0.0,
		"pierce": 99,
		"lifetime": 0.75,
		"behavior": "area_blast",
		"sfx": "hit"
	},
	# 5 Efsanevi Evrim Silahı
	"weapon_evo_divine_sun": {
		"proj_tex": "res://assets/sprites/weapons/weapon_evo_divine_sun.png",
		"damage": 110.0,
		"speed": 0.0,
		"interval": 0.85,
		"scale": 0.0075,
		"spin": 4.0,
		"pierce": 99,
		"lifetime": 0.85,
		"behavior": "area_blast",
		"sfx": "level_up"
	},
	"weapon_evo_hellfire_storm": {
		"proj_tex": "res://assets/sprites/weapons/weapon_evo_hellfire_storm.png",
		"damage": 65.0,
		"speed": 30.0,
		"interval": 0.28,
		"scale": 0.009,
		"spin": 12.0,
		"pierce": 4,
		"lifetime": 1.8,
		"behavior": "facing_flame",
		"sfx": "shoot"
	},
	"weapon_evo_king_cleaver": {
		"proj_tex": "res://assets/sprites/weapons/weapon_evo_king_cleaver.png",
		"damage": 140.0,
		"speed": 26.0,
		"interval": 1.25,
		"scale": 0.010,
		"spin": 22.0,
		"pierce": 8,
		"lifetime": 2.2,
		"behavior": "targeted",
		"sfx": "axe_throw"
	},
	"weapon_evo_storm_quiver": {
		"proj_tex": "res://assets/sprites/weapons/weapon_evo_storm_quiver.png",
		"damage": 75.0,
		"speed": 42.0,
		"interval": 0.55,
		"scale": 0.007,
		"spin": 0.0,
		"pierce": 3,
		"lifetime": 2.4,
		"behavior": "targeted",
		"sfx": "shoot"
	},
	"weapon_evo_cosmic_archon": {
		"proj_tex": "res://assets/sprites/weapons/weapon_evo_cosmic_archon.png",
		"damage": 130.0,
		"speed": 22.0,
		"interval": 1.10,
		"scale": 0.011,
		"spin": 15.0,
		"pierce": 6,
		"lifetime": 3.0,
		"behavior": "targeted",
		"sfx": "shoot"
	}
}

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	
	# Fare imlecini pencereye kilitle (TPS kamera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Meta progression ve karakter seçimini yükle
	_apply_character_and_meta()
	
	# Başlangıç silahı ile slotları başlat
	_init_default_weapons()
	
	# Sihirbaz/karakter etrafında parıldayan büyü aurası parçacıkları
	_setup_player_aura()
	
	if spring_arm:
		spring_arm.rotation.x = camera_pitch
	
	call_deferred("_emit_initial_hud")

func _setup_player_aura() -> void:
	var aura_particles := CPUParticles3D.new()
	aura_particles.name = "ArcaneAuraParticles"
	aura_particles.amount = 26
	aura_particles.lifetime = 1.2
	aura_particles.randomness = 0.3
	aura_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	aura_particles.emission_sphere_radius = 0.75
	aura_particles.gravity = Vector3(0, 0.85, 0)
	aura_particles.initial_velocity_min = 0.2
	aura_particles.initial_velocity_max = 0.6
	aura_particles.scale_amount_min = 0.12
	aura_particles.scale_amount_max = 0.32
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var spark_tex = load("res://assets/sprites/particles/particle_spark_soft.png")
	if spark_tex:
		mat.albedo_texture = spark_tex
	aura_particles.material_override = mat
	
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.24, 0.24)
	aura_particles.mesh = mesh
	
	var grad := Gradient.new()
	grad.set_color(0, Color(0.65, 0.3, 0.95, 0.0))
	grad.add_point(0.25, Color(0.85, 0.5, 1.0, 0.9))
	grad.add_point(0.7, Color(0.4, 0.9, 1.0, 0.8))
	grad.set_color(grad.get_point_count() - 1, Color(0.2, 0.9, 0.6, 0.0))
	aura_particles.color_ramp = grad
	
	aura_particles.position = Vector3(0, 0.9, 0)
	add_child(aura_particles)

func _apply_character_and_meta() -> void:
	var meta = get_node_or_null("/root/MetaProgression")
	if not meta:
		return
		
	total_coins = meta.total_coins
	var char_id: String = meta.selected_character_id if "selected_character_id" in meta else "knight"
	if meta.CHARACTERS.has(char_id):
		var c_data: Dictionary = meta.CHARACTERS[char_id]
		# Karakter portresini Sprite3D'ye aktar
		var p_tex: Texture2D = load(c_data.get("portrait", ""))
		if p_tex and sprite:
			sprite.texture = p_tex
			
		# 5 Karakterin Başlangıç Stat Modları (Knight, Mage, Ranger, Alchemist, Necromancer)
		var stat_mods: Dictionary = c_data.get("stat_mods", {})
		if stat_mods.has("max_health"):
			max_health += float(stat_mods["max_health"])
			current_health = max_health
		if stat_mods.has("armor"):
			armor += float(stat_mods["armor"])
		if stat_mods.has("move_speed_mult"):
			move_speed *= float(stat_mods["move_speed_mult"])
		if stat_mods.has("area_mult"):
			area_mult *= float(stat_mods["area_mult"])
		if stat_mods.has("cooldown_mult"):
			cooldown_mult *= float(stat_mods["cooldown_mult"])
		if stat_mods.has("luck"):
			luck_mult += float(stat_mods["luck"])
			crit_chance = minf(1.0, base_crit_chance + (luck_mult - 1.0) * 0.4)
		if stat_mods.has("projectile_speed_mult"):
			projectile_speed_mult *= float(stat_mods["projectile_speed_mult"])
		if stat_mods.has("duration_mult"):
			duration_mult *= float(stat_mods["duration_mult"])
		if stat_mods.has("extra_projectiles"):
			extra_projectiles += int(stat_mods["extra_projectiles"])
		if stat_mods.has("hp_regen"):
			hp_regen += float(stat_mods["hp_regen"])
		if stat_mods.has("xp_multiplier"):
			xp_multiplier *= float(stat_mods["xp_multiplier"])
			
	# Kalıcı atölye yükseltmelerini (Sağlık, Hasar, Hız, Mıknatıs, Kritik, Zırh) uygula
	meta.apply_to_player(self)

func _init_default_weapons() -> void:
	var meta = get_node_or_null("/root/MetaProgression")
	var char_id: String = meta.selected_character_id if (meta and "selected_character_id" in meta) else "knight"
	var starting_weapon := "weapon_sword"
	if meta and meta.CHARACTERS.has(char_id):
		starting_weapon = meta.CHARACTERS[char_id].get("weapon_id", "weapon_sword")
		
	add_weapon(starting_weapon)

func has_weapon(w_id: String) -> bool:
	return owned_weapons.has(w_id)

func get_weapon_level(w_id: String) -> int:
	if owned_weapons.has(w_id):
		return owned_weapons[w_id].get("level", 1)
	return 0

func has_free_weapon_slot() -> bool:
	return owned_weapons.keys().size() < 6

func has_passive(p_id: String) -> bool:
	return owned_passives.has(p_id)

func get_passive_level(p_id: String) -> int:
	return owned_passives.get(p_id, 0)

func has_free_passive_slot() -> bool:
	return owned_passives.keys().size() < 6

func add_weapon(weapon_id: String) -> bool:
	if owned_weapons.has(weapon_id):
		owned_weapons[weapon_id]["level"] += 1
		_recalculate_weapon_stats()
		return true
		
	var current_count = owned_weapons.keys().size()
	if current_count >= 6:
		return false
		
	var w_icon = "res://assets/sprites/weapons/%s.png" % weapon_id
	owned_weapons[weapon_id] = {
		"id": weapon_id,
		"level": 1,
		"icon": w_icon,
		"slot_index": current_count,
		"cooldown_timer": randf_range(0.0, 0.4)
	}
	_update_orbit_weapon_visuals()
	_recalculate_weapon_stats()
	return true

func add_passive(passive_id: String, stat_name: String, value: float) -> void:
	owned_passives[passive_id] = owned_passives.get(passive_id, 0) + 1
	_apply_passive_stat(stat_name, value, passive_id)

# 19 Pasif Eşyanın Bütün Statlarını Eksiksiz Uygulayan Fonksiyon
func _apply_passive_stat(stat_name: String, value: float, passive_id: String = "") -> void:
	match stat_name:
		"move_speed":
			move_speed *= value
		"max_health":
			var old_max = max_health
			max_health += value
			current_health = minf(max_health, current_health + value)
			emit_signal("health_changed", current_health, max_health)
		"damage_mult", "damage":
			damage_multiplier *= value
		"cooldown_mult", "cooldown":
			cooldown_mult = maxf(0.25, cooldown_mult * value)
			attack_interval = maxf(0.10, attack_interval * value)
		"area_mult":
			area_mult *= value
		"armor":
			armor = minf(0.70, armor + value)
		"crit_chance", "luck":
			luck_mult += value
			crit_chance = minf(1.0, base_crit_chance + (luck_mult - 1.0) * 0.4)
		"magnet_range":
			magnet_range_mult *= value
		"extra_projectiles":
			extra_projectiles = mini(2, extra_projectiles + int(value))
		"hp_regen":
			hp_regen += value
		"projectile_speed":
			projectile_speed_mult *= value
		"duration":
			duration_mult *= value
		"xp_mult":
			xp_multiplier *= value
		"gold_mult":
			gold_multiplier *= value
		"revive":
			revives_remaining = mini(2, revives_remaining + int(value))
		"invulnerability":
			invulnerability_duration += value
		"curse":
			curse_mult *= 1.10
			xp_multiplier *= 1.15
			gold_multiplier *= 1.15
		"torrona":
			var lvl: int = owned_passives.get(passive_id, 1)
			if lvl == 5:
				curse_mult *= 1.25
				xp_multiplier *= 1.25
			else:
				damage_multiplier *= 1.05
				projectile_speed_mult *= 1.05
				area_mult *= 1.05
				duration_mult *= 1.05
		"sharpener":
			curse_mult *= 1.12
			frenzy_gold_bonus *= 1.35
		"orbit_speed":
			weapon_orbit_speed *= value

func _recalculate_weapon_stats() -> void:
	var total_lvls: int = 0
	for w in owned_weapons.values():
		total_lvls += int(w.get("level", 1))
	weapon_orbit_speed = 2.4 + float(total_lvls - 1) * 0.18

func _update_orbit_weapon_visuals() -> void:
	if not weapon_slots_node:
		return
		
	var w_keys = owned_weapons.keys()
	for i in range(6):
		var slot = weapon_slots_node.get_node_or_null("Slot%d" % i)
		if not slot:
			continue
			
		for c in slot.get_children():
			c.queue_free()
			
		if i < w_keys.size():
			var w_id = w_keys[i]
			var icon_path: String = owned_weapons[w_id].get("icon", "res://assets/sprites/weapons/weapon_sword.png")
			var tex: Texture2D = load(icon_path)
			if tex:
				var w_sprite := Sprite3D.new()
				w_sprite.texture = tex
				w_sprite.pixel_size = 0.0042
				w_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				w_sprite.double_sided = true
				w_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
				slot.add_child(w_sprite)

func apply_upgrade(upgrade_data: Dictionary) -> void:
	var up_type: String = upgrade_data.get("type", "")
	var up_id: String = upgrade_data.get("id", "")
	
	if up_type == "evolution":
		var base_id: String = upgrade_data.get("base_weapon_id", "")
		evolve_weapon(base_id, upgrade_data)
	elif up_type == "weapon":
		add_weapon(up_id)
	elif up_type == "stat" or up_type == "passive":
		var stat_name: String = upgrade_data.get("stat", "")
		var val: float = float(upgrade_data.get("value", 1.1))
		add_passive(up_id, stat_name, val)
	elif up_type == "consumable":
		var stat_name: String = upgrade_data.get("stat", "")
		if stat_name == "heal":
			current_health = minf(max_health, current_health + float(upgrade_data.get("value", 35.0)))
		elif stat_name == "gold":
			add_coin(int(upgrade_data.get("value", 50)))
		else:
			current_health = minf(max_health, current_health + max_health * 0.4)
		emit_signal("health_changed", current_health, max_health)

func evolve_weapon(base_id: String, evo_data: Dictionary) -> bool:
	var evo_id: String = evo_data.get("id", "")
	if owned_weapons.has(base_id):
		var old_slot: int = int(owned_weapons[base_id].get("slot_index", 0))
		owned_weapons.erase(base_id)
		var evo_icon: String = evo_data.get("icon", "res://assets/sprites/weapons/%s.png" % evo_id)
		owned_weapons[evo_id] = {
			"id": evo_id,
			"level": 1,
			"icon": evo_icon,
			"slot_index": old_slot,
			"cooldown_timer": 0.0
		}
		_update_orbit_weapon_visuals()
		_recalculate_weapon_stats()
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_sfx("level_up", 0.05, 1.2)
		return true
	return false

func _emit_initial_hud() -> void:
	emit_signal("health_changed", current_health, max_health)
	emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)
	emit_signal("coins_changed", total_coins, coins_in_run)
	emit_signal("dash_cooldown_updated", 0.0, dash_cooldown)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
		
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pitch = clampf(camera_pitch - event.relative.y * mouse_sensitivity, min_pitch_rad, max_pitch_rad)
		if spring_arm:
			spring_arm.rotation.x = camera_pitch

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clampf(target_zoom - 0.85, MIN_ZOOM, MAX_ZOOM)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clampf(target_zoom + 0.85, MIN_ZOOM, MAX_ZOOM)
			
	if event.is_action_pressed("dash") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		_trigger_dash()
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_fire_primary_attack()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	dash_timer -= delta
	attack_timer += delta
	invulnerability_timer -= delta
	
	# Pasif Can Yenilenmesi (HP Regen)
	if hp_regen > 0.0 and current_health < max_health:
		current_health = minf(max_health, current_health + hp_regen * delta)
		emit_signal("health_changed", current_health, max_health)
	
	# Kamera mesafesini akıcı şekilde zoom hedefine yaklaştır ve Shake uygula
	if spring_arm:
		spring_arm.spring_length = lerpf(spring_arm.spring_length, target_zoom, delta * 12.0)
		if camera:
			var cam_global_y = camera.global_position.y
			if cam_global_y < 0.6:
				spring_arm.spring_length = maxf(1.8, spring_arm.spring_length - (0.6 - cam_global_y) * 2.0)
			# Kontrollü Kamera Titremesi (Trauma decay)
			if trauma > 0.0:
				trauma = maxf(0.0, trauma - delta * 2.8)
				var shake_amount = pow(trauma, trauma_power)
				camera.h_offset = randf_range(-max_shake_offset, max_shake_offset) * shake_amount
				camera.v_offset = randf_range(-max_shake_offset, max_shake_offset) * shake_amount
				camera.rotation.z = randf_range(-max_shake_roll, max_shake_roll) * shake_amount
			else:
				camera.h_offset = 0.0
				camera.v_offset = 0.0
				camera.rotation.z = 0.0

	# Karakterin ve silah slotlarının yer altına düşmesini kesin olarak engelle
	if position.y < 0.0:
		position.y = 0.0
		velocity.y = 0.0
		
	# 6 Adet Silah Slotunu Karakterin Etrafında 360 Derece Döndür
	if weapon_slots_node:
		weapon_orbit_angle += delta * weapon_orbit_speed
		if weapon_orbit_angle >= TAU:
			weapon_orbit_angle -= TAU
		weapon_slots_node.rotation.y = weapon_orbit_angle
		weapon_slots_node.position.y = maxf(0.9, 1.1 + sin(weapon_orbit_angle * 2.0) * 0.08)
	
	# Her silahın kendi bekleme süresini işlet ve ateşle
	for w_id in owned_weapons.keys():
		var w_data: Dictionary = owned_weapons[w_id]
		var cfg: Dictionary = WEAPON_CONFIGS.get(w_id, WEAPON_CONFIGS["weapon_sword"])
		var base_interval: float = cfg.get("interval", 0.5)
		var lvl: int = int(w_data.get("level", 1))
		var actual_interval: float = maxf(0.10, base_interval * pow(0.92, lvl - 1) * cooldown_mult)
		
		w_data["cooldown_timer"] = float(w_data.get("cooldown_timer", 0.0)) + delta
		if w_data["cooldown_timer"] >= actual_interval:
			w_data["cooldown_timer"] = 0.0
			_fire_weapon(w_id, w_data, cfg)

	# Dash durumu
	if is_dashing:
		dash_elapsed += delta
		dash_ghost_timer += delta
		if dash_ghost_timer >= 0.05:
			dash_ghost_timer = 0.0
			_spawn_dash_ghost()
		velocity = dash_vector * (move_speed * 2.8)
		if sprite:
			sprite.rotation.z = PI * 0.25
		if dash_elapsed >= dash_duration:
			is_dashing = false
			if sprite:
				sprite.rotation.z = 0.0
	else:
		# Standart WASD hareketi
		var input_dir := Vector3.ZERO
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			input_dir.z -= 1.0
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			input_dir.z += 1.0
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
			input_dir.x -= 1.0
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
			input_dir.x += 1.0

		if input_dir.length_squared() > 0.01:
			input_dir = input_dir.normalized()
			var cam_rot_y := 0.0
			if camera:
				cam_rot_y = camera.global_rotation.y
			var move_dir := input_dir.rotated(Vector3.UP, cam_rot_y)
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
			
			facing_dir = move_dir
			if sprite:
				if move_dir.x < -0.1:
					sprite.flip_h = true
				elif move_dir.x > 0.1:
					sprite.flip_h = false
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
			if camera:
				var cam_fwd = -camera.global_transform.basis.z
				cam_fwd.y = 0.0
				if cam_fwd.length_squared() > 0.001:
					facing_dir = cam_fwd.normalized()

	move_and_slide()
	_update_camera_obstacles_transparency()

func _update_camera_obstacles_transparency() -> void:
	if not camera:
		return
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return
		
	var cam_pos = camera.global_position
	var player_target = global_position + Vector3(0, 1.2, 0)
	
	# Kamera ile oyuncu arasındaki hattı tara
	var blocked_nodes: Array[Node] = []
	var query = PhysicsRayQueryParameters3D.create(cam_pos, player_target)
	query.collision_mask = 1 # Environment / obstacle layer
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	# Raycast ile aradaki engelleri bul
	for i in range(4): # En fazla 4 katmanlı engel kontrolü
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			break
		var collider = result.get("collider")
		if collider:
			blocked_nodes.append(collider)
			query.exclude = query.exclude + [result.get("rid")]
		else:
			break
			
	# Kamera engel grubundaki tüm nesnelerin saydamlığını güncelle
	var fading_obstacles = get_tree().get_nodes_in_group("camera_fading_obstacles")
	for obs in fading_obstacles:
		if not is_instance_valid(obs):
			continue
		if blocked_nodes.has(obs):
			if obs.has_method("set_obstacle_alpha"):
				obs.set_obstacle_alpha(0.25)
		else:
			if obs.has_method("set_obstacle_alpha"):
				obs.set_obstacle_alpha(1.0)

func shake_camera(amount: float = 0.25, max_t: float = 0.6) -> void:
	trauma = clampf(trauma + amount, 0.0, max_t)

func _spawn_dash_ghost() -> void:
	if not sprite or not sprite.texture:
		return
	var ghost := Sprite3D.new()
	ghost.texture = sprite.texture
	ghost.pixel_size = sprite.pixel_size
	ghost.billboard = sprite.billboard
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(0.4, 0.8, 1.2, 0.65)
	ghost.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	ghost.global_position = sprite.global_position
	ghost.rotation = sprite.rotation
	get_parent().add_child(ghost)
	
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tw.tween_property(ghost, "scale", Vector3(1.15, 1.15, 1.15), 0.22)
	tw.tween_callback(ghost.queue_free)

func _trigger_dash() -> void:
	if dash_timer <= 0.0 and not is_dashing:
		is_dashing = true
		dash_timer = dash_cooldown
		dash_elapsed = 0.0
		dash_ghost_timer = 0.0
		dash_vector = facing_dir.normalized()
		shake_camera(0.12, 0.3)
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_sfx("dash", 0.05, 1.2)

func _fire_weapon(weapon_id: String, weapon_data: Dictionary, config: Dictionary) -> void:
	var nearest = _find_nearest_enemy()
	var behavior: String = config.get("behavior", "targeted")
	
	# Merminin çıkış noktası: Silahın karakter etrafında döndüğü gerçek 3D konum
	var spawn_origin: Vector3 = global_position + Vector3(0, 1.1, 0)
	var slot_idx: int = int(weapon_data.get("slot_index", 0))
	var slot_marker: Node3D = null
	if weapon_slots_node:
		slot_marker = weapon_slots_node.get_node_or_null("Slot%d" % slot_idx)
		if slot_marker:
			spawn_origin = slot_marker.global_position
			
	var dir := facing_dir
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
	else:
		dir = Vector3.FORWARD
		
	if behavior == "facing_flame":
		var spread_angle := randf_range(-0.18, 0.18)
		dir = dir.rotated(Vector3.UP, spread_angle)
	elif behavior == "area_blast":
		dir = Vector3.ZERO
		spawn_origin = global_position + Vector3(0, 0.4, 0)
	elif behavior == "sky_strike":
		if nearest and is_instance_valid(nearest):
			spawn_origin = nearest.global_position + Vector3(0, 7.0, 0)
			dir = Vector3.DOWN
		else:
			return
	elif behavior == "radial":
		dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	else:
		if nearest and is_instance_valid(nearest):
			var target_pos = nearest.global_position
			target_pos.y = spawn_origin.y
			var diff = target_pos - spawn_origin
			if diff.length_squared() > 0.001:
				dir = diff.normalized()

	# Yerden çıkış yüksekliğini güvenli seviyede tut (yerin dibine batmasın)
	if behavior != "sky_strike":
		spawn_origin.y = maxf(0.65, spawn_origin.y)
		
	var lvl: int = int(weapon_data.get("level", 1))
	var base_dmg: float = config.get("damage", 40.0)
	var final_damage: float = base_dmg * (1.0 + float(lvl - 1) * 0.35) * damage_multiplier
	
	if randf() < crit_chance:
		final_damage *= 2.0
		
	var p_speed: float = config.get("speed", 24.0) * projectile_speed_mult
	var p_tex: String = config.get("proj_tex", "res://assets/sprites/weapons/proj_sword.png")
	var p_scale: float = config.get("scale", 0.0055) * area_mult
	var p_spin: float = config.get("spin", 15.0)
	var p_pierce: int = int(config.get("pierce", 1))
	var p_lifetime: float = float(config.get("lifetime", 2.0)) * duration_mult
	var is_blast: bool = (behavior == "area_blast")
	var sfx_name: String = config.get("sfx", "slash")
	
	# Çoklu mermi (extra_projectiles) desteği
	var shots: int = 1
	var is_single_shot_behavior = (behavior == "area_blast" or behavior == "melee_arc" or behavior == "vortex")
	if not is_single_shot_behavior:
		shots += extra_projectiles
		
	var target_dest_pos = Vector3.ZERO
	if nearest and is_instance_valid(nearest):
		target_dest_pos = nearest.global_position
		target_dest_pos.y = 0.35
	else:
		target_dest_pos = spawn_origin + dir * 10.0
	if slot_marker:
		_trigger_slot_kickback(slot_marker)
		
	for s in range(shots):
		var shot_dir := dir
		if shots > 1 and not is_single_shot_behavior and behavior != "sky_strike":
			var spread = (float(s) - float(shots - 1) * 0.5) * 0.14
			shot_dir = dir.rotated(Vector3.UP, spread)
		_spawn_weapon_projectile(spawn_origin, shot_dir, final_damage, p_speed, p_tex, p_scale, p_spin, p_pierce, p_lifetime, is_blast, sfx_name, behavior, target_dest_pos)

func _fire_primary_attack() -> void:
	if owned_weapons.is_empty():
		return
	var first_id: String = owned_weapons.keys()[0]
	var w_data: Dictionary = owned_weapons[first_id]
	var cfg: Dictionary = WEAPON_CONFIGS.get(first_id, WEAPON_CONFIGS["weapon_sword"])
	var base_dmg: float = cfg.get("damage", 40.0) * damage_multiplier
	var spawn_origin: Vector3 = global_position + Vector3(0, 1.1, 0)
	if weapon_slots_node:
		var slot_marker = weapon_slots_node.get_node_or_null("Slot0")
		if slot_marker:
			spawn_origin = slot_marker.global_position
			_trigger_slot_kickback(slot_marker)
	spawn_origin.y = maxf(0.65, spawn_origin.y)
	
	var shot_dir = facing_dir
	shot_dir.y = 0.0
	if shot_dir.length_squared() > 0.001:
		shot_dir = shot_dir.normalized()
	else:
		shot_dir = Vector3.FORWARD
		
	var prim_behavior: String = cfg.get("behavior", "targeted")
	_spawn_weapon_projectile(
		spawn_origin,
		shot_dir,
		base_dmg,
		cfg.get("speed", 24.0) * projectile_speed_mult,
		cfg.get("proj_tex", ""),
		cfg.get("scale", 0.0055) * area_mult,
		cfg.get("spin", 15.0),
		int(cfg.get("pierce", 1)),
		float(cfg.get("lifetime", 2.0)) * duration_mult,
		(prim_behavior == "area_blast"),
		cfg.get("sfx", "slash"),
		prim_behavior,
		spawn_origin + shot_dir * 10.0
	)

func _spawn_weapon_projectile(
	origin: Vector3,
	dir: Vector3,
	dmg: float,
	spd: float,
	tex_path: String,
	sc: float,
	spin: float,
	pierce: int = 1,
	life: float = 2.0,
	is_blast: bool = false,
	sfx: String = "slash",
	p_behavior: String = "targeted",
	dest_pos: Vector3 = Vector3.ZERO
) -> void:
	var proj_scene := load("res://scenes/weapons/proj_blade_3d.tscn")
	if not proj_scene:
		return
	var proj = proj_scene.instantiate()
	proj.position = origin
	proj.configure(dir, dmg, spd, tex_path, sc, spin, pierce, life, is_blast, p_behavior, self, dest_pos)
	get_parent().add_child(proj)
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx(sfx, 0.05, 1.0)

func _trigger_slot_kickback(slot_marker: Node3D) -> void:
	if not slot_marker:
		return
		
	if not slot_marker.has_meta("orig_local_pos"):
		slot_marker.set_meta("orig_local_pos", slot_marker.position)
	var orig_pos: Vector3 = slot_marker.get_meta("orig_local_pos")
	
	# Devam eden önceki kickback tween varsa temizle
	if slot_marker.has_meta("kickback_tween"):
		var prev_tw = slot_marker.get_meta("kickback_tween")
		if prev_tw and is_instance_valid(prev_tw) and prev_tw.is_valid():
			prev_tw.kill()
			slot_marker.position = orig_pos
			slot_marker.scale = Vector3.ONE
		
	var outward = orig_pos.normalized() if orig_pos.length_squared() > 0.01 else Vector3.RIGHT
	var kick_pos = orig_pos - outward * 0.32
	
	var tw = slot_marker.create_tween()
	slot_marker.set_meta("kickback_tween", tw)
	
	# 1. Aşama: Anlık geriye tepme ve scale * 1.25 büyümesi (0.04s)
	tw.set_parallel(true)
	tw.tween_property(slot_marker, "scale", Vector3(1.25, 1.25, 1.25), 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(slot_marker, "position", kick_pos, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Aşama: 0.12 saniyede geri sıçrayarak yerine oturma (TRANS_BACK)
	tw.chain().set_parallel(true)
	tw.tween_property(slot_marker, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(slot_marker, "position", orig_pos, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Ateş anında slot ucunda hafif parlama (Muzzle Flash Sprite)
	var flash = Sprite3D.new()
	flash.texture = load("res://assets/sprites/particles/particle_spark_soft.png")
	flash.pixel_size = 0.007
	flash.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flash.modulate = Color(1.0, 0.95, 0.6, 1.0)
	flash.position = outward * 0.35
	slot_marker.add_child(flash)
	
	var tw_flash = flash.create_tween()
	tw_flash.set_parallel(true)
	tw_flash.tween_property(flash, "scale", Vector3(1.6, 1.6, 1.6), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_flash.tween_property(flash, "modulate:a", 0.0, 0.08)
	tw_flash.chain().tween_callback(flash.queue_free)

func _find_nearest_enemy() -> Node3D:
	var tree = get_tree()
	if not tree: return null
	var enemies = tree.get_nodes_in_group("enemies")
	var nearest: Node3D = null
	var min_dist_sq := 999999.0
	for e in enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			continue
		if e.get("is_broken") == true or e.get("is_dead") == true:
			continue
		var d = global_position.distance_squared_to(e.global_position)
		if d < min_dist_sq:
			min_dist_sq = d
			nearest = e
	return nearest

func take_damage(amount: float) -> void:
	if is_dead or is_dashing or invulnerability_timer > 0.0:
		return
		
	# Zırh koruması
	var reduced = maxf(1.0, amount * (1.0 - armor))
	current_health = maxf(0.0, current_health - reduced)
	invulnerability_timer = invulnerability_duration
	emit_signal("health_changed", current_health, max_health)
	
	# Hasar flaşı
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color.RED, 0.1)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)
		
	if current_health <= 0.0:
		if revives_remaining > 0:
			_revive()
		else:
			_die()

func _revive() -> void:
	revives_remaining -= 1
	current_health = max_health * 0.5
	invulnerability_timer = 2.0 # 2sn tam dokunulmazlık
	emit_signal("health_changed", current_health, max_health)
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("level_up", 0.05, 1.3)
	# Etraftaki düşmanları savuracak dirilme şok dalgası
	var cfg = WEAPON_CONFIGS["weapon_earthquake"]
	_spawn_weapon_projectile(global_position + Vector3(0, 0.4, 0), Vector3.ZERO, 100.0, 0.0, cfg.get("proj_tex", ""), 0.007, 0.0, 99, 0.7, true, "hit")

func _die() -> void:
	is_dead = true
	emit_signal("player_died")
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("game_over", 0.0, 1.0)

func add_xp(amount: int) -> void:
	if is_dead: return
	var bonus_amount: int = int(float(amount) * xp_multiplier)
	current_xp += bonus_amount
	if current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		xp_to_next_level = int(xp_to_next_level * 1.45 + 15)
		emit_signal("level_up", current_level)
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_sfx("level_up", 0.1, 1.0)
	emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

func add_coin(amount: int = 1) -> void:
	var bonus_coin: int = int(float(amount) * gold_multiplier * frenzy_gold_bonus)
	coins_in_run += bonus_coin
	total_coins += bonus_coin
	emit_signal("coins_changed", total_coins, coins_in_run)
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("coin", 0.05, 1.2)
