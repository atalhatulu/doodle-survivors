extends SceneTree

var timer: float = 0.0
var step: int = 0
var main3d_instance: Node = null

func _init() -> void:
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	if step == 0:
		step = 1
		print("[TRUE 3D TEST] Loading scenes/world/main_3d.tscn...")
		var main_scene = load("res://scenes/world/main_3d.tscn")
		main3d_instance = main_scene.instantiate()
		root.add_child(main3d_instance)
		return
		
	timer += 0.016
	
	if step == 1 and timer > 0.8:
		# Oyuncunun görüş alanına devasa meşe ağacı, kadim ağaç ve dark fantasy yaratıkları yerleştir
		var giant_tree_sc = load("res://scenes/world/giant_tree_3d.tscn")
		# 1. Sol arkada Devasa Kadim Ağaç
		var gt1 = giant_tree_sc.instantiate()
		gt1.position = Vector3(-6.5, 0, -19.0)
		var sp_gt1 = gt1.get_node_or_null("Sprite3D")
		if sp_gt1:
			sp_gt1.texture = load("res://assets/sprites/environment/prop_giant_ancient_tree.png")
			sp_gt1.pixel_size = 0.015
		main3d_instance.add_child(gt1)

		# 2. Sağ arkada Devasa Meşe Ağacı
		var gt2 = giant_tree_sc.instantiate()
		gt2.position = Vector3(8.5, 0, -22.0)
		var sp_gt2 = gt2.get_node_or_null("Sprite3D")
		if sp_gt2:
			sp_gt2.texture = load("res://assets/sprites/environment/prop_giant_oak_tree.png")
			sp_gt2.pixel_size = 0.016
		main3d_instance.add_child(gt2)

		var enemy_sc = load("res://scenes/enemies/enemy_3d_base.tscn")
		# 1. Armored turtle
		var e1 = enemy_sc.instantiate()
		e1.position = Vector3(0, 0, -7.5)
		var sp1 = e1.get_node_or_null("Sprite3D")
		if sp1:
			sp1.texture = load("res://assets/sprites/enemies/enemy_armored_turtle.png")
			sp1.pixel_size = 0.0085
		main3d_instance.add_child(e1)
		
		# 2. Spider
		var e2 = enemy_sc.instantiate()
		e2.position = Vector3(-3.0, 0, -6.0)
		var sp2 = e2.get_node_or_null("Sprite3D")
		if sp2:
			sp2.texture = load("res://assets/sprites/enemies/enemy_spider.png")
			sp2.pixel_size = 0.0075
		main3d_instance.add_child(e2)

		# 3. Plant monster
		var e3 = enemy_sc.instantiate()
		e3.position = Vector3(3.5, 0, -8.5)
		var sp3 = e3.get_node_or_null("Sprite3D")
		if sp3:
			sp3.texture = load("res://assets/sprites/enemies/enemy_plant_monster.png")
			sp3.pixel_size = 0.0085
		main3d_instance.add_child(e3)

		# 4. Spiky ghost (Uçan mistik)
		var e4 = enemy_sc.instantiate()
		e4.position = Vector3(-4.5, 0.8, -10.5)
		var sp4 = e4.get_node_or_null("Sprite3D")
		if sp4:
			sp4.texture = load("res://assets/sprites/enemies/enemy_spiky_ghost.png")
			sp4.pixel_size = 0.0080
		main3d_instance.add_child(e4)
		
		var coin_sc = load("res://scenes/pickups/coin_3d.tscn")
		var c = coin_sc.instantiate()
		c.position = Vector3(2.0, 0, -4.5)
		main3d_instance.add_child(c)
		
		# Görsel & Davranış Cilası Doğrulaması için Sahneye Efekt ve Mermiler Ekle
		var proj_sc = load("res://scenes/weapons/proj_blade_3d.tscn")
		if proj_sc:
			# 1. Kılıç Kavis Kesme İzi (Hades Çift Renk Kavis Dalgası)
			var p_sword = proj_sc.instantiate()
			p_sword.position = Vector3(0.8, 1.1, -4.0)
			p_sword.configure(Vector3.FORWARD, 55.0, 0.0, "res://assets/sprites/weapons/proj_sword_heavy_slash.png", 0.008, 0.0, 99, 1.5, false, "melee_arc", main3d_instance.get_node_or_null("Player3D"))
			main3d_instance.add_child(p_sword)
			
			# 2. Balta ve Yıldırım Zemin Darbe Çatlağı (Crater)
			var p_crater = proj_sc.instantiate()
			p_crater.position = Vector3(-1.8, 0.025, -5.5)
			p_crater.configure(Vector3.ZERO, 0.0, 0.0, "res://assets/sprites/weapons/ground_impact_crater.png", 0.008, 0.0, 99, 3.0, false, "targeted")
			var sp_cr = p_crater.get_node_or_null("Sprite3D")
			if sp_cr:
				sp_cr.billboard = BaseMaterial3D.BILLBOARD_DISABLED
				sp_cr.rotation = Vector3(-PI * 0.5, 0.4, 0.0)
			main3d_instance.add_child(p_crater)
			
			# 3. Şimşek / Yıldırım Arkı (Gökten inen zikzak rünik ark)
			var p_lightning = proj_sc.instantiate()
			p_lightning.position = Vector3(1.8, 2.5, -6.5)
			p_lightning.configure(Vector3.DOWN, 85.0, 10.0, "res://assets/sprites/weapons/proj_lightning_bolt.png", 0.010, 0.0, 99, 1.5, false, "sky_strike")
			main3d_instance.add_child(p_lightning)
		
		step = 2
		return

	if step == 2 and timer > 1.2:
		step = 3
		print("[TRUE 3D TEST] Capturing TRUE 3D TPS screenshot...")
		var image = root.get_viewport().get_texture().get_image()
		if image:
			var err = image.save_png("res://docs/test_true_3d_tps.png")
			print("[TRUE 3D TEST] Saved test_true_3d_tps.png, err code: ", err)
		quit(0)
