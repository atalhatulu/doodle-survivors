extends Area3D

@export var speed: float = 24.0
@export var damage: float = 35.0
@export var lifetime: float = 2.0

var direction: Vector3 = Vector3.FORWARD
var spin_speed: float = 15.0
var pierce_left: int = 1
var is_area_blast: bool = false
var blast_growth_rate: float = 0.0
var hit_targets: Array[Node] = []
var base_scale: Vector3 = Vector3.ONE

var behavior: String = "targeted"
var player_ref: Node3D = null
var spawn_pos: Vector3 = Vector3.ZERO
var initial_lifetime: float = 2.0
var target_dest: Vector3 = Vector3.ZERO
var elapsed_time: float = 0.0
var arc_spawn_offset: Vector3 = Vector3.ZERO
var has_ground_shockwaved: bool = false
var original_tex_path: String = ""

# İleri düzey silah davranış değişkenleri
var sine_wobble_freq: float = 8.5
var sine_wobble_amp: float = 0.32
var locked_target: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if original_tex_path.contains("dagger"):
		_acquire_homing_target()

func configure(
	p_dir: Vector3,
	p_damage: float,
	p_speed: float,
	p_tex_path: String,
	p_scale: float = 0.0055,
	p_spin: float = 15.0,
	p_pierce: int = 1,
	p_lifetime: float = 2.0,
	p_is_area_blast: bool = false,
	p_behavior: String = "targeted",
	p_player: Node3D = null,
	p_dest: Vector3 = Vector3.ZERO
) -> void:
	direction = p_dir.normalized() if p_dir.length_squared() > 0.001 else Vector3.ZERO
	damage = p_damage
	speed = p_speed
	spin_speed = p_spin
	pierce_left = p_pierce
	lifetime = p_lifetime
	initial_lifetime = p_lifetime
	is_area_blast = p_is_area_blast
	behavior = p_behavior
	player_ref = p_player
	spawn_pos = global_position if is_inside_tree() else position
	target_dest = p_dest
	elapsed_time = 0.0
	has_ground_shockwaved = false
	original_tex_path = p_tex_path
	hit_targets.clear()
	
	var col: CollisionShape3D = get_node_or_null("CollisionShape3D")
	var sp: Sprite3D = get_node_or_null("Sprite3D")
	if sp:
		sp.pixel_size = p_scale
		var t = load(p_tex_path)
		if t:
			sp.texture = t
		if p_spin == 0.0 and direction.length_squared() > 0.001 and behavior != "sky_strike":
			sp.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			# 3D uzayda hedefe doğru yatayda ve dikeyde yönlen
			var yaw = atan2(-direction.x, -direction.z)
			var horiz_len = Vector2(direction.x, direction.z).length()
			var pitch = atan2(direction.y, horiz_len)
			sp.rotation = Vector3(pitch, yaw, 0.0)
		elif behavior == "sky_strike":
			sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		elif is_area_blast:
			sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		else:
			# Balta, bumerang vb. dönen nesneler için Y-Billboard
			sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			
	if is_area_blast:
		blast_growth_rate = 3.5
		scale = Vector3(0.5, 0.5, 0.5)
		if sp:
			sp.pixel_size = minf(p_scale, 0.007)
	elif behavior == "melee_arc":
		# Yakın dövüş savurması (Kılıç kavis kesişi)
		scale = Vector3(1.6, 1.6, 1.6)
		if player_ref and is_instance_valid(player_ref):
			var my_pos = global_position if is_inside_tree() else position
			arc_spawn_offset = my_pos - player_ref.global_position
	elif behavior == "vortex":
		# Hiçlik girdabı: devasa çekim alanı
		scale = Vector3(1.3, 1.3, 1.3)
	elif behavior == "parabolic_lob":
		# Balta / İksir atışı: başlangıçta yukarı doğru yay
		scale = Vector3(1.0, 1.0, 1.0)
	elif behavior == "sky_strike":
		scale = Vector3(1.8, 1.8, 1.8)
		if sp:
			sp.scale = Vector3(1.0, 1.5, 1.0)
	else:
		var scale_factor = p_scale / 0.0055
		if col:
			col.scale = Vector3.ONE * clampf(scale_factor, 0.8, 3.5)

	_setup_projectile_particles()

