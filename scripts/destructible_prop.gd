extends CharacterBody2D

@export var max_health: float = 15.0
@export var prop_type: String = "barrel"

@export var coin_scene: PackedScene = preload("res://scenes/pickups/coin_pickup.tscn")
const XPGem = preload("res://scripts/xp_gem.gd")
@export var xp_scene: PackedScene = preload("res://scenes/pickups/xp_gem.tscn")
@export var meat_scene: PackedScene = preload("res://scenes/pickups/pickup_meat.tscn")
@export var vacuum_scene: PackedScene = preload("res://scenes/pickups/pickup_vacuum.tscn")
@export var nuke_scene: PackedScene = preload("res://scenes/pickups/pickup_nuke.tscn")
@export var damage_number_scene: PackedScene = preload("res://scenes/ui/damage_number.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health: float = 15.0
var is_broken: bool = false
var is_dead: bool = false
var damage: float = 0.0
var base_scale: Vector2 = Vector2(0.55, 0.55)
var hit_tween: Tween

func _ready() -> void:
	add_to_group("destructibles")
	add_to_group("enemies") # Böylece otomatik hedef alan silahlar da vurabilir
	collision_layer = 1
	collision_mask = 0
	health = max_health
	if sprite:
		base_scale = sprite.scale

func take_damage(amount: float, is_crit: bool = false, source_pos: Vector2 = Vector2.ZERO, source_weapon_id: String = "") -> void:
	if is_broken:
		return
		
	health -= amount
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.12, 1.0)
		
	# Hasar sayısı efekti
	if damage_number_scene:
		var dmg_lbl = damage_number_scene.instantiate()
		var target_parent: Node = get_tree().current_scene if (get_tree() and get_tree().current_scene) else (get_tree().root if get_tree() else null)
		if target_parent:
			target_parent.call_deferred("add_child", dmg_lbl)
		if dmg_lbl.has_method("setup"):
			dmg_lbl.call_deferred("setup", amount, is_crit, global_position + Vector2(randf_range(-10, 10), -20))
			
	# Titreme ve vurulma animasyonu
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()
	hit_tween = create_tween()
	hit_tween.tween_property(sprite, "scale", base_scale * 1.25, 0.05)
	hit_tween.parallel().tween_property(sprite, "modulate", Color(1.5, 1.2, 0.8), 0.05)
	hit_tween.tween_property(sprite, "scale", base_scale, 0.1)
	hit_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if health <= 0.0:
		_break_prop()

func _break_prop() -> void:
	if is_broken:
		return
	is_broken = true
	is_dead = true
	
	# Hedef almaktan çıkar
	remove_from_group("enemies")
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("hit", 0.05, 2.0)
		
	_drop_loot()
	
	# Parçalanma animasyonu
	var break_tween := create_tween()
	break_tween.tween_property(sprite, "scale", base_scale * 1.35, 0.08)
	break_tween.parallel().tween_property(sprite, "rotation", randf_range(-0.5, 0.5), 0.08)
	break_tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
	break_tween.tween_callback(queue_free)

func _drop_loot() -> void:
	var roll := randf()
	var drop_node: Node2D = null
	
	if roll < 0.42:
		# Altın Kesesi / Sikke
		if coin_scene:
			drop_node = coin_scene.instantiate()
	elif roll < 0.68:
		# XP Kristali (Havuz sınırına ve en uzaktaki kristal füzyonuna tabi)
		XPGem.spawn_gem(get_tree(), global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8)), randi_range(20, 50))
		return
	elif roll < 0.82:
		# İyileştirici Et (Meat)
		if meat_scene:
			drop_node = meat_scene.instantiate()
	elif roll < 0.90:
		# Vakum Küresi (Vacuum Orb)
		if vacuum_scene:
			drop_node = vacuum_scene.instantiate()
	elif roll < 0.94:
		# Kutsal Işık / Nuke (Rosary)
		if nuke_scene:
			drop_node = nuke_scene.instantiate()
	else:
		# Boş
		return
		
	if drop_node:
		drop_node.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		var target_parent: Node = get_tree().current_scene if (get_tree() and get_tree().current_scene) else (get_tree().root if get_tree() else null)
		if target_parent:
			target_parent.call_deferred("add_child", drop_node)
