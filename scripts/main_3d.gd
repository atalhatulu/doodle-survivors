extends Node3D

@onready var player: CharacterBody3D = $Player3D
@onready var hud: CanvasLayer = $HUD
@onready var level_up_menu: CanvasLayer = $LevelUpMenu
@onready var game_over_menu: CanvasLayer = $GameOverMenu
@onready var obstacles_node: Node3D = $Obstacles3D

var tree_scene: PackedScene = preload("res://scenes/world/tree_3d.tscn")
var giant_tree_scene: PackedScene = preload("res://scenes/world/giant_tree_3d.tscn")
var pine_scene: PackedScene = preload("res://scenes/world/pine_3d.tscn")
var rock_scene: PackedScene = preload("res://scenes/world/rock_3d.tscn")
var bush_scene: PackedScene = preload("res://scenes/world/bush_3d.tscn")
var barrel_scene: PackedScene = preload("res://scenes/world/barrel_3d.tscn")
var shrine_scene: PackedScene = preload("res://scenes/world/shrine_3d.tscn")
var pillar_scene: PackedScene = preload("res://scenes/world/ruin_pillar_3d.tscn")
var lantern_scene: PackedScene = preload("res://scenes/world/lantern_3d.tscn")
var grave_scene: PackedScene = preload("res://scenes/world/grave_3d.tscn")
var jar_scene: PackedScene = preload("res://scenes/world/jar_3d.tscn")
var flower_scene: PackedScene = preload("res://scenes/world/flower_3d.tscn")
var grass_scene: PackedScene = preload("res://scenes/world/grass_clump_3d.tscn")

func _ready() -> void:
	if player:
		if level_up_menu:
			player.level_up.connect(func(lvl): level_up_menu.show_level_up_options())
			level_up_menu.upgrade_selected.connect(func(up_data):
				if player.has_method("apply_upgrade"):
					player.apply_upgrade(up_data)
			)
			
		if game_over_menu:
			player.player_died.connect(func(): game_over_menu.show_game_over(1, 0, 0))