func _acquire_homing_target() -> void:
	var tree = get_tree()
	if not tree: return
	var enemies = tree.get_nodes_in_group("enemies")
	var best_dist_sq := 225.0 # 15 metre menzil
	var my_pos = global_position if is_inside_tree() else position
	var nearest: Node3D = null
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if e.get("is_dead") == true or e.get("is_broken") == true:
				continue
			var d_sq = my_pos.distance_squared_to(e.global_position)
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				nearest = e
	locked_target = nearest

# Statik önbellek: Materyal, Mesh ve Gradient paylaşımı (GC ve tahsis yükünü sıfıra indirir)
static var _cached_mat: StandardMaterial3D = null
static var _cached_mesh: QuadMesh = null
static var _cached_grad: Gradient = null

func _setup_projectile_particles() -> void:
	if is_area_blast:
		return
		
	if _cached_mat == null:
		_cached_mat = StandardMaterial3D.new()
		_cached_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_cached_mat.vertex_color_use_as_albedo = true
		_cached_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_cached_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_cached_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		var spark_tex = load("res://assets/sprites/particles/particle_spark_soft.png")
		if spark_tex:
			_cached_mat.albedo_texture = spark_tex
			
		_cached_mesh = QuadMesh.new()
		_cached_mesh.size = Vector2(0.22, 0.22)
		
		_cached_grad = Gradient.new()
		_cached_grad.set_color(0, Color(1.0, 0.9, 0.4, 0.95)) # Golden spark
		_cached_grad.add_point(0.35, Color(0.9, 0.4, 0.95, 0.85)) # Arcane purple
		_cached_grad.add_point(0.75, Color(0.3, 0.8, 1.0, 0.6)) # Cyan dissipation
		_cached_grad.set_color(_cached_grad.get_point_count() - 1, Color(0.1, 0.3, 0.8, 0.0))

	var particles := CPUParticles3D.new()
	particles.amount = 16
	particles.lifetime = 0.35
	particles.explosiveness = 0.0
	particles.randomness = 0.2
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.22
	particles.gravity = Vector3(0, 0.5, 0)
	particles.initial_velocity_min = 0.2
	particles.initial_velocity_max = 1.0
	particles.scale_amount_min = 0.12
	particles.scale_amount_max = 0.26
	particles.material_override = _cached_mat
	particles.mesh = _cached_mesh
	particles.color_ramp = _cached_grad
	
	add_child(particles)

