extends Node2D

@export var radius: float = 95.0
@export var damage_per_tick: float = 16.0
@export var duration: float = 3.5

var tick_timer: float = 0.0
var elapsed: float = 0.0
var player: Node2D = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	queue_redraw()
	scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	elapsed += delta
	tick_timer += delta
	
	if tick_timer >= 0.35:
		tick_timer = 0.0
		_deal_poison_pulse()
		
	if elapsed >= duration - 0.5:
		modulate.a = maxf(0.0, (duration - elapsed) / 0.5)
		
	if elapsed >= duration:
		queue_free()

func _draw() -> void:
	# Yoğun asidik mor-yeşil zehir dumanı perdesi
	draw_circle(Vector2.ZERO, radius, Color(0.2, 0.7, 0.3, 0.35))
	draw_circle(Vector2(-15, -10), radius * 0.7, Color(0.4, 0.2, 0.6, 0.25))
	draw_circle(Vector2(20, 15), radius * 0.6, Color(0.15, 0.85, 0.4, 0.3))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.4, 0.9, 0.4, 0.6), 2.0)

func _deal_poison_pulse() -> void:
	var mult: float = player.damage_multiplier if (player and "damage_multiplier" in player) else 1.0
	var final_dmg: float = damage_per_tick * mult
	var enemies := get_tree().get_nodes_in_group("enemies")
	
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			if global_position.distance_to(e.global_position) <= radius:
				if player and player.has_method("record_weapon_damage"):
					player.record_weapon_damage("dash_toxic_flash", final_dmg)
				if e.has_method("take_damage"):
					e.take_damage(final_dmg, false, global_position)
				if e.has_method("apply_status"):
					e.apply_status("poison", 3.0, 10.0)
