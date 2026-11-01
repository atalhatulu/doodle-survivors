extends Area2D

@export var coin_value: int = 1
@export var magnet_speed: float = 520.0

@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D = null
var is_attracted: bool = false
var is_collected: bool = false
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	set_deferred("monitoring", false)
	set_deferred("monitorable", true)
	set_process(false)
	
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func start_attraction(p: Node2D, override_speed: float = -1.0) -> void:
	if is_collected:
		return
	player = p
	is_attracted = true
	if override_speed > 0.0:
		magnet_speed = override_speed
	set_process(true)

func _process(delta: float) -> void:
	if not is_attracted or is_collected:
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
	
	if dist < 24.0:
		_collect(player)

func _collect(target: Node2D) -> void:
	if is_collected:
		return
	is_collected = true
	var p: Node2D = target if (target and target.is_in_group("player")) else (get_tree().get_first_node_in_group("player") if get_tree() else null)
	if p and p.has_method("add_coins"):
		p.add_coins(coin_value)
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_sfx("coin", 0.12)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()