func _physics_process(delta: float) -> void:
	elapsed_time += delta
	lifetime -= delta
	
	match behavior:
		"sky_strike":
			# Gökten dikey hızla in
			global_position += Vector3.DOWN * speed * delta
			if global_position.y <= 0.4:
				global_position.y = 0.4
				if not has_ground_shockwaved:
					has_ground_shockwaved = true
					_spawn_ground_crater(global_position, 1.35)
					_spawn_lightning_impact()
				queue_free()
				return
				
		"parabolic_lob":
			# Hedefe doğru parabolik kavis (Arc throw)
			# Yerçekimi hissi veren parabol: 4.0 * t * (1.0 - t), zirvede yavaşlayan, düşerken hızlanan eğri
			var total_t = maxf(0.01, initial_lifetime)
			var raw_progress = clampf(elapsed_time / total_t, 0.0, 1.0)
			
			# Zirvede yavaşlayıp düşüşte hızlanan organik zaman eğrisi (ease in-out)
			var progress = 0.5 - 0.5 * cos(raw_progress * PI)
			var horiz_pos = spawn_pos.lerp(target_dest, progress)
			
			# Parabolik fizik eğrisi: t=0.5 noktasında zirve yapar
			var arc_height = (4.0 * raw_progress * (1.0 - raw_progress)) * 4.2
			global_position = Vector3(horiz_pos.x, maxf(0.35, horiz_pos.y + arc_height), horiz_pos.z)
			
			if spin_speed != 0.0:
				var sp = get_node_or_null("Sprite3D")
				if sp:
					sp.rotation.z += delta * spin_speed
					
			if raw_progress >= 1.0 or lifetime <= 0.0:
				_spawn_ground_crater(global_position, 0.95)
				_spawn_hit_spark(global_position)
				if original_tex_path.contains("potion"):
					_spawn_potion_puddle()
				else:
					_spawn_axe_impact()
				queue_free()
				return
				
		"boomerang":
			# Oyuncunun hareketine göre yumuşak yay çizen kavisli dönüş ve eksende takla
			var half_life = initial_lifetime * 0.5
			var current_spd := speed
			var sp = get_node_or_null("Sprite3D")
			
			# Kendi ekseninde takla animasyonu (Z ekseni dönüşü + X ekseni taklası)
			if sp:
				sp.rotation.z += delta * spin_speed
				sp.rotation.x += delta * (spin_speed * 0.6)
			
			if elapsed_time < half_life:
				# İleri gidiş ve hafif yan kavis
				var side_curve = Vector3(-direction.z, 0.0, direction.x) * sin((elapsed_time / half_life) * PI) * 3.5
				current_spd = lerpf(speed, 2.0, elapsed_time / half_life)
				global_position += (direction * current_spd + side_curve) * delta
			else:
				# Yumuşak kavisle geriye oyuncuya doğru yönel
				var target_pos = player_ref.global_position + Vector3(0, 1.0, 0) if (player_ref and is_instance_valid(player_ref)) else (spawn_pos + Vector3(0, 1.0, 0))
				var to_player = target_pos - global_position
				to_player.y = 0.0
				var return_dir = to_player.normalized() if to_player.length_squared() > 0.01 else -direction
				
				# Yumuşak açısal yönelme (Slerp-like steer)
				direction = direction.lerp(return_dir, delta * 6.0).normalized()
				current_spd = lerpf(3.0, speed * 1.35, (elapsed_time - half_life) / half_life)
				global_position += direction * current_spd * delta
				
				if to_player.length() < 1.5:
					queue_free()
					return
				
			if global_position.y < 0.35:
				global_position.y = 0.35
					
		"vortex":
			# Ağır hareket et veya yerinde dur, etraftaki düşmanları merkezine çek
			global_position += direction * (speed * 0.35) * delta
			if global_position.y < 0.35:
				global_position.y = 0.35
			if spin_speed != 0.0:
				var sp = get_node_or_null("Sprite3D")
				if sp:
					sp.rotation.z += delta * spin_speed
			# Çekim kuvveti (Black hole pull)
			_pull_nearby_enemies(delta)
			
		"melee_arc":
			# Karakterin önünde 140 derecelik kavisli kılıç savurması:
			# Organik hızlanma-yavaşlama (ease-out cubic eğrisi)
			var p_fwd := Vector3.FORWARD
			if direction.length_squared() > 0.001:
				p_fwd = Vector3(direction.x, 0.0, direction.z).normalized()
			elif player_ref and "facing_dir" in player_ref:
				var p_face: Vector3 = player_ref.facing_dir
				p_face.y = 0.0
				if p_face.length_squared() > 0.001:
					p_fwd = p_face.normalized()
					
			if player_ref and is_instance_valid(player_ref):
				var total_t = maxf(0.01, initial_lifetime)
				var raw_prog = clampf(elapsed_time / total_t, 0.0, 1.0)
				# Ease-out cubic: hızlı başlar, savurma sonuna doğru organikçe frenler
				var swing_prog = 1.0 - pow(1.0 - raw_prog, 3.0)
				var angle = lerpf(-1.25, 1.25, swing_prog)
				
				var swing_offset = (p_fwd.rotated(Vector3.UP, angle)) * 2.3
				global_position = player_ref.global_position + Vector3(0, 1.0, 0) + swing_offset
				var sp = get_node_or_null("Sprite3D")
				if sp:
					sp.billboard = BaseMaterial3D.BILLBOARD_DISABLED
					var yaw = atan2(-swing_offset.x, -swing_offset.z)
					sp.rotation = Vector3(deg_to_rad(-25.0), yaw, angle * 0.7)
			else:
				global_position += p_fwd * speed * delta
				
		_:
			# Standart / Hançer / Asa / Alan Patlaması
			if not is_area_blast:
				# Asa Küresi (weapon_staff): Hafif sinüs süzülmesi (subtle arcane wobble) ve ışıltı izi
				if original_tex_path.contains("orb"):
					var right_vec = Vector3(-direction.z, 0.0, direction.x).normalized() if direction.length_squared() > 0.001 else Vector3.RIGHT
					# Analitik yan hız türevi: d/dt [A * sin(w * t)] = A * w * cos(w * t) -> 0.32m genlikte organik salınım
					var wobble_deriv = right_vec * (cos(elapsed_time * sine_wobble_freq) * sine_wobble_freq * sine_wobble_amp)
					var vert_wobble = Vector3.UP * (sin(elapsed_time * (sine_wobble_freq * 0.6)) * 0.45)
					global_position += (direction * speed + wobble_deriv + vert_wobble) * delta
				# Hançer (weapon_dagger): İnce delici hava yarığı iziyle hedefe kilitlenme (homing steering)
				elif original_tex_path.contains("dagger"):
					if not is_instance_valid(locked_target) or locked_target.is_queued_for_deletion() or locked_target.get("is_dead") == true:
						_acquire_homing_target()
					if locked_target and is_instance_valid(locked_target) and not locked_target.is_queued_for_deletion():
						var to_enemy = (locked_target.global_position + Vector3(0, 0.8, 0)) - global_position
						to_enemy.y = 0.0
						if to_enemy.length_squared() > 0.01:
							direction = direction.lerp(to_enemy.normalized(), delta * 8.5).normalized()
							var sp = get_node_or_null("Sprite3D")
							if sp and sp.billboard == BaseMaterial3D.BILLBOARD_DISABLED:
								var yaw = atan2(-direction.x, -direction.z)
								sp.rotation = Vector3(0.0, yaw, 0.0)
					global_position += direction * speed * delta
				else:
					global_position += direction * speed * delta
					
				if global_position.y < 0.35:
					global_position.y = 0.35
				if spin_speed != 0.0:
					var sp = get_node_or_null("Sprite3D")
					if sp:
						sp.rotation.z += delta * spin_speed
			else:
				if scale.x < 2.2:
					scale += Vector3.ONE * (blast_growth_rate * delta)
				if spin_speed != 0.0:
					var sp = get_node_or_null("Sprite3D")
					if sp:
						sp.rotation.z += delta * spin_speed

	if lifetime <= 0.0:
		queue_free()

