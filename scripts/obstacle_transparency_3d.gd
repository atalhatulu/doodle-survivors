extends StaticBody3D

@onready var sprite: Sprite3D = $Sprite3D

var target_alpha: float = 1.0
var current_alpha: float = 1.0
var wind_time: float = 0.0
var sway_intensity: float = 0.0
var base_rotation_z: float = 0.0

func _ready() -> void:
	add_to_group("camera_fading_obstacles")
	if sprite:
		current_alpha = sprite.modulate.a
		base_rotation_z = sprite.rotation.z
	# Çim, çiçek veya çalı ise rüzgarda hafifçe salınsın
	var scene_name = name.to_lower()
	if scene_name.begins_with("grass") or scene_name.begins_with("flower"):
		sway_intensity = randf_range(0.06, 0.12)
		wind_time = randf_range(0.0, 10.0)
	elif scene_name.begins_with("bush") or scene_name.begins_with("tree") or scene_name.begins_with("pine"):
		sway_intensity = randf_range(0.015, 0.035)
		wind_time = randf_range(0.0, 10.0)

func set_obstacle_alpha(alpha: float) -> void:
	target_alpha = alpha

func _process(delta: float) -> void:
	if not sprite:
		return
	if not is_equal_approx(current_alpha, target_alpha):
		current_alpha = move_toward(current_alpha, target_alpha, delta * 4.5)
		sprite.modulate.a = current_alpha
	if sway_intensity > 0.0:
		wind_time += delta * 2.8
		sprite.rotation.z = base_rotation_z + sin(wind_time) * sway_intensity
