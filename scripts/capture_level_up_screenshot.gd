extends SceneTree

var timer: float = 0.0
var step: int = 0
var main3d: Node = null

func _init() -> void:
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	if step == 0:
		step = 1
		print("[CAPTURE LEVEL UP] Loading scenes/world/main_3d.tscn...")
		var sc = load("res://scenes/world/main_3d.tscn")
		main3d = sc.instantiate()
		root.add_child(main3d)
		return
		
	timer += 0.016
	if step == 1 and timer > 0.4:
		step = 2
		var p = main3d.get_node_or_null("Player3D")
		if p:
			p.add_xp(50)
			print("[CAPTURE LEVEL UP] Triggered level up. Player level: ", p.current_level)
		
	if step == 2 and timer > 0.9:
		step = 3
		print("[CAPTURE LEVEL UP] Capturing screenshot...")
		var img: Image = root.get_viewport().get_texture().get_image()
		if img and not img.is_empty():
			var save_path = "docs/test_level_up_cards_readability.png"
			var err = img.save_png(save_path)
			print("[CAPTURE LEVEL UP] Saved %s, err code: %d" % [save_path, err])
		else:
			print("[CAPTURE LEVEL UP] Failed to get viewport image!")
		quit(0)
