extends CharacterBody3D

signal boss_defeated()

@export var max_health: float = 35.0
@export var move_speed: float = 4.2
@export var contact_damage: float = 12.0
@export var xp_value: int = 15

@export var is_elite: bool = false
@export var is_boss: bool = false

@onready var sprite: Sprite3D = $Sprite3D

var current_health: float = 35.0
var player: Node3D = null
var wobble_timer: float = 0.0
var attack_cooldown_timer: float = 0.0

var damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number_3d.tscn")
var chest_scene: PackedScene = preload("res://scenes/pickups/chest_3d.tscn")

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")

func setup_elite(hp: float, dmg: float) -> void:
	is_elite = true
	max_health = hp
	current_health = hp
	contact_damage = dmg
	xp_value = 80

func setup_boss(hp: float, dmg: float) -> void:
	is_boss = true
	max_health = hp
	current_health = hp
	contact_damage = dmg
	xp_value = 350

var knockback_velocity: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	attack_cooldown_timer -= delta
	var to_player := (player.global_position - global_position)
	to_player.y = 0.0
	var dist := to_player.length()
	
	# Hafif Knockback sönümlenmesi
	if knockback_velocity.length_squared() > 0.01:
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, delta * 22.0)
	
	if dist > 1.2:
		var dir := to_player.normalized()
		velocity.x = dir.x * move_speed + knockback_velocity.x
		velocity.z = dir.z * move_speed + knockback_velocity.z
		
		# Kağıt yürüme salınımı (wobble)
		wobble_timer += delta * 10.0
		if sprite:
			sprite.rotation.z = sin(wobble_timer) * 0.08
			if dir.x < -0.1:
				sprite.flip_h = true
			elif dir.x > 0.1:
				sprite.flip_h = false
	else:
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		# Oyuncuya doğrudan temas vuruşu
		if attack_cooldown_timer <= 0.0:
			attack_cooldown_timer = 0.8
			if player.has_method("take_damage"):
				player.take_damage(contact_damage)
				var audio = get_node_or_null("/root/AudioManager")
				if audio:
					audio.play_sfx("hit", 0.05, 0.9)
			
	move_and_slide()

func take_damage(amount: float, source_dir: Vector3 = Vector3.ZERO) -> void:
	current_health -= amount
	
	var is_crit := (amount > contact_damage * 1.5)
	_spawn_damage_number(amount, is_crit)
	
	# Knockback: Boss'lar hafif, normal düşmanlar hissedilir şekilde geri savrulur
	if source_dir != Vector3.ZERO:
		var kb_strength: float = 3.2 if not is_boss else 0.8
		if is_crit:
			kb_strength *= 1.4
		knockback_velocity = source_dir.normalized() * kb_strength
		
	# Hit Flash: Hades tarzı beyaz/parlak vuruş tepkisi
	if sprite:
		var tw = create_tween()
		var flash_color = Color(3.5, 3.5, 3.5) if is_crit else Color(2.5, 2.5, 2.5)
		tw.tween_property(sprite, "modulate", flash_color, 0.07)
		tw.tween_property(sprite, "modulate", Color.WHITE if not is_elite else Color(1.3, 0.9, 0.4, 1.0), 0.12)
		
	# Impact Particles: Vuruş kıvılcımları
	_spawn_impact_particles(is_crit)
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		var pitch = 1.3 if is_crit else 1.05
		audio.play_sfx("hit", 0.05, pitch)
		
	# Kritik vuruşlarda kontrollü kamera sarsıntısı
	if is_crit and player and player.has_method("shake_camera"):
		player.shake_camera(0.18, 0.22)
		
	if current_health <= 0.0:
		_die()

static var _cached_impact_mat: StandardMaterial3D = null
static var _cached_impact_mesh: QuadMesh = null
static var _cached_impact_grad_crit: Gradient = null
static var _cached_impact_grad_normal: Gradient = null

