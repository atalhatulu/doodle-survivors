extends Node2D

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 280.0
var life_time: float = 0.65

func setup(amount: float, is_crit: bool, spawn_pos: Vector2) -> void:
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var meta = tree.root.get_node_or_null("MetaProgression") if (tree and tree.root) else null
	if meta and not bool(meta.settings.get("show_damage_numbers", true)):
		queue_free()
		return
		
	global_position = spawn_pos + Vector2(randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
	
	var label: Label = get_node_or_null("Label")
	if not label:
		return
		
	var text_val: String = str(int(round(amount)))
	label.text = text_val
	
	if is_crit:
		label.text = "!" + text_val + "!"
		label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.15, 1.0)) # Kırmızı/Turuncu Kritik
		label.add_theme_font_size_override("font_size", 22)
		scale = Vector2(1.4, 1.4)
		velocity = Vector2(randf_range(-70.0, 70.0), randf_range(-180.0, -220.0))
	else:
		label.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08, 1.0)) # Mürekkep Siyahı
		label.add_theme_font_size_override("font_size", 16)
		scale = Vector2(1.0, 1.0)
		velocity = Vector2(randf_range(-45.0, 45.0), randf_range(-130.0, -160.0))
		
	# Squash & stretch + Fade out tween
	var tween := create_tween()
	tween.tween_property(self, "scale", scale * 1.15, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", scale * 0.7, life_time - 0.1)
	
	var alpha_tween := create_tween()
	alpha_tween.tween_interval(0.3)
	alpha_tween.tween_property(self, "modulate:a", 0.0, life_time - 0.3)
	alpha_tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	velocity.y += gravity * delta
	position += velocity * delta
