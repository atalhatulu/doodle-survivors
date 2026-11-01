extends Area2D

@export var speed: float = 880.0
@export var damage: float = 42.0
@export var life_time: float = 3.0
@export var max_pierce: int = 8

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
	queue_redraw()
	
	var player := get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) > 1350.0:
		queue_free()

func _draw() -> void:
	# Elektrikli ok kuyruğu çiz
	draw_line(Vector2(-24, 0), Vector2(16, 0), Color(0.4, 0.9, 1.8, 0.9), 2.5, true)
	draw_circle(Vector2(16, 0), 3.5, Color(1.8, 2.0, 2.5, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if body and body.has_method("take_damage"):
		if "is_dead" in body and body.is_dead:
			return
		var id := body.get_instance_id()
		if not hit_enemies.has(id):
			hit_enemies[id] = true
			body.take_damage(damage, is_crit, global_position, "weapon_evo_storm_quiver")
			if body.has_method("apply_status"):
				body.apply_status("shock", 3.0)
			
			_trigger_chain_lightning(body.global_position, id)
			
			pierce_count += 1
			if pierce_count >= max_pierce:
				set_deferred("monitoring", false)
				set_deferred("monitorable", false)
				call_deferred("queue_free")

func _trigger_chain_lightning(origin_pos: Vector2, hit_id: int) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var chained := 0
	for e in enemies:
		if not is_instance_valid(e) or e.get_instance_id() == hit_id or ("is_dead" in e and e.is_dead):
			continue
		var dist := origin_pos.distance_to(e.global_position)
		if dist <= 190.0:
			e.take_damage(damage * 0.55, is_crit, origin_pos, "weapon_evo_storm_quiver")
			if e.has_method("apply_status"):
				e.apply_status("shock", 2.5)
			chained += 1
			if chained >= 2:
				break
