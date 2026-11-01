extends Area2D

@export var damage: float = 24.0
@export var life_time: float = 3.2
@export var radius: float = 45.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var elapsed: float = 0.0
var tick_timer: float = 0.0
var max_life: float = 3.2
var bubble_offset: float = 0.0

func _ready() -> void:
	z_index = -2
	collision_layer = 0
	collision_mask = 1
	var dur_mult: float = player.duration_mult if player and "duration_mult" in player else 1.0
	max_life = life_time * dur_mult
	bubble_offset = randf() * TAU
	
	scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= max_life:
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tw.chain().tween_callback(queue_free)
		set_physics_process(false)
		return
		
	tick_timer += delta
	if tick_timer >= 0.25:
		tick_timer = 0.0
		_deal_pool_damage()
		
	queue_redraw()

func _draw() -> void:
	var alpha: float = clampf(1.0 - (elapsed / max_life), 0.2, 0.85)
	var pulse := sin(elapsed * 5.0 + bubble_offset) * 3.0
	var r := radius + pulse
	
	# Zemin eriyik lav göleti
	draw_circle(Vector2.ZERO, r, Color(0.9, 0.25, 0.05, alpha * 0.7))
	draw_circle(Vector2.ZERO, r * 0.65, Color(1.3, 0.6, 0.1, alpha * 0.9))
	draw_circle(Vector2.ZERO, r * 0.35, Color(1.6, 1.2, 0.3, alpha))
	
	# Lav kabarcıkları
	for b in range(3):
		var b_ang := bubble_offset + float(b) * 2.1 + elapsed * 2.0
		var b_dist := (r * 0.45) * sin(elapsed * 3.0 + float(b))
		var b_pos := Vector2(cos(b_ang), sin(b_ang)) * b_dist
		draw_circle(b_pos, 3.5, Color(1.6, 1.4, 0.5, alpha))

func _deal_pool_damage() -> void:
	var bodies := get_overlapping_bodies()
	if bodies.is_empty():
		return
	var p_dmg: float = player.damage_multiplier if player and "damage_multiplier" in player else 1.0
	var final_dmg := damage * p_dmg
	for b in bodies:
		if b and is_instance_valid(b) and b.has_method("take_damage"):
			if "is_dead" in b and b.is_dead:
				continue
			b.take_damage(final_dmg, false, global_position, "weapon_evo_hellfire_storm")
			if b.has_method("apply_status"):
				b.apply_status("burn", 2.5, 15.0)
