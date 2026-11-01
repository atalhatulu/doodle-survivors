extends Area3D

@export var xp_value: int = 15
@onready var sprite: Sprite3D = $Sprite3D
var player: Node3D = null
var is_attracted: bool = false
var float_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")

var attract_speed: float = 6.0

func _process(delta: float) -> void:
	float_time += delta * 4.0
	if sprite and not is_attracted:
		sprite.position.y = 0.3 + sin(float_time) * 0.08
		
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var d = global_position.distance_to(player.global_position)
	var mag_mult: float = float(player.get("magnet_range_mult")) if "magnet_range_mult" in player else 1.0
	if d < (7.0 * mag_mult):
		if not is_attracted:
			is_attracted = true
			if sprite:
				# Çekilme başlangıcında parlama efekti
				var tw = create_tween()
				tw.tween_property(sprite, "modulate", Color(1.6, 1.8, 2.2, 1.0), 0.12)
				tw.tween_property(sprite, "scale", Vector3(1.25, 0.85, 1.25), 0.10)
		
	if is_attracted:
		attract_speed = move_toward(attract_speed, 32.0, delta * 40.0)
		var target_pt = player.global_position + Vector3(0, 0.8, 0)
		var to_tgt = (target_pt - global_position).normalized()
		global_position += to_tgt * (attract_speed * delta)
		if sprite:
			sprite.rotation.z += delta * 12.0

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("add_xp"):
		body.add_xp(xp_value)
		queue_free()
