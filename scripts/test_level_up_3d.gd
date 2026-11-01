extends SceneTree

# Test level up and XP collection in 3D without errors
var timer: float = 0.0
var step: int = 0
var main3d: Node = null

func _init() -> void:
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	if step == 0:
		step = 1
		print("[3D LEVEL UP TEST] Loading main_3d.tscn...")
		var sc = load("res://scenes/world/main_3d.tscn")
		main3d = sc.instantiate()
		root.add_child(main3d)
		return
		
	timer += 0.016
	if step == 1 and timer > 0.4:
		step = 2
		print("[3D LEVEL UP TEST] Triggering add_xp on Player3D to level up...")
		var p = main3d.get_node_or_null("Player3D")
		if p:
			# Trigger enough XP to level up
			p.add_xp(50)
			print("[3D LEVEL UP TEST] Player leveled up to: ", p.current_level)
		else:
			printerr("[3D LEVEL UP TEST] Player3D not found!")
		
	if step == 2 and timer > 0.8:
		step = 3
		var lvl_menu = main3d.get_node_or_null("LevelUpMenu")
		if lvl_menu and lvl_menu.visible:
			print("[3D LEVEL UP TEST] LevelUpMenu successfully opened in 3D world! PASS")
		else:
			print("[3D LEVEL UP TEST] LevelUpMenu check: visible=", lvl_menu.visible if lvl_menu else "null")
		quit(0)
