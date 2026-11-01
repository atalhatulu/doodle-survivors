extends SceneTree

var timer: float = 0.0
var step: int = 0
var tps_instance: Node = null

func _init() -> void:
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	if step == 0:
		step = 1
		print("[TPS SCREENSHOT] Loading TPSScreenViewport scene...")
		var tps_scene = load("res://scenes/world/tps_screen_viewport.tscn")
		tps_instance = tps_scene.instantiate()
		root.add_child(tps_instance)
		return
		
	timer += 0.016
	
	if step == 1 and timer > 0.8:
		step = 2
		print("[TPS SCREENSHOT] Capturing real TPS perspective screenshot...")
		var image = root.get_viewport().get_texture().get_image()
		if image:
			var err = image.save_png("res://docs/test_real_tps_perspective.png")
			print("[TPS SCREENSHOT] Saved test_real_tps_perspective.png, err code: ", err)
		else:
			print("[TPS SCREENSHOT] Image was null")
		quit(0)
