extends Area2D

@export var magnet_speed: float = 480.0

@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D = null
var is_attracted: bool = false
var is_collected: bool = false
var velocity: Vector2 = Vector2.ZERO
var pulse_time: float = 0.0

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if is_collected:
		return
		
	pulse_time += delta * 6.0
	if sprite:
		sprite.scale = Vector2.ONE * (0.6 + sin(pulse_time) * 0.08)
		
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var dist := global_position.distance_to(player.global_position)
	var reach: float = 180.0
	if "magnet_range_mult" in player:
		reach *= player.magnet_range_mult
		
	if dist < reach:
		is_attracted = true
		
	if is_attracted:
		var dir := (player.global_position - global_position).normalized()
		velocity = velocity.move_toward(dir * magnet_speed, 1800.0 * delta)
		global_position += velocity * delta
		
		if dist < 28.0:
			_collect(player)

func _on_body_entered(body: Node2D) -> void:
	_collect(body)

func _on_area_entered(area: Area2D) -> void:
	_collect(area.get_parent())

func _collect(target: Node2D) -> void:
	if is_collected:
		return
	is_collected = true
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("coin_pickup", 0.05, 3.0)
		
	# Haritadaki tüm XP kristallerini anında oyuncuya çek
	var p: Node2D = target if target.is_in_group("player") else get_tree().get_first_node_in_group("player")
	var gems := get_tree().get_nodes_in_group("xp_gems")
	for gem in gems:
		if is_instance_valid(gem) and not gem.get("is_collected"):
			if gem.has_method("start_attraction"):
				gem.start_attraction(p, 950.0)
			else:
				gem.is_attracted = true
				if "magnet_speed" in gem:
					gem.magnet_speed = maxf(gem.magnet_speed, 950.0)
				
	# Yüzen metin bildirimi
	_spawn_floating_text("VAKUM ÇEKİMİ!", Color(0.4, 0.8, 1.0))
	
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _spawn_floating_text(txt: String, col: Color) -> void:
	var label := Label.new()
	label.text = txt
	label.global_position = global_position - Vector2(50, 30)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", col)
	label.z_index = 50
	get_tree().current_scene.add_child(label)
	
	var t := label.create_tween()
	t.tween_property(label, "position:y", label.position.y - 45.0, 0.8)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.2)
	t.tween_callback(label.queue_free)
