extends Node3D

var velocity: Vector3 = Vector3.ZERO
var gravity: float = 8.0
var life_time: float = 0.75

func setup(amount: float, is_crit: bool, spawn_pos: Vector3) -> void:
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var meta = tree.root.get_node_or_null("MetaProgression") if (tree and tree.root) else null
	if meta and not bool(meta.settings.get("show_damage_numbers", true)):
		queue_free()
		return

	global_position = spawn_pos + Vector3(randf_range(-0.35, 0.35), randf_range(0.1, 0.4), randf_range(-0.35, 0.35))

	var label: Label3D = get_node_or_null("Label3D")
	if not label:
		return

	var text_val: String = str(int(round(amount)))
	label.text = text_val

	if is_crit:
		label.text = "!" + text_val + "!"
		label.modulate = Color(1.0, 0.25, 0.15, 1.0) # Kırmızı/Turuncu Kritik
		label.font_size = 46
		scale = Vector3(1.4, 1.4, 1.4)
		velocity = Vector3(randf_range(-1.8, 1.8), randf_range(3.8, 4.8), randf_range(-1.8, 1.8))
	else:
		label.modulate = Color(0.1, 0.08, 0.06, 1.0) # Mürekkep Siyahı / Koyu Gri
		label.font_size = 32
		scale = Vector3(1.0, 1.0, 1.0)
		velocity = Vector3(randf_range(-1.2, 1.2), randf_range(2.8, 3.6), randf_range(-1.2, 1.2))

	# Zıplama & Fade Out Tween
	var tween := create_tween()
	tween.tween_property(self, "scale", scale * 1.2, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", scale * 0.65, life_time - 0.12)

	var alpha_tween := create_tween()
	alpha_tween.tween_interval(0.35)
	alpha_tween.tween_property(label, "modulate:a", 0.0, life_time - 0.35)
	alpha_tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	velocity.y -= gravity * delta
	position += velocity * delta
