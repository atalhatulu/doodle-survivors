extends Area2D

@export var damage: float = 40.0
@export var max_duration: float = 6.0

var player: Node2D = null
var is_triggered: bool = false
var duration: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # layer 1: enemies
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player")
	
	# Görsel çizim: Dikensi tuzak
	queue_redraw()
	scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	duration += delta
	if duration >= max_duration and not is_triggered:
		_fade_out()

func _draw() -> void:
	# Koyu yeşil-siyah dikensi gölge tuzağı halkası
	draw_circle(Vector2.ZERO, 16.0, Color(0.1, 0.2, 0.12, 0.7))
	draw_arc(Vector2.ZERO, 18.0, 0, TAU, 12, Color(0.3, 0.8, 0.4, 0.9), 2.5)
	for i in range(6):
		var ang := i * (TAU / 6.0)
		var p1 := Vector2(cos(ang), sin(ang)) * 12.0
		var p2 := Vector2(cos(ang), sin(ang)) * 24.0
		draw_line(p1, p2, Color(0.2, 0.9, 0.4, 1.0), 2.0)

func _on_body_entered(body: Node2D) -> void:
	if is_triggered:
		return
	if body and body.is_in_group("enemies") and not ("is_dead" in body and body.is_dead):
		_trigger(body)

func _trigger(enemy: Node2D) -> void:
	is_triggered = true
	var mult: float = player.damage_multiplier if (player and "damage_multiplier" in player) else 1.0
	var final_dmg: float = damage * mult
	
	if player and player.has_method("record_weapon_damage"):
		player.record_weapon_damage("dash_shadow_roll", final_dmg)
		
	if enemy.has_method("take_damage"):
		enemy.take_damage(final_dmg, false, global_position)
	if enemy.has_method("apply_status"):
		enemy.apply_status("slow", 3.0)
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("pencil_slash", 0.1, 2.0)
		
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(queue_free)

func _fade_out() -> void:
	is_triggered = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