func _populate_obstacles() -> void:
	var placed_solid_positions: Array[Vector3] = []
	var min_solid_dist: float = 2.4 # Katı engeller arasındaki minimum mesafe (çakışmayı önler)
	
	var is_valid_pos = func(test_pos: Vector3, min_d: float) -> bool:
		for p in placed_solid_positions:
			if p.distance_squared_to(test_pos) < (min_d * min_d):
				return false
		return true

	# 1. Heybetli Kadim Sunaklar (Önce yerleştirilir, etrafları ferah kalmalı - min 6.0m)
	for i in range(5):
		var r = randf_range(25.0, 85.0)
		var angle = (float(i) / 5.0) * TAU + randf_range(-0.25, 0.25)
		var s_pos = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
		placed_solid_positions.append(s_pos)
		var s = shrine_scene.instantiate()
		s.position = s_pos
		obstacles_node.add_child(s)

	# 2. Ruh Fenerleri (Glowing Lantern Posts) - Haritayı aydınlatan gizemli fenerler
	for i in range(14):
		var r = randf_range(14.0, 85.0)
		var angle = (float(i) / 14.0) * TAU + randf_range(-0.15, 0.15)
		var l_pos = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
		if is_valid_pos.call(l_pos, 3.5):
			placed_solid_positions.append(l_pos)
			var lantern = lantern_scene.instantiate()
			lantern.position = l_pos
			obstacles_node.add_child(lantern)

	# 3. Antik Harabeler & Sütunlar (Ruin Pillars)
	for i in range(16):
		var tries = 0
		while tries < 10:
			tries += 1
			var r = randf_range(15.0, 95.0)
			var angle = randf() * TAU
			var p_pos = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
			if is_valid_pos.call(p_pos, 3.0):
				placed_solid_positions.append(p_pos)
				var pillar = pillar_scene.instantiate()
				pillar.position = p_pos
				obstacles_node.add_child(pillar)
				break

	# 4. Mezarlık Kümeleri (Graves)
	for i in range(22):
		var tries = 0
		while tries < 10:
			tries += 1
			var r = randf_range(18.0, 105.0)
			var angle = randf() * TAU
			var g_pos = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
			if is_valid_pos.call(g_pos, 2.2):
				placed_solid_positions.append(g_pos)
				var grave = grave_scene.instantiate()
				grave.position = g_pos
				obstacles_node.add_child(grave)
				break

	# 5. Heybetli Kadim ve Meşe Ağaçları (Giant Ancient & Oak Trees) - Harita genelinde ve orta katmanda yükselen devasa ağaçlar
	for i in range(32):
		var tries = 0
		while tries < 10:
			tries += 1
			var r = randf_range(14.0, 95.0)
			var angle = randf() * TAU
			var pos = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
			if is_valid_pos.call(pos, 4.5):
				placed_solid_positions.append(pos)
				var gtree = giant_tree_scene.instantiate()
				gtree.position = pos
				var spr = gtree.get_node_or_null("Sprite3D")
				if spr:
					if randf() < 0.5:
						spr.texture = preload("res://assets/sprites/environment/prop_giant_oak_tree.png")
						spr.pixel_size = randf_range(0.013, 0.017)
					else:
						spr.texture = preload("res://assets/sprites/environment/prop_giant_ancient_tree.png")
						spr.pixel_size = randf_range(0.012, 0.016)
				obstacles_node.add_child(gtree)
				break

	# 6. Orta Boy Ağaçlar, Çamlar, Kayalar, Çalılar ve Kırılabilir Nesneler (Varil & Çömlek)
	var large_obstacles = [tree_scene, pine_scene, rock_scene, bush_scene, barrel_scene, jar_scene]
	var rock_textures = [
		preload("res://assets/sprites/environment/paper_rock_grey.png"),
		preload("res://assets/sprites/environment/paper_rock_large.png"),
		preload("res://assets/sprites/environment/env_boulder_dark.png")
	]
	var tree_textures = [
		preload("res://assets/sprites/environment/paper_s1_01_tree.png"),
		preload("res://assets/sprites/environment/env_tree_small.png")
	]
	var grass_textures = [
		preload("res://assets/sprites/environment/env_grass_tuft.png"),
		preload("res://assets/sprites/environment/paper_grass_tall.png"),
		preload("res://assets/sprites/environment/paper_grass_spiky.png")
	]

	for i in range(110):
		var tries = 0
		while tries < 10:
			tries += 1
			var r = randf_range(8.0, 115.0)
			var angle = randf() * TAU
			var pos = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
			if is_valid_pos.call(pos, min_solid_dist):
				placed_solid_positions.append(pos)
				var chosen_scene: PackedScene = large_obstacles.pick_random()
				var prop = chosen_scene.instantiate()
				prop.position = pos
				var p_spr = prop.get_node_or_null("Sprite3D")
				if p_spr:
					if chosen_scene == rock_scene:
						p_spr.texture = rock_textures.pick_random()
						p_spr.pixel_size = randf_range(0.006, 0.0085)
						if randf() < 0.5:
							p_spr.flip_h = true
					elif chosen_scene == tree_scene:
						p_spr.texture = tree_textures.pick_random()
						p_spr.pixel_size = randf_range(0.008, 0.011)
						if randf() < 0.5:
							p_spr.flip_h = true
				obstacles_node.add_child(prop)
				break

	# 7. Zemin Detayları & Doğa: Işıltılı Karanlık Zambaklar & Ot Kümeleri (Çarpışmasız, özgürce dağılır)
	var flora = [flower_scene, grass_scene]
	for i in range(140):
		var r = randf_range(5.0, 115.0)
		var angle = randf() * TAU
		var plant = flora.pick_random().instantiate()
		plant.position = Vector3(cos(angle) * r, 0.0, sin(angle) * r)
		var pl_spr = plant.get_node_or_null("Sprite3D")
		if pl_spr and plant.name.to_lower().begins_with("grass"):
			pl_spr.texture = grass_textures.pick_random()
			pl_spr.pixel_size = randf_range(0.0055, 0.0085)
			if randf() < 0.5:
				pl_spr.flip_h = true
		obstacles_node.add_child(plant)

	# 8. Ufuk Derinliği ve Devasa Orman Kuşağı (Giant Ancient & Oak Forest Backdrop)
	_populate_perimeter_forest()

