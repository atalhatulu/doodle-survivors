extends CharacterBody2D

signal boss_defeated()

@export var is_boss: bool = false
@export var is_elite: bool = false
@export var move_speed: float = 85.0
@export var max_health: float = 20.0
@export var damage: float = 10.0
@export var xp_scene: PackedScene = preload("res://scenes/pickups/xp_gem.tscn")
@export var damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number.tscn")
@export var coin_scene: PackedScene = preload("res://scenes/pickups/coin_pickup.tscn")
@export var coin_drop_chance: float = 0.04
@export var chest_scene: PackedScene = preload("res://scenes/pickups/chest_pickup.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var health: float = 20.0
var walk_cycle: float = 0.0
var base_scale: Vector2 = Vector2(0.55, 0.55)
var base_modulate: Color = Color(1, 1, 1, 1)
var hit_tween: Tween
var is_dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var hp_bar: ProgressBar = null

# Basit engel aşma / raycast avoidance değişkenleri
var obstacle_avoid_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	if sprite:
		base_scale = sprite.scale
		base_modulate = sprite.modulate
	walk_cycle = randf_range(0.0, 10.0)
	
	if is_boss and not hp_bar:
		_create_hp_bar()

func set_variant(color_tint: Color, scale_mult: float = 1.0) -> void:
	base_modulate = color_tint
	if sprite:
		sprite.modulate = base_modulate
		base_scale = sprite.scale * scale_mult
		sprite.scale = base_scale

func setup_elite(hp: float, dmg: float) -> void:
	is_elite = true
	max_health = hp
	health = hp
	damage = dmg
	_create_hp_bar()

func setup_boss(hp: float, dmg: float) -> void:
	is_boss = true
	max_health = hp
	health = hp
	damage = dmg
	_create_hp_bar()

func _create_hp_bar() -> void:
	if hp_bar:
		hp_bar.queue_free()
		
	hp_bar = ProgressBar.new()
	var bar_w: float = 90.0 if is_boss else 64.0
	var bar_h: float = 8.0 if is_boss else 6.0
	hp_bar.custom_minimum_size = Vector2(bar_w, bar_h)
	hp_bar.show_percentage = false
	hp_bar.max_value = max_health
	hp_bar.value = health
	
	var y_offset: float = -85.0 if is_boss else -65.0
	hp_bar.position = Vector2(-bar_w * 0.5, y_offset)
	
	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = Color(0.12, 0.1, 0.1, 0.85)
	bg_box.border_width_left = 1
	bg_box.border_width_top = 1
	bg_box.border_width_right = 1
	bg_box.border_width_bottom = 1
	bg_box.border_color = Color(0.0, 0.0, 0.0, 1)
	bg_box.corner_radius_top_left = 3
	bg_box.corner_radius_top_right = 3
	bg_box.corner_radius_bottom_right = 3
	bg_box.corner_radius_bottom_left = 3
	hp_bar.add_theme_stylebox_override("background", bg_box)
	
	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = Color(0.95, 0.25, 0.2, 1) if is_boss else Color(0.95, 0.75, 0.15, 1)
	fill_box.corner_radius_top_left = 3
	fill_box.corner_radius_top_right = 3
	fill_box.corner_radius_bottom_right = 3
	fill_box.corner_radius_bottom_left = 3
	hp_bar.add_theme_stylebox_override("fill", fill_box)
	
	add_child(hp_bar)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var to_player := (player.global_position - global_position).normalized()
	
	# Akıllı Engel Aşma (Raycast tabanlı çevreleme)
	var final_dir := to_player
	var space_state := get_world_2d().direct_space_state
	
	# İleriye 45 piksellik engel taraması
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + to_player * 48.0, 4) # layer 4: environment
	var result := space_state.intersect_ray(query)
	
	if result:
		# Engel varsa engel normaline göre sağa veya sola kayma vektörü ekle
		var normal: Vector2 = result.normal
		var tangent := Vector2(-normal.y, normal.x)
		if tangent.dot(to_player) < 0.0:
			tangent = -tangent
		final_dir = (to_player * 0.4 + tangent * 0.8).normalized()
		
	if knockback_velocity.length_squared() > 10.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	else:
		velocity = final_dir * move_speed
	
	if sprite:
		var is_player_on_left := player.global_position.x < global_position.x
		sprite.flip_h = is_player_on_left
		
	move_and_slide()
	_animate_procedural(delta)

func _animate_procedural(delta: float) -> void:
	if not sprite or is_dead:
		return
	if hit_tween and hit_tween.is_valid():
		return
	walk_cycle += delta * 10.0
	var bob := sin(walk_cycle)
	sprite.scale.x = base_scale.x * (1.0 + bob * 0.1)
	sprite.scale.y = base_scale.y * (1.0 - bob * 0.1)

