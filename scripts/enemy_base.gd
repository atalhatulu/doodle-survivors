extends CharacterBody2D

signal boss_defeated()

@export var is_boss: bool = false
@export var is_elite: bool = false
@export var move_speed: float = 85.0
@export var max_health: float = 20.0
@export var damage: float = 10.0
const XPGem = preload("res://scripts/xp_gem.gd")
@export var xp_scene: PackedScene = preload("res://scenes/pickups/xp_gem.tscn")
@export var damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number.tscn")
@export var coin_scene: PackedScene = preload("res://scenes/pickups/coin_pickup.tscn")
@export var coin_drop_chance: float = 0.04
@export var chest_scene: PackedScene = preload("res://scenes/pickups/chest_pickup.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var health: float = 20.0
var current_health: float:
	get: return health
	set(v): health = v
var archetype_name: String = ""
var walk_cycle: float = 0.0
var base_scale: Vector2 = Vector2(0.55, 0.55)
var base_modulate: Color = Color(1, 1, 1, 1)
var variant_scale_mult: float = 1.0
var variant_tint: Color = Color.WHITE
var hit_tween: Tween
var is_dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var hp_bar: ProgressBar = null

# Basit engel aşma / raycast avoidance değişkenleri
var obstacle_avoid_dir: Vector2 = Vector2.ZERO

# Durum Efektleri (Status Effects)
var is_burning: bool = false
var burn_timer: float = 0.0
var burn_dmg: float = 0.0
var burn_tick: float = 0.0

var is_poisoned: bool = false
var poison_timer: float = 0.0
var poison_dmg: float = 0.0
var poison_tick: float = 0.0

var is_shocked: bool = false
var shock_timer: float = 0.0

var is_stunned: bool = false
var stun_timer: float = 0.0

var is_slowed: bool = false
var slow_timer: float = 0.0

# Boss Saldırı Telegrafları
var boss_attack_timer: float = 2.0
var boss_attack_cooldown: float = 6.5
var is_charging_attack: bool = false

func _init() -> void:
	add_to_group("enemies")

func _enter_tree() -> void:
	add_to_group("enemies")

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	if sprite:
		base_scale = sprite.scale * variant_scale_mult
		sprite.scale = base_scale
		base_modulate = sprite.modulate * variant_tint
		sprite.modulate = base_modulate
	walk_cycle = randf_range(0.0, 10.0)
	
	if is_boss and not hp_bar:
		_create_hp_bar()

func setup_archetype(p_name: String, p_tex_path: String, p_scale: float, p_hp: float, p_speed: float, p_dmg: float) -> void:
	archetype_name = p_name
	max_health = p_hp
	health = p_hp
	move_speed = p_speed
	damage = p_dmg
	if sprite:
		var tex = load(p_tex_path)
		if tex:
			sprite.texture = tex
		base_scale = Vector2(p_scale, p_scale)
		sprite.scale = base_scale

func set_variant(color_tint: Color, scale_mult: float = 1.0) -> void:
	variant_tint = color_tint
	variant_scale_mult = scale_mult
	if sprite:
		base_modulate = color_tint
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
		
	# Durum Efektleri Sayacı
	_process_status_effects(delta)
	if is_dead:
		return
		
	if is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if is_charging_attack:
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		move_and_slide()
		return
		
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	# Boss Telegrafları Kontrolü
	if is_boss and not is_charging_attack:
		boss_attack_timer += delta
		if boss_attack_timer >= boss_attack_cooldown:
			boss_attack_timer = 0.0
			_start_boss_telegraph()
		
	var to_player := (player.global_position - global_position).normalized()
	
	# Akıllı Engel Aşma (Yalnızca çevre engelleriyle çarpışan yer düşmanları için)
	var final_dir := to_player
	if (collision_mask & 4) != 0:
		var space_state := get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(global_position, global_position + to_player * 48.0, 4) # layer 4: environment
		var result := space_state.intersect_ray(query)
		
		if result:
			# Engel varsa engel normaline göre sağa veya sola kayma vektörü ekle
			var normal: Vector2 = result.normal
			var tangent := Vector2(-normal.y, normal.x)
			if tangent.dot(to_player) < 0.0:
				tangent = -tangent
			final_dir = (to_player * 0.4 + tangent * 0.8).normalized()
		
	var effective_speed: float = (move_speed * 0.5) if is_slowed else move_speed
	if knockback_velocity.length_squared() > 10.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	else:
		velocity = final_dir * effective_speed
	
	if sprite:
		var is_player_on_left := player.global_position.x < global_position.x
		sprite.flip_h = is_player_on_left
		
	move_and_slide()
	_animate_procedural(delta)

func _process_status_effects(delta: float) -> void:
	if is_burning:
		burn_timer -= delta
		burn_tick += delta
		if burn_tick >= 0.5:
			burn_tick = 0.0
			take_damage(burn_dmg, false, global_position, "weapon_dragon_breath")
		if burn_timer <= 0.0:
			is_burning = false
			_update_status_tint()

	if is_poisoned:
		poison_timer -= delta
		poison_tick += delta
		if poison_tick >= 0.7:
			poison_tick = 0.0
			take_damage(poison_dmg, false, global_position, "weapon_potion")
		if poison_timer <= 0.0:
			is_poisoned = false
			_update_status_tint()

	if is_shocked:
		shock_timer -= delta
		if shock_timer <= 0.0:
			is_shocked = false
			_update_status_tint()

	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false

	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0.0:
			is_slowed = false

func _animate_procedural(delta: float) -> void:
	if not sprite or is_dead:
		return
	if hit_tween and hit_tween.is_valid():
		return
		
	var is_moving := velocity.length_squared() > 100.0
	var enemy_type: String = archetype_name if archetype_name != "" else scene_file_path.get_file().get_basename()
	
	if enemy_type in ["enemy_bat", "enemy_wingeye", "enemy_eyeball", "bat_flyer", "bee_gasmask", "wasp_flying", "spiky_ghost"]:
		# Uçan yaratıklar: Havada yumuşak süzülme, dikey kanat/göz çırpma ve hafif yana yatma
		walk_cycle += delta * 14.0
		var float_y := sin(walk_cycle * 0.5) * 5.0
		var flap := cos(walk_cycle) * 0.12
		sprite.position.y = lerp(sprite.position.y, float_y, delta * 12.0)
		sprite.scale.x = base_scale.x * (1.0 + flap)
		sprite.scale.y = base_scale.y * (1.0 - flap * 0.8)
		sprite.rotation = lerp_angle(sprite.rotation, sin(walk_cycle * 0.5) * 0.1, delta * 10.0)
		
	elif enemy_type in ["enemy_frog"]:
		# Kurbağa / Sıçrayan yaratıklar: Zıplama ve yere inince ezilme (hop & squash)
		walk_cycle += delta * 7.0
		var hop := sin(walk_cycle)
		if hop > 0.1:
			# Zıplama anı: Dikey uzama, yukarı kalkma
			sprite.position.y = lerp(sprite.position.y, -hop * 10.0, delta * 15.0)
			sprite.scale.x = base_scale.x * (1.0 - hop * 0.15)
			sprite.scale.y = base_scale.y * (1.0 + hop * 0.20)
		else:
			# Yere basma/çökme anı: Yana genişleme, dikey basılma
			sprite.position.y = lerp(sprite.position.y, 0.0, delta * 15.0)
			sprite.scale.x = base_scale.x * (1.0 + absf(hop) * 0.15)
			sprite.scale.y = base_scale.y * (1.0 - absf(hop) * 0.15)
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, delta * 8.0)
		
	elif enemy_type in ["enemy_brute", "enemy_chomper", "enemy_king", "brute_cyclops", "fury_cyclops", "armored_turtle", "wood_log_spiked"]:
		# Ağır zırhlılar / Boss'lar: Ağır adımlar, sarsıcı yana yatma ve derin soluk
		var anim_spd: float = 6.0 if is_moving else 2.5
		walk_cycle += delta * anim_spd
		var sway := sin(walk_cycle)
		if is_moving:
			sprite.rotation = lerp_angle(sprite.rotation, sway * 0.08, delta * 8.0)
			sprite.scale.x = base_scale.x * (1.0 + absf(sway) * 0.06)
			sprite.scale.y = base_scale.y * (1.0 - absf(sway) * 0.06)
		else:
			# Ağır nefes alma
			sprite.rotation = lerp_angle(sprite.rotation, 0.0, delta * 6.0)
			sprite.scale.x = base_scale.x * (1.0 + sway * 0.03)
			sprite.scale.y = base_scale.y * (1.0 - sway * 0.03)
		sprite.position.y = lerp(sprite.position.y, 0.0, delta * 8.0)
		
	elif enemy_type in ["enemy_ghost", "spiky_ghost"]:
		# Hayalet / Kültist: Titrek mistik dalgalanma ve hafif süzülme
		walk_cycle += delta * 4.0
		var levitate := sin(walk_cycle) * 6.0
		sprite.position.y = lerp(sprite.position.y, levitate, delta * 6.0)
		sprite.rotation = lerp_angle(sprite.rotation, cos(walk_cycle * 0.7) * 0.05, delta * 6.0)
		sprite.scale.x = base_scale.x * (1.0 + sin(walk_cycle * 2.0) * 0.04)
		sprite.scale.y = base_scale.y * (1.0 - sin(walk_cycle * 2.0) * 0.04)
		
	else:
		# Standart Piyadeler (İskelet, Örümcek, Gulyabani vb.)
		var cycle_spd: float = 12.0 if is_moving else 3.5
		walk_cycle += delta * cycle_spd
		var bob := sin(walk_cycle)
		if is_moving:
			sprite.rotation = lerp_angle(sprite.rotation, bob * 0.12, delta * 12.0)
			sprite.scale.x = base_scale.x * (1.0 + absf(bob) * 0.08)
			sprite.scale.y = base_scale.y * (1.0 - absf(bob) * 0.08)
		else:
			sprite.rotation = lerp_angle(sprite.rotation, 0.0, delta * 8.0)
			sprite.scale.x = base_scale.x * (1.0 + bob * 0.04)
			sprite.scale.y = base_scale.y * (1.0 - bob * 0.04)
		sprite.position.y = lerp(sprite.position.y, 0.0, delta * 8.0)

