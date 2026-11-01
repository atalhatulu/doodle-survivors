extends Area3D

@onready var sprite: Sprite3D = $Sprite3D
var player: Node3D = null
var is_attracted: bool = false
var float_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	float_time += delta * 4.0
	if sprite:
		sprite.position.y = 0.25 + sin(float_time) * 0.06
		
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var d = global_position.distance_to(player.global_position)
	var mag_mult: float = float(player.get("magnet_range_mult")) if "magnet_range_mult" in player else 1.0
	if d < (6.0 * mag_mult):
		is_attracted = true
		
	if is_attracted:
		global_position = global_position.move_toward(player.global_position + Vector3(0, 0.8, 0), delta * 18.0)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("add_coin"):
		body.add_coin(1)
		queue_free()
