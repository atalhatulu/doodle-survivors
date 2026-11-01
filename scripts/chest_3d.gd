extends Area3D

@export var gold_amount: int = 75

@onready var sprite: Sprite3D = $Sprite3D
var is_collected: bool = false

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2 # Player3D layer
	body_entered.connect(_on_body_entered)
	
	# Yere düşme ve parıldama animasyonu
	if sprite:
		sprite.scale = Vector3(0.01, 0.01, 0.01)
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector3(1.25, 1.25, 1.25), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(sprite, "scale", Vector3.ONE, 0.16)
	
	_idle_bob()

func _idle_bob() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(sprite, "rotation:z", 0.08, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "rotation:z", -0.08, 0.45).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return
	if body and body.is_in_group("player"):
		_open_chest(body)

func _open_chest(player: Node3D) -> void:
	is_collected = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var luck: float = player.luck_mult if player and "luck_mult" in player else 1.0
	var upgrades_count: int = 1
	var roll := randf()
	if luck > 1.1 and roll < (luck - 1.0) * 0.35:
		upgrades_count = 3
	elif luck > 1.0 and roll < (luck - 1.0) * 0.65:
		upgrades_count = 2
		
	var final_gold: int = gold_amount * upgrades_count
	if player.has_method("add_coin"):
		player.add_coin(final_gold)
	elif player.has_method("add_coins"):
		player.add_coins(final_gold)
		
	# LevelUpMenu evrim veya sandık ödüllerini aç
	var tree := get_tree()
	var menu: Node = null
	if tree and tree.current_scene:
		menu = tree.current_scene.get_node_or_null("LevelUpMenu")
	if not menu and tree and tree.root:
		menu = tree.root.find_child("LevelUpMenu", true, false)
		
	if menu and menu.has_method("show_level_up_options"):
		for u in range(upgrades_count):
			menu.show_level_up_options(true)
			
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("coin", 0.05, 3.0)
		audio.play_sfx("level_up", 0.0, 2.0)
		
	# Patlama ve havaya uçuşma efekti
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", sprite.scale * 1.8, 0.22)
	tw.tween_property(sprite, "position:y", sprite.position.y + 1.2, 0.22)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(queue_free)
