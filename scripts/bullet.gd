extends Area2D

@export var speed: float = 650.0
@export var damage: float = 15.0
@export var life_time: float = 3.5
@export var spin_speed: float = 0.0
@export var max_pierce: int = 1

var direction: Vector2 = Vector2.RIGHT
var is_crit: bool = false
var pierce_count: int = 0
var hit_enemies: Dictionary = {}

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()
	
	var timer := get_tree().create_timer(life_time, false)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if spin_speed != 0.0:
		$Sprite2D.rotation += spin_speed * delta
		
	# Ekran dışı mesafe kontrolü (Oyuncudan 950 pikselden fazla uzaklaşırsa sil)
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
				set_deferred("monitorable", false)
				call_deferred("queue_free")