func _pull_nearby_enemies(delta: float) -> void:
	var tree = get_tree()
	if not tree: return
	var enemies = tree.get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			continue
		var dist_sq = global_position.distance_squared_to(e.global_position)
		if dist_sq < 25.0: # 5 metre menzil
			var pull_dir = (global_position - e.global_position)
			pull_dir.y = 0.0
			if pull_dir.length_squared() > 0.05:
				e.global_position += pull_dir.normalized() * (4.5 * delta)

func _spawn_ground_crater(hit_pos: Vector3, crater_scale: float = 1.0) -> void:
	var parent_node = get_parent()
	if not parent_node: return
	
	var crater := Sprite3D.new()
	crater.texture = load("res://assets/sprites/weapons/ground_impact_crater.png")
	crater.pixel_size = 0.0075 * crater_scale
	# Yere yatay darbe lekesi
	crater.rotation = Vector3(-PI * 0.5, randf_range(0, TAU), 0.0)
	crater.position = Vector3(hit_pos.x, 0.025, hit_pos.z)
	crater.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	crater.modulate = Color(1.0, 1.0, 1.0, 0.95)
	parent_node.add_child(crater)
	
	# 2.2 saniye sonra yavaşça solup silinsin
	var tw = crater.create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(crater, "modulate:a", 0.0, 0.6)
	tw.tween_callback(crater.queue_free)