func take_damage(amount: float, is_crit: bool = false, source_pos: Vector2 = Vector2.ZERO, source_weapon_id: String = "") -> void:
	if is_dead:
		return
	health -= amount
	
	if source_weapon_id != "" and player and player.has_method("record_weapon_damage"):
		player.record_weapon_damage(source_weapon_id, amount)
	
	if hp_bar:
		hp_bar.value = health
		
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var audio = tree.root.get_node_or_null("AudioManager") if (tree and tree.root) else null
	if audio:
		audio.play_sfx("hit", 0.15, 2.5 if is_crit else 0.0)
	
	# Hasar Sayısı Efekti (Doodle font & uçuşma)
	if damage_number_scene:
		var dmg_lbl = damage_number_scene.instantiate()
		var target_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
		if target_parent:
			target_parent.call_deferred("add_child", dmg_lbl)
		if dmg_lbl.has_method("setup"):
			dmg_lbl.call_deferred("setup", amount, is_crit, global_position + Vector2(0, -25))
		
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
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if sprite:
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
	remove_from_group("enemies")
	if hp_bar and is_instance_valid(hp_bar):
		hp_bar.visible = false
		hp_bar.queue_free()
		
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var audio = tree.root.get_node_or_null("AudioManager") if (tree and tree.root) else null
	if audio:
		audio.play_sfx("enemy_die", 0.12, 3.0 if (is_boss or is_elite) else 0.0)
		
	if is_boss:
		emit_signal("boss_defeated")
		
	if player:
		if "total_enemies_killed" in player:
			player.total_enemies_killed += 1
		if player.has_method("on_enemy_killed_near"):
			player.on_enemy_killed_near(global_position)
	
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	# XP Kristali bırakma (Maksimum 250 sınır, sınır aşıldığında oyuncuya en uzak kristale aktarılır)
	var base_xp: int = 3
	if is_boss:
		base_xp = 150
	elif is_elite:
		base_xp = 40
	elif max_health > 80.0:
		base_xp = 8
	elif max_health > 40.0:
		base_xp = 5
	XPGem.spawn_gem(tree, global_position, base_xp)
		
	# Altın Sikke (Coin) Bırakma
	if coin_scene:
		var gold_bonus: float = player.frenzy_gold_bonus if (player and "frenzy_gold_bonus" in player) else 1.0
		var should_drop_coin := is_elite or is_boss or (randf() < (coin_drop_chance * gold_bonus))
		if should_drop_coin:
			var drop_count: int = 4 if is_elite else (8 if is_boss else 1)
			for i in range(drop_count):
				var coin = coin_scene.instantiate()
				var spread := Vector2(randf_range(-25.0, 25.0), randf_range(-25.0, 25.0))
				coin.global_position = global_position + spread
				var target_p: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
				if target_p:
					target_p.call_deferred("add_child", coin)
				
	# Boss ve Elitlerden Hazine Sandığı Düşmesi
	if (is_boss or is_elite) and chest_scene:
		var chest = chest_scene.instantiate()
		chest.global_position = global_position
		chest.gold_amount = 100 if is_boss else 40
		var target_p: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
		if target_p:
			target_p.call_deferred("add_child", chest)
		
	# İnfaz Animasyonu (Juice / Squash & Spin & Fade)
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()
		
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if sprite:
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
	else:
		queue_free()

