class_name XPGem
extends Area2D

const MAX_ACTIVE_GEMS: int = 250
static var active_gems: Array[Area2D] = []

@export var xp_amount: int = 15
@export var magnet_speed: float = 520.0

@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D = null
var is_attracted: bool = false
var is_collected: bool = false
var is_absorbed: bool = false
var velocity: Vector2 = Vector2.ZERO
var tier: int = 1
var pulse_tween: Tween = null

func _enter_tree() -> void:
	register_gem(self)

func _exit_tree() -> void:
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	unregister_gem(self)

func _ready() -> void:
	add_to_group("xp_gems")
	collision_layer = 8
	collision_mask = 0
	set_deferred("monitoring", false)
	set_deferred("monitorable", true)
	
	_update_tier_visuals()
	
	# Başlangıçta işlemci yükünü sıfıra indirmek için process kapalıdır.
	# Oyuncu mıknatıs alanına girdiğinde start_attraction() ile açılır.
	set_process(false)
	
	# Eğer sınır aşıldıysa, oyuncuya en uzak kristale aktar ve bu nesneyi serbest bırak
	if active_gems.size() > MAX_ACTIVE_GEMS:
		var target_gem := _find_furthest_gem_from_player(self)
		if target_gem:
			target_gem.add_xp_value(xp_amount)
			unregister_gem(self)
			queue_free()
			return

	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func register_gem(gem: Area2D) -> void:
	if not active_gems.has(gem):
		active_gems.append(gem)

static func unregister_gem(gem: Area2D) -> void:
	active_gems.erase(gem)

static func reset_pool() -> void:
	active_gems.clear()

static func get_active_gem_count() -> int:
	_cleanup_dead_gems()
	return active_gems.size()

static func _cleanup_dead_gems() -> void:
	var clean: Array[Area2D] = []
	for g in active_gems:
		if is_instance_valid(g) and not g.is_queued_for_deletion() and not g.is_collected and not g.is_absorbed:
			clean.append(g)
	active_gems = clean

static func _find_furthest_gem_from_player(exclude_gem: Area2D = null) -> Area2D:
	_cleanup_dead_gems()
	if active_gems.is_empty():
		return null
		
	var p: Node2D = null
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		p = tree.get_first_node_in_group("player")
	var p_pos := p.global_position if p else Vector2.ZERO
	
	var max_dist_sq := -1.0
	var furthest: Area2D = null
	var furthest_unattracted: Area2D = null
	var max_unattracted_dist_sq := -1.0
	
	for g in active_gems:
		if g == exclude_gem or not is_instance_valid(g) or g.is_queued_for_deletion() or g.is_collected or g.is_absorbed:
			continue
		var d_sq := p_pos.distance_squared_to(g.global_position)
		if not g.is_attracted and d_sq > max_unattracted_dist_sq:
			max_unattracted_dist_sq = d_sq
			furthest_unattracted = g
		if d_sq > max_dist_sq:
			max_dist_sq = d_sq
			furthest = g
			
	return furthest_unattracted if furthest_unattracted else furthest

static func spawn_gem(tree: SceneTree, spawn_pos: Vector2, amount: int) -> Area2D:
	_cleanup_dead_gems()
	if not tree:
		tree = Engine.get_main_loop() as SceneTree
		
	# Vampire Survivors standardı: Sınır dolduğunda en uzaktaki kristal devasa kristale evrilir
	if active_gems.size() >= MAX_ACTIVE_GEMS:
		var furthest := _find_furthest_gem_from_player()
		if furthest:
			furthest.add_xp_value(amount)
			return furthest
			
	var scene := load("res://scenes/pickups/xp_gem.tscn") as PackedScene
	if not scene:
		return null
	var gem := scene.instantiate() as Area2D
	gem.position = spawn_pos
	gem.global_position = spawn_pos
	gem.xp_amount = amount
	register_gem(gem)
	
	var parent_node: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if parent_node:
		parent_node.call_deferred("add_child", gem)
	else:
		unregister_gem(gem)
		gem.queue_free()
		return null
	return gem

func setup(amount: int) -> void:
	xp_amount = amount
	_update_tier_visuals()

func add_xp_value(amount: int) -> void:
	xp_amount += amount
	_update_tier_visuals()
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if sprite and is_inside_tree():
		if pulse_tween and pulse_tween.is_valid():
			pulse_tween.kill()
		pulse_tween = create_tween()
		pulse_tween.tween_property(sprite, "scale", _get_tier_scale() * 1.45, 0.12).set_trans(Tween.TRANS_BACK)
		pulse_tween.tween_property(sprite, "scale", _get_tier_scale(), 0.12)

func _get_tier_scale() -> Vector2:
	if xp_amount < 25:
		return Vector2(0.22, 0.22)
	elif xp_amount < 80:
		return Vector2(0.28, 0.28)
	elif xp_amount < 250:
		return Vector2(0.35, 0.35)
	elif xp_amount < 800:
		return Vector2(0.44, 0.44)
	else:
		return Vector2(0.55, 0.55)

func _update_tier_visuals() -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if not sprite:
		return
		
	# Karanlık Orta Çağ Fantezi Kristal Skalası
	if xp_amount < 25:
		tier = 1
		sprite.modulate = Color(0.3, 0.70, 1.0, 1.0) # Berrak Mavi Kristal
		sprite.scale = Vector2(0.22, 0.22)
	elif xp_amount < 80:
		tier = 2
		sprite.modulate = Color(0.2, 0.92, 0.45, 1.0) # Zümrüt Yeşili Kristal
		sprite.scale = Vector2(0.28, 0.28)
	elif xp_amount < 250:
		tier = 3
		sprite.modulate = Color(0.95, 0.25, 0.2, 1.0) # Kızıl Ruh Kristali
		sprite.scale = Vector2(0.35, 0.35)
	elif xp_amount < 800:
		tier = 4
		sprite.modulate = Color(0.98, 0.82, 0.12, 1.0) # Parlak Altın Kristali
		sprite.scale = Vector2(0.44, 0.44)
	else:
		tier = 5
		sprite.modulate = Color(0.88, 0.22, 0.98, 1.0) # Kadim Mor Ruh Taşı
		sprite.scale = Vector2(0.55, 0.55)

func start_attraction(p: Node2D, override_speed: float = -1.0) -> void:
	if is_collected or is_absorbed:
		return
	player = p
	is_attracted = true
	if override_speed > 0.0:
		magnet_speed = override_speed
	set_process(true)

func _process(delta: float) -> void:
	if not is_attracted or is_collected or is_absorbed:
		set_process(false)
		return
		
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") if get_tree() else null
		if not player:
			set_process(false)
			return
			
	var dist := global_position.distance_to(player.global_position)
	var dir := (player.global_position - global_position).normalized()
	velocity = velocity.move_toward(dir * magnet_speed, 1800.0 * delta)
	global_position += velocity * delta
	
	if dist < 26.0:
		_collect(player)

func absorb_into() -> int:
	if is_collected or is_absorbed:
		return 0
	is_absorbed = true
	unregister_gem(self)
	var amt := xp_amount
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()
	return amt

func _collect(target: Node2D) -> void:
	if is_collected or is_absorbed:
		return
	is_collected = true
	unregister_gem(self)
	
	var p: Node2D = target if (target and target.is_in_group("player")) else (get_tree().get_first_node_in_group("player") if get_tree() else null)
	if p and p.has_method("add_xp"):
		p.add_xp(xp_amount)
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_sfx("xp", 0.15)
			
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()