func _spawn_impact_particles(is_crit: bool) -> void:
	if _cached_impact_mat == null:
		_cached_impact_mat = StandardMaterial3D.new()
		_cached_impact_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_cached_impact_mat.vertex_color_use_as_albedo = true
		_cached_impact_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_cached_impact_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_cached_impact_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		var spark_tex = load("res://assets/sprites/particles/particle_spark_soft.png")
		if spark_tex:
			_cached_impact_mat.albedo_texture = spark_tex
			
		_cached_impact_mesh = QuadMesh.new()
		_cached_impact_mesh.size = Vector2(0.2, 0.2)
		
		_cached_impact_grad_crit = Gradient.new()
		_cached_impact_grad_crit.set_color(0, Color(1.0, 0.4, 0.1, 1.0))
		_cached_impact_grad_crit.add_point(0.5, Color(1.0, 0.85, 0.2, 0.8))
		_cached_impact_grad_crit.set_color(_cached_impact_grad_crit.get_point_count() - 1, Color(1.0, 0.2, 0.1, 0.0))
		
		_cached_impact_grad_normal = Gradient.new()
		_cached_impact_grad_normal.set_color(0, Color(1.0, 1.0, 0.8, 1.0))
		_cached_impact_grad_normal.add_point(0.5, Color(1.0, 0.7, 0.3, 0.7))
		_cached_impact_grad_normal.set_color(_cached_impact_grad_normal.get_point_count() - 1, Color(1.0, 0.2, 0.1, 0.0))

	var particles := CPUParticles3D.new()
	particles.amount = 14 if is_crit else 8
	particles.lifetime = 0.25
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.25
	particles.direction = Vector3(randf_range(-1, 1), 1.0, randf_range(-1, 1)).normalized()
	particles.spread = 65.0
	particles.initial_velocity_min = 2.5
	particles.initial_velocity_max = 5.5 if is_crit else 3.8
	particles.gravity = Vector3(0, -6.0, 0)
	particles.scale_amount_min = 0.08
	particles.scale_amount_max = 0.20
	particles.material_override = _cached_impact_mat
	particles.mesh = _cached_impact_mesh
	particles.color_ramp = _cached_impact_grad_crit if is_crit else _cached_impact_grad_normal
	
	var main = get_parent()
	if not main:
		main = get_tree().current_scene
	if main:
		main.add_child(particles)
		particles.global_position = global_position + Vector3(0, 0.9, 0)
		particles.emitting = true
		get_tree().create_timer(0.35).timeout.connect(particles.queue_free)

func _spawn_damage_number(amount: float, is_crit: bool = false) -> void:
	if not damage_number_scene:
		return
	var num = damage_number_scene.instantiate()
	var main = get_parent()
	if not main:
		main = get_tree().current_scene
	if main:
		main.add_child(num)
		var spawn_pos = global_position + Vector3(0, 1.3, 0)
		num.setup(amount, is_crit, spawn_pos)

func _die() -> void:
	if is_boss:
		emit_signal("boss_defeated")
	_spawn_drop()
	queue_free()

func _spawn_drop() -> void:
	var main = get_parent()
	if not main: return
	
	# Elit veya Boss öldüğünde kesin Hazine Sandığı (chest_3d) bırakır
	if is_elite or is_boss:
		if chest_scene:
			var chest = chest_scene.instantiate()
			chest.position = Vector3(global_position.x, 0.0, global_position.z)
			main.add_child(chest)
		return
		
	var r = randf()
	if r < 0.25:
		# Coin
		var coin_sc = load("res://scenes/pickups/coin_3d.tscn")
		if coin_sc:
			var c = coin_sc.instantiate()
			c.position = Vector3(global_position.x, 0.0, global_position.z)
			main.add_child(c)
	else:
		# Gem
		var gem_sc = load("res://scenes/pickups/gem_3d.tscn")
		if gem_sc:
			var g = gem_sc.instantiate()
			g.position = Vector3(global_position.x, 0.0, global_position.z)
			g.xp_value = xp_value
			main.add_child(g)
