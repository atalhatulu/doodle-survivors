extends Area2D

@export var coin_value: int = 1
@export var magnet_speed: float = 520.0

@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D = null
var is_attracted: bool = false
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var dist := global_position.distance_to(player.global_position)
	var reach: float = 200.0
	if player and "magnet_range_mult" in player:
		reach *= player.magnet_range_mult
		
	if dist < reach:
		is_attracted = true
		
	if is_attracted:
		var dir := (player.global_position - global_position).normalized()
		velocity = velocity.move_toward(dir * magnet_speed, 1800.0 * delta)
		global_position += velocity * delta
		
		if dist < 24.0:
			_collect(player)

func _on_body_entered(body: Node2D) -> void:
	_collect(body)

func _on_area_entered(area: Area2D) -> void:
	_collect(area.get_parent())

func _collect(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	var p: Node2D = target if target.is_in_group("player") else get_tree().get_first_node_in_group("player")
	if p and p.has_method("add_coins"):
		p.add_coins(coin_value)
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_sfx("coin", 0.12)
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		queue_free()
