extends Area2D

@export var speed: float = 450.0
@export var damage: float = 28.0
@export var max_distance: float = 380.0
@export var max_hits_per_leg: int = 4

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var returning: bool = false
var player: Node2D = null
var hit_enemies: Dictionary = {}
var is_crit: bool = false
var leg_hits: int = 0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	rotation += delta * 16.0
	
	if not returning:
		position += direction * speed * delta
		distance_traveled += speed * delta
		if distance_traveled >= max_distance or leg_hits >= max_hits_per_leg:
			returning = true
			leg_hits = 0
			hit_enemies.clear() # Dönüş yolunda tekrar vurabilir
	else:
		if not player or not is_instance_valid(player):
			player = get_tree().get_first_node_in_group("player")
		if player:
			var return_dir := (player.global_position - global_position).normalized()
			position += return_dir * (speed * 1.2) * delta
			if global_position.distance_to(player.global_position) < 30.0:
				queue_free()
		else:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body and body.has_method("take_damage"):
		if "is_dead" in body and body.is_dead:
			return
		var id := body.get_instance_id()
		if not hit_enemies.has(id):
			hit_enemies[id] = true
			leg_hits += 1
			body.take_damage(damage, is_crit, global_position, "weapon_boomerang")
			if returning and leg_hits >= max_hits_per_leg:
				queue_free()