func _populate_perimeter_forest() -> void:
	var giant_ancient_tex := preload("res://assets/sprites/environment/prop_giant_ancient_tree.png")
	var giant_oak_tex := preload("res://assets/sprites/environment/prop_giant_oak_tree.png")
	var pine_tex := preload("res://assets/sprites/environment/paper_tree_pine_tall.png")
	
	var backdrop_node := Node3D.new()
	backdrop_node.name = "PerimeterForestBackdrop"
	add_child(backdrop_node)
	
	# Katman 1: İç Perimetre (32m - 55m) - Devasa Meşe ve Kadim Orman Ağaçları (Görseldeki yüksek tepe tacı & gövde)
	for i in range(80):
		var angle := (float(i) / 80.0) * TAU + randf_range(-0.06, 0.06)
		var dist := randf_range(32.0, 55.0)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		
		var sp := Sprite3D.new()
		var is_oak: bool = (i % 2 == 0)
		sp.texture = giant_oak_tex if is_oak else giant_ancient_tex
		sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		var p_size := randf_range(0.016, 0.024)
		sp.pixel_size = p_size
		# Ağacın kökünün tam zemin hizasında (y=0) durması için sprite yüksekliğinin yarısı kadar yukarı kaldır
		var spr_h: float = (1024.0 * p_size) * 0.48
		sp.position = pos + Vector3(0, spr_h, 0)
		# Sis ve güneş ışığı ile yıkanan hafif atmosferik sabah ormanı tonu
		sp.modulate = Color(0.78, 0.86, 0.82, 0.98)
		sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		backdrop_node.add_child(sp)

	# Katman 2: Orta Perimetre (55m - 82m) - Katmanlı yoğun arka plan gölgeleri
	for i in range(100):
		var angle := (float(i) / 100.0) * TAU + randf_range(-0.05, 0.05)
		var dist := randf_range(55.0, 82.0)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		
		var sp := Sprite3D.new()
		var rand_type = randf()
		var p_size: float = 0.02
		if rand_type < 0.50:
			sp.texture = giant_oak_tex
			p_size = randf_range(0.020, 0.028)
		elif rand_type < 0.85:
			sp.texture = giant_ancient_tex
			p_size = randf_range(0.018, 0.026)
		else:
			sp.texture = pine_tex
			p_size = randf_range(0.022, 0.030)
			
		sp.pixel_size = p_size
		sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		var spr_h: float = (1024.0 * p_size) * 0.48
		sp.position = pos + Vector3(0, spr_h, 0)
		sp.modulate = Color(0.62, 0.72, 0.74, 0.95)
		sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		backdrop_node.add_child(sp)

	# Katman 3: Dış Perimetre (82m - 120m) - Sis içinde kaybolan devasa ufuk ormanı silüeti
	for i in range(110):
		var angle := (float(i) / 110.0) * TAU + randf_range(-0.04, 0.04)
		var dist := randf_range(82.0, 120.0)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		
		var sp := Sprite3D.new()
		var rand_type = randf()
		var p_size: float = randf_range(0.025, 0.036)
		sp.texture = giant_oak_tex if rand_type < 0.6 else giant_ancient_tex
		sp.pixel_size = p_size
		sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		var spr_h: float = (1024.0 * p_size) * 0.48
		sp.position = pos + Vector3(0, spr_h, 0)
		# Ufukta sis rengine bürünen atmosferik derinlik tonu
		sp.modulate = Color(0.48, 0.60, 0.64, 0.90)
		sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		backdrop_node.add_child(sp)
