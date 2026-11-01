extends SceneTree

# Test and capture screenshots for visual verification
var timer: float = 0.0
var step: int = 0
var main_instance: Node = null

func _init() -> void:
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	if step == 0:
		step = 1
		print("[SCREENSHOT TEST] Loading main game scene...")
		var main_scene = load("res://scenes/world/main.tscn")
		main_instance = main_scene.instantiate()
		root.add_child(main_instance)
		return
		
	timer += 0.016
	
	# Wait 30 frames for chunks and sprites to initialize and render
	if step == 1 and timer > 0.6:
		# Oyuncunun yakınına test için bir altın sikke örneği ekle (çekim alanı dışında, net görülebilir)
		var coin_sc = load("res://scenes/pickups/coin_pickup.tscn")
		var coin = coin_sc.instantiate()
		coin.position = Vector2(240, -50)
		main_instance.add_child(coin)
		step = 2
		return

	if step == 2 and timer > 0.9:
		step = 3
		print("[SCREENSHOT TEST] Capturing gameplay screenshot...")
		var image = root.get_viewport().get_texture().get_image()
		if image:
			var err = image.save_png("res://docs/test_tps_gameplay.png")
			print("[SCREENSHOT TEST] Saved test_tps_gameplay.png, err code: ", err)
		else:
			print("[SCREENSHOT TEST] Viewport image was null")
		
		# Now test character select menu
		if main_instance:
			main_instance.queue_free()
		var char_scene = load("res://scenes/ui/character_select_menu.tscn")
		var char_inst = char_scene.instantiate()
		root.add_child(char_inst)
		main_instance = char_inst
		timer = 0.0
		return
		
	if step == 3 and timer > 0.4:
		step = 4
		print("[SCREENSHOT TEST] Capturing character select screenshot...")
		var image = root.get_viewport().get_texture().get_image()
		if image:
			var err = image.save_png("res://docs/test_char_select.png")
			print("[SCREENSHOT TEST] Saved test_char_select.png, err code: ", err)
		quit(0)
