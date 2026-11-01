extends Node2D

var radius: float = 10.0
var max_radius: float = 135.0
var duration: float = 0.35
var elapsed: float = 0.0

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	var t := elapsed / duration
	radius = lerpf(10.0, max_radius, ease(t, -2.0))
	queue_redraw()
	if elapsed >= duration:
		queue_free()

func _draw() -> void:
	var alpha := 1.0 - (elapsed / duration)
	# Yeşil-turuncu kimyasal alev patlama dalgası
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.6, 0.1, alpha * 0.9), 4.0)
	draw_arc(Vector2.ZERO, radius * 0.85, 0, TAU, 32, Color(0.2, 1.0, 0.4, alpha * 0.8), 3.0)
	draw_circle(Vector2.ZERO, radius * 0.4, Color(0.8, 1.0, 0.2, alpha * 0.3))
