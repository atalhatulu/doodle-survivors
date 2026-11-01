extends Node2D

enum Type { CIRCLE, LINE }

var telegraph_type: Type = Type.CIRCLE
var radius: float = 190.0
var line_width: float = 110.0
var line_length: float = 450.0
var target_direction: Vector2 = Vector2.RIGHT

var duration: float = 1.2
var elapsed: float = 0.0
var is_triggered: bool = false
var callback: Callable

func setup_circle(rad: float, dur: float, on_complete: Callable) -> void:
	telegraph_type = Type.CIRCLE
	radius = rad
	duration = dur
	callback = on_complete
	queue_redraw()

func setup_line(dir: Vector2, width: float, length: float, dur: float, on_complete: Callable) -> void:
	telegraph_type = Type.LINE
	target_direction = dir.normalized()
	line_width = width
	line_length = length
	duration = dur
	callback = on_complete
	rotation = target_direction.angle()
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= duration and not is_triggered:
		is_triggered = true
		if callback.is_valid():
			callback.call()
		_fade_out()

func _draw() -> void:
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var pulse := (sin(elapsed * 18.0) + 1.0) * 0.5
	var edge_color := Color(1.0, 0.15, 0.15, 0.85 + pulse * 0.15)
	
	if telegraph_type == Type.CIRCLE:
		# Zemin uyarı dairesi: Dış kırmızı sınır
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48, edge_color, 3.5)
		# İç dolgu: Zamanla genişleyen kırmızı uyarı
		var fill_rad := radius * progress
		draw_circle(Vector2.ZERO, fill_rad, Color(0.95, 0.1, 0.1, 0.25 + pulse * 0.1))
	elif telegraph_type == Type.LINE:
		# Zemin hücum hattı: Kırmızı dikdörtgen
		var rect := Rect2(0, -line_width * 0.5, line_length, line_width)
		draw_rect(rect, edge_color, false, 3.5)
		var fill_rect := Rect2(0, -line_width * 0.5, line_length * progress, line_width)
		draw_rect(fill_rect, Color(0.95, 0.1, 0.1, 0.25 + pulse * 0.1), true)

func _fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