func apply_status(status_type: String, duration_sec: float, tick_damage_val: float = 12.0) -> void:
	if is_dead:
		return
	if status_type == "burn":
		if is_poisoned:
			_trigger_toxic_explosion()
			return
		is_burning = true
		burn_timer = maxf(burn_timer, duration_sec)
		burn_dmg = tick_damage_val
		_update_status_tint()
	elif status_type == "poison":
		if is_burning:
			_trigger_toxic_explosion()
			return
		is_poisoned = true
		poison_timer = maxf(poison_timer, duration_sec)
		poison_dmg = tick_damage_val
		_update_status_tint()
	elif status_type == "shock":
		is_shocked = true
		shock_timer = maxf(shock_timer, duration_sec)
		_check_superconduct_vortex_synergy()
		_update_status_tint()
	elif status_type == "stun":
		is_stunned = true
		stun_timer = maxf(stun_timer, duration_sec)
	elif status_type == "slow":
		is_slowed = true
		slow_timer = maxf(slow_timer, duration_sec)

func _trigger_toxic_explosion() -> void:
	is_burning = false
	is_poisoned = false
	_update_status_tint()
	
	var mult: float = player.damage_multiplier if (player and "damage_multiplier" in player) else 1.0
	var explosion_damage: float = 85.0 * mult
	var blast_radius: float = 135.0
	
	if player and player.has_method("record_weapon_damage"):
		player.record_weapon_damage("rezonans_toksik_patlama", explosion_damage)
		
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var audio = tree.root.get_node_or_null("AudioManager") if (tree and tree.root) else null
	if audio:
		audio.play_sfx("hit", 0.1, 2.5)
	if player and player.has_method("add_camera_shake"):
		player.add_camera_shake(3.5)
		
	var fx := Node2D.new()
	fx.global_position = global_position
	var fx_parent: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if fx_parent:
		fx_parent.call_deferred("add_child", fx)
	
	# Patlama merkezindeki düşman doğrudan hasar alır
	take_damage(explosion_damage, true, global_position, "rezonans_toksik_patlama")
	
	var enemies: Array = tree.get_nodes_in_group("enemies") if tree else []
	for e in enemies:
		if e != self and is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			var dist := global_position.distance_to(e.global_position)
			if dist <= blast_radius:
				if e.has_method("take_damage"):
					e.take_damage(explosion_damage, true, global_position, "rezonans_toksik_patlama")
				if "knockback_velocity" in e:
					var p_dir: Vector2 = (e.global_position - global_position).normalized()
					e.knockback_velocity += p_dir * 300.0