func take_damage(amount: float, is_crit: bool = false, source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	health -= amount
	
	if hp_bar:
		hp_bar.value = health
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.15, 2.5 if is_crit else 0.0)
	
	# Hasar Sayısı Efekti (Doodle font & uçuşma)
	if damage_number_scene:
		var dmg_lbl = damage_number_scene.instantiate()
		get_tree().current_scene.call_deferred("add_child", dmg_lbl)
		dmg_lbl.setup(amount, is_crit, global_position + Vector2(0, -25))
		
	# Mikro Geri İtme (Knockback)
	var push_origin: Vector2 = source_pos if source_pos != Vector2.ZERO else (player.global_position if (player and is_instance_valid(player)) else global_position)
	var push_dir: Vector2 = (global_position - push_origin).normalized()
	if push_dir == Vector2.ZERO:
		push_dir = Vector2.RIGHT.rotated(randf() * TAU)
		
	var kb_strength: float = 220.0 if not is_crit else 340.0
	if is_boss:
		kb_strength *= 0.15
	elif is_elite:
		kb_strength *= 0.45
	knockback_velocity = push_dir * kb_strength
		
	# Juice: Parlama, Ezilme/Esnetme (Squash & Stretch) ve Titreme
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()
		
	hit_tween = create_tween().set_parallel(true)
	
	# Renk Parlaması: Normal hasarda kızıl-mürekkep, kritik hasarda altın-sarı
	var flash_color: Color = Color(3.5, 2.8, 0.8, 1.0) if is_crit else Color(2.6, 0.7, 0.7, 1.0)
	sprite.modulate = flash_color
	hit_tween.tween_property(sprite, "modulate", base_modulate, 0.14)
	
	# Squash & Stretch (Darbe anında yana esneyip basılma, ardından toparlanma)
	var squash_factor: float = 1.35 if not is_crit else 1.55
	sprite.scale = Vector2(base_scale.x * squash_factor, base_scale.y * (0.7 / squash_factor))
	hit_tween.tween_property(sprite, "scale", base_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Kağıt Çıkartma Titremesi (Sticker Wobble)
	var wobble_angle: float = randf_range(-0.25, 0.25) * (1.5 if is_crit else 1.0)
	sprite.rotation = wobble_angle
	hit_tween.tween_property(sprite, "rotation", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if health <= 0:
		_die()

# İnfaz animasyonu (Doodle tarzı havaya zıplayıp, dönerek ve küçülerek yok olma)
func _die() -> void:
	if is_dead:
		return
	is_dead = true
	if hp_bar and is_instance_valid(hp_bar):
		hp_bar.visible = false
		hp_bar.queue_free()
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("enemy_die", 0.12, 3.0 if (is_boss or is_elite) else 0.0)
		
	if is_boss:
		emit_signal("boss_defeated")
	
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	# XP Kristalini hemen bırak
	if xp_scene:
		var gem = xp_scene.instantiate()
		gem.global_position = global_position
		# Dengeli XP: Sıradan canavarlar 2-4 XP, Elitler 40 XP, Bosslar 150 XP
		var base_xp: int = 3
		if is_boss:
			base_xp = 150
		elif is_elite:
			base_xp = 40
		elif max_health > 80.0:
			base_xp = 8
		elif max_health > 40.0:
			base_xp = 5
		gem.xp_amount = base_xp
		get_tree().current_scene.call_deferred("add_child", gem)
		
	# Altın / Kağıt Ataş (Coin) Bırakma
	if coin_scene:
		var should_drop_coin := is_elite or is_boss or (randf() < coin_drop_chance)
		if should_drop_coin:
			var drop_count: int = 4 if is_elite else (8 if is_boss else 1)
			for i in range(drop_count):
				var coin = coin_scene.instantiate()
				var spread := Vector2(randf_range(-25.0, 25.0), randf_range(-25.0, 25.0))
				coin.global_position = global_position + spread
				get_tree().current_scene.call_deferred("add_child", coin)
				
	# Boss ve Elitlerden Hazine Sandığı Düşmesi
	if (is_boss or is_elite) and chest_scene:
		var chest = chest_scene.instantiate()
		chest.global_position = global_position
		chest.gold_amount = 100 if is_boss else 40
		get_tree().current_scene.call_deferred("add_child", chest)
		
	# İnfaz Animasyonu (Juice / Squash & Spin & Fade)
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()
		
	var death_tween := create_tween()
	death_tween.set_parallel(true)
	# Yukarı doğru zıplama
	death_tween.tween_property(sprite, "position:y", sprite.position.y - 35.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Dönüş
	death_tween.tween_property(sprite, "rotation", randf_range(-PI, PI) * 1.5, 0.25)
	# Küçülme
	death_tween.tween_property(sprite, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN)
	# Kararma / şeffaflaşma
	death_tween.tween_property(sprite, "modulate", Color(1.5, 0.3, 0.3, 0.0), 0.25)
	
	death_tween.chain().tween_callback(queue_free)
