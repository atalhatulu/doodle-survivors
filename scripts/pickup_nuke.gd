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
		
	pulse_time += delta * 7.0
	if sprite:
		sprite.scale = Vector2.ONE * (0.65 + sin(pulse_time) * 0.1)
		
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
		audio.play_sfx("hit", 0.02, 3.5)
		
	# Ekran beyaz parlama efekti
	_create_screen_flash()
	
	# Ekrandaki tüm normal düşmanları kutsal ışıkla yok et
	var enemies := get_tree().get_nodes_in_group("enemies")
	var p: Node2D = target if target.is_in_group("player") else get_tree().get_first_node_in_group("player")
	var p_pos := p.global_position if p else global_position
	
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.get("is_dead"):
			var is_boss: bool = enemy.get("is_boss") if "is_boss" in enemy else false
			if not is_boss:
				if enemy.has_method("take_damage"):
					enemy.take_damage(9999.0, true, p_pos)
					
	_spawn_floating_text("KUTSAL IŞIK: DÜŞMANLAR BİÇİLDİ!", Color(1.0, 0.9, 0.3))
	
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _create_screen_flash() -> void:
	var flash := CanvasLayer.new()
	flash.layer = 100
	flash.process_mode = Node.PROCESS_MODE_ALWAYS
	var rect := ColorRect.new()
	rect.color = Color(1.0, 1.0, 0.9, 0.75)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.add_child(rect)
	get_tree().root.add_child(flash)
	
	var tween := rect.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(rect, "color:a", 0.0, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

func _spawn_floating_text(txt: String, col: Color) -> void:
	var label := Label.new()
	label.text = txt
	label.global_position = global_position - Vector2(70, 30)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", col)
	label.z_index = 50
	get_tree().current_scene.add_child(label)
	
	var t := label.create_tween()
	t.tween_property(label, "position:y", label.position.y - 50.0, 0.9)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.2)
	t.tween_callback(label.queue_free)