func _check_superconduct_vortex_synergy() -> void:
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var vortices: Array = tree.get_nodes_in_group("void_vortices") if tree else []
	for v in vortices:
		if is_instance_valid(v) and global_position.distance_to(v.global_position) <= 220.0:
			if v.has_method("trigger_superconduct"):
				v.trigger_superconduct(player)
				break

func _update_status_tint() -> void:
	if not sprite or is_dead:
		return
	if is_burning and is_poisoned:
		sprite.modulate = Color(2.5, 1.5, 0.4, 1.0)
	elif is_burning:
		sprite.modulate = Color(2.0, 0.7, 0.4, 1.0)
	elif is_poisoned:
		sprite.modulate = Color(0.5, 2.0, 0.6, 1.0)
	elif is_shocked:
		sprite.modulate = Color(0.6, 1.4, 2.5, 1.0)
	elif is_slowed:
		sprite.modulate = Color(0.5, 0.7, 1.5, 1.0)
	else:
		sprite.modulate = base_modulate

func _start_boss_telegraph() -> void:
	if is_dead or not player or not is_instance_valid(player):
		return
	is_charging_attack = true
	var telegraph_script = preload("res://scripts/boss_telegraph.gd")
	var tele := Node2D.new()
	tele.set_script(telegraph_script)
	tele.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", tele)
	
	var pick_circle: bool = (randf() < 0.5)
	if pick_circle:
		tele.setup_circle(190.0, 1.2, func(): _execute_boss_slam(tele.global_position))
	else:
		var dir := (player.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		tele.setup_line(dir, 110.0, 420.0, 1.0, func(): _execute_boss_charge(dir))

func _execute_boss_slam(slam_center: Vector2) -> void:
	if is_dead:
		is_charging_attack = false
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.2, 3.0)
	if player and is_instance_valid(player):
		var dist := slam_center.distance_to(player.global_position)
		if dist <= 190.0:
			player.take_damage(damage * 1.35)
			if player.has_method("add_camera_shake"):
				player.add_camera_shake(6.0)
	if sprite:
		var tw := create_tween()
		tw.tween_property(sprite, "scale", base_scale * 1.4, 0.15)
		tw.tween_property(sprite, "scale", base_scale, 0.15)
	is_charging_attack = false

func _execute_boss_charge(charge_dir: Vector2) -> void:
	if is_dead:
		is_charging_attack = false
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("axe_throw", 0.15, 1.5)
	knockback_velocity = charge_dir * 550.0
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func(): is_charging_attack = false)