func _spawn_hit_spark(pos: Vector3) -> void:
	var parent_node = get_parent()
	if not parent_node: return
	
	var spark_particles := CPUParticles3D.new()
	spark_particles.amount = 8
	spark_particles.lifetime = 0.22
	spark_particles.one_shot = true
	spark_particles.explosiveness = 1.0
	spark_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	spark_particles.emission_sphere_radius = 0.15
	spark_particles.gravity = Vector3(0, -2.0, 0)
	spark_particles.initial_velocity_min = 2.0
	spark_particles.initial_velocity_max = 4.5
	spark_particles.scale_amount_min = 0.1
	spark_particles.scale_amount_max = 0.25
	spark_particles.material_override = _cached_mat
	spark_particles.mesh = _cached_mesh
	spark_particles.color_ramp = _cached_grad
	spark_particles.position = pos
	parent_node.add_child(spark_particles)
	spark_particles.emitting = true
	
	var tw = spark_particles.create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(spark_particles.queue_free)

func _spawn_lightning_impact() -> void:
	var proj_scene := load("res://scenes/weapons/proj_blade_3d.tscn")
	if not proj_scene: return
	var blast = proj_scene.instantiate()
	blast.position = Vector3(global_position.x, 0.4, global_position.z)
	blast.configure(Vector3.ZERO, damage * 0.65, 0.0, "res://assets/sprites/weapons/proj_magic_spark.png", 0.006, 10.0, 99, 0.35, true)
	get_parent().add_child(blast)
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.06, 1.2)

func _spawn_potion_puddle() -> void:
	var proj_scene := load("res://scenes/weapons/proj_blade_3d.tscn")
	if not proj_scene: return
	var puddle = proj_scene.instantiate()
	puddle.position = Vector3(global_position.x, 0.36, global_position.z)
	puddle.configure(Vector3.ZERO, damage * 0.5, 0.0, "res://assets/sprites/weapons/proj_potion.png", 0.0055, 0.0, 99, 2.5, true)
	get_parent().add_child(puddle)
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.05, 0.9)

func _spawn_axe_impact() -> void:
	var proj_scene := load("res://scenes/weapons/proj_blade_3d.tscn")
	if not proj_scene: return
	var shock = proj_scene.instantiate()
	shock.position = Vector3(global_position.x, 0.36, global_position.z)
	shock.configure(Vector3.ZERO, damage * 0.45, 0.0, "res://assets/sprites/weapons/proj_magic_spark.png", 0.0055, 0.0, 99, 0.25, true)
	get_parent().add_child(shock)
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.08, 0.85)

func _handle_hit(target: Node) -> void:
	if not is_instance_valid(target) or hit_targets.has(target):
		return
		
	if target.has_method("take_damage"):
		hit_targets.append(target)
		var hit_dir = direction
		if hit_dir.length_squared() < 0.01:
			var rel = target.global_position - global_position
			rel.y = 0.0
			hit_dir = rel.normalized() if rel.length_squared() > 0.001 else Vector3.FORWARD
		target.take_damage(damage, hit_dir)
		
		# Vuruş anında darbe partikülleri (Hit Spark Burst)
		_spawn_hit_spark(global_position)
		
		# Vuruş ses efekti
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_sfx("hit", 0.08, 0.0)
			
		if not is_area_blast:
			pierce_left -= 1
			if pierce_left <= 0:
				queue_free()

func _on_body_entered(body: Node) -> void:
	_handle_hit(body)

func _on_area_entered(area: Area3D) -> void:
	_handle_hit(area)

