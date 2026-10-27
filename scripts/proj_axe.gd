extends Area2D

@export var damage: float = 50.0
@export var speed: float = 460.0
@export var spin_speed: float = 24.0 # Kendi ekseninde fırıl fırıl dönme
@export var max_hits: int = 6 # Delip geçebileceği düşman sayısı
@export var max_distance: float = 1200.0

var direction: Vector2 = Vector2.RIGHT
var velocity: Vector2 = Vector2.ZERO
var player: Node2D = null
var hit_enemies: Dictionary = {}
var is_crit: bool = false
var total_hits: int = 0
var distance_traveled: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")
	
	var timer := get_tree().create_timer(4.0, false)
	timer.timeout.connect(queue_free)

func launch(target_dir: Vector2, initial_speed: float = 460.0) -> void:
	direction = target_dir.normalized()
	speed = initial_speed
	velocity = direction * speed

func _physics_process(delta: float) -> void:
	if velocity == Vector2.ZERO:
		velocity = direction * speed
		
	var move_step := velocity * delta
	global_position += move_step
	distance_traveled += move_step.length()
	
	if sprite:
		sprite.rotation += spin_speed * delta
		
	# Belli süre sonra vurulan düşman hafızasını yenile (çoklu vuruş için)
	for id in hit_enemies.keys():
		hit_enemies[id] -= delta
		if hit_enemies[id] <= 0.0:
			hit_enemies.erase(id)
			
	if distance_traveled >= max_distance:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.12)
		tw.tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body and body.has_method("take_damage"):
		var id := body.get_instance_id()
		if not hit_enemies.has(id):
			hit_enemies[id] = 0.35
			total_hits += 1
			body.take_damage(damage, is_crit, global_position)
			
			if total_hits >= max_hits:
				set_deferred("monitoring", false)
				set_deferred("monitorable", false)
				var tw := create_tween()
				tw.tween_property(self, "modulate:a", 0.0, 0.1)
				tw.tween_callback(queue_free)
