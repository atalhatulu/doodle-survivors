extends Area2D

@export var speed: float = 600.0
@export var damage: float = 30.0
@export var life_time: float = 3.0
@export var max_pierce: int = 4

var direction: Vector2 = Vector2.RIGHT
var pierce_count: int = 0
var hit_enemies: Dictionary = {}
var is_crit: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	rotation = direction.angle() + PI * 0.25 # Kılıç çapraz fırlasın
	
	var timer := get_tree().create_timer(life_time, false)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	var player := get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) > 1000.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body and body.has_method("take_damage"):
		var id := body.get_instance_id()
		if not hit_enemies.has(id):
			hit_enemies[id] = true
			body.take_damage(damage, is_crit)
			pierce_count += 1
			if pierce_count >= max_pierce:
				set_deferred("monitoring", false)
				call_deferred("queue_free")
