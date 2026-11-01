extends Area2D

@export var gold_amount: int = 50

@onready var sprite: Sprite2D = $Sprite2D
var is_collected: bool = false

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	
	# Yere düşme ve parıldama animasyonu
	scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15)
	
	# Hafif sallanma
	_idle_bob()

func _idle_bob() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(sprite, "rotation", 0.1, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "rotation", -0.1, 0.4).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body and body.is_in_group("player"):
		_open_chest(body)

func _open_chest(player: Node2D) -> void:
	is_collected = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	# Şans faktörüne göre çoklu yükseltme (Vampire Survivors Jackpot Sandık)
	var luck: float = player.luck_mult if player and "luck_mult" in player else 1.0
	var upgrades_count: int = 1
	var roll := randf()
	if luck > 1.1 and roll < (luck - 1.0) * 0.3:
		upgrades_count = 3
	elif luck > 1.0 and roll < (luck - 1.0) * 0.6:
		upgrades_count = 2
		
	var final_gold: int = gold_amount * upgrades_count
	if player.has_method("add_coins"):
		player.add_coins(final_gold)
		
	# Yükseltme seçeneklerini aç
	var menu = get_tree().current_scene.get_node_or_null("LevelUpMenu")
	if menu and menu.has_method("show_level_up_options"):
		for u in range(upgrades_count):
			menu.show_level_up_options()
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("coin", 0.05, 3.0)
		audio.play_sfx("level_up", 0.0, 2.0)
		
	# Patlama ve yok olma efekti
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(1.8, 1.8), 0.2)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(queue_free)
