extends StaticBody3D

@export var max_health: float = 20.0
@onready var sprite: Sprite3D = $Sprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var health: float = 20.0
var is_broken: bool = false
var base_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	add_to_group("destructibles")
	add_to_group("enemies") # Otomatik hedefleme yapan silahlar da varillere vurabilsin
	health = max_health
	if sprite:
		base_scale = sprite.scale

func take_damage(amount: float) -> void:
	if is_broken:
		return
		
	health -= amount
	
	var dmg_sc = load("res://scenes/ui/damage_number_3d.tscn")
	if dmg_sc:
		var num = dmg_sc.instantiate()
		var main = get_parent()
		if not main: main = get_tree().current_scene
		if main:
			main.add_child(num)
			num.setup(amount, false, global_position + Vector3(0, 0.9, 0))
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.1, 1.2)
		
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "scale", base_scale * 1.25, 0.05)
		tw.parallel().tween_property(sprite, "modulate", Color(2.0, 1.5, 1.0), 0.05)
		tw.tween_property(sprite, "scale", base_scale, 0.08)
		tw.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.08)
		
	if health <= 0.0:
		_break_barrel()

func _break_barrel() -> void:
	if is_broken:
		return
	is_broken = true
	
	remove_from_group("enemies")
	remove_from_group("destructibles")
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.15, 1.8)
		
	_drop_loot()
	
	# Parçalanma animasyonu (hafif sıçrama ve solma)
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "scale", base_scale * 1.35, 0.08)
		tw.parallel().tween_property(sprite, "position:y", sprite.position.y + 0.35, 0.08)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tw.tween_callback(queue_free)
	else:
		queue_free()

func _drop_loot() -> void:
	var main = get_parent()
	if not main:
		main = get_tree().current_scene
	if not main:
		return
		
	var roll = randf()
	if roll < 0.45:
		# Altın Sikke (Gold Coin 3D)
		var coin_sc = load("res://scenes/pickups/coin_3d.tscn")
		if coin_sc:
			var c = coin_sc.instantiate()
			c.position = Vector3(global_position.x + randf_range(-0.4, 0.4), 0.0, global_position.z + randf_range(-0.4, 0.4))
			main.add_child(c)
	elif roll < 0.85:
		# XP Kristali (Gem 3D)
		var gem_sc = load("res://scenes/pickups/gem_3d.tscn")
		if gem_sc:
			var g = gem_sc.instantiate()
			g.position = Vector3(global_position.x + randf_range(-0.4, 0.4), 0.0, global_position.z + randf_range(-0.4, 0.4))
			g.xp_value = randi_range(25, 60)
			main.add_child(g)
	else:
		# Şanslı drop: Birden fazla sikke
		var coin_sc = load("res://scenes/pickups/coin_3d.tscn")
		if coin_sc:
			for i in range(3):
				var c = coin_sc.instantiate()
				c.position = Vector3(global_position.x + randf_range(-0.6, 0.6), 0.0, global_position.z + randf_range(-0.6, 0.6))
				main.add_child(c)
