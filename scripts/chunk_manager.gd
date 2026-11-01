extends Node2D

const TILE_SIZE: float = 240.0
const TILES_PER_CHUNK: int = 6
const CHUNK_SIZE: float = TILE_SIZE * TILES_PER_CHUNK
const CHUNK_RADIUS: int = 2

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

# Karanlık Orta Çağ Fantezi Zemin Dokuları
var terrain_tiles: Array[Texture2D] = [
	preload("res://assets/sprites/terrain/tile_dungeon_cobble.png"),
	preload("res://assets/sprites/terrain/tile_mossy_ground.png"),
	preload("res://assets/sprites/terrain/tile_ruin_slabs.png"),
	preload("res://assets/sprites/terrain/tile_dark_earth.png")
]

# Papercraft Zemin Detayları
var paper_floor_props: Array[Texture2D] = [
	preload("res://assets/sprites/environment/paper_bush_dense.png"),
	preload("res://assets/sprites/environment/paper_rock_grey.png"),
	preload("res://assets/sprites/environment/paper_stump.png")
]

# Yeni Papercraft Çevre Engelleri
var tree_scene: PackedScene = preload("res://scenes/world/tree_big.tscn")
var rock_scene: PackedScene = preload("res://scenes/world/rock_grey.tscn")
var bush_tex: Texture2D = preload("res://assets/sprites/environment/paper_bush_dense.png")
var palm_tex: Texture2D = preload("res://assets/sprites/environment/paper_tree_palm_big.png")

# Kırılabilir Saha Objeleri
var prop_barrel_scene: PackedScene = preload("res://scenes/world/prop_barrel.tscn")
var prop_jar_scene: PackedScene = preload("res://scenes/world/prop_jar.tscn")
var prop_grave_scene: PackedScene = preload("res://scenes/world/prop_grave.tscn")

var loaded_chunks: Dictionary = {}
var current_player_chunk: Vector2i = Vector2i(9999, 9999)

func _ready() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
	_update_chunks(true)

func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var player_chunk := _world_to_chunk(player.global_position)
	if player_chunk != current_player_chunk:
		current_player_chunk = player_chunk
		_update_chunks(false)

func _world_to_chunk(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / CHUNK_SIZE)),
		int(floor(pos.y / CHUNK_SIZE))
	)

func _update_chunks(_force: bool) -> void:
	var needed_coords: Array[Vector2i] = []
	for x in range(current_player_chunk.x - CHUNK_RADIUS, current_player_chunk.x + CHUNK_RADIUS + 1):
		for y in range(current_player_chunk.y - CHUNK_RADIUS, current_player_chunk.y + CHUNK_RADIUS + 1):
			needed_coords.append(Vector2i(x, y))
			
	var to_remove: Array[Vector2i] = []
	for coord in loaded_chunks.keys():
		if not coord in needed_coords:
			to_remove.append(coord)
			
	for coord in to_remove:
		var chunk_node: Node2D = loaded_chunks[coord]
		chunk_node.queue_free()
		loaded_chunks.erase(coord)
		
	for coord in needed_coords:
		if not loaded_chunks.has(coord):
			_spawn_chunk(coord)

func _spawn_chunk(coord: Vector2i) -> void:
	var chunk_root := Node2D.new()
	chunk_root.name = "Chunk_%d_%d" % [coord.x, coord.y]
	chunk_root.position = Vector2(coord.x * CHUNK_SIZE, coord.y * CHUNK_SIZE)
	chunk_root.y_sort_enabled = true
	add_child(chunk_root)
	loaded_chunks[coord] = chunk_root
	
	var seed_val := (coord.x * 73856093) ^ (coord.y * 19349663)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	
	# 1. Zemin Katmanı (Karanlık Orta Çağ Zemin Varyasyonları)
	var biome_index := absi((coord.x * 3 + coord.y * 5 + (coord.x ^ coord.y)) % terrain_tiles.size())
	var base_tex: Texture2D = terrain_tiles[biome_index]
	
	var ground_rect := TextureRect.new()
	ground_rect.texture = base_tex
	ground_rect.stretch_mode = TextureRect.STRETCH_TILE
	ground_rect.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	ground_rect.z_index = -20
	ground_rect.modulate = Color(0.24, 0.32, 0.26, 1.0) # Shadow Forest Papercraft karanlık karton zemin
	chunk_root.add_child(ground_rect)
	
	# Zemin geçiş yamaları (Organik arazi harmanı)
	var alt_tex: Texture2D = terrain_tiles[(biome_index + 1) % terrain_tiles.size()]
	var patch_count := rng.randi_range(1, 2)
	for p in range(patch_count):
		var patch_rect := TextureRect.new()
		patch_rect.texture = alt_tex
		patch_rect.stretch_mode = TextureRect.STRETCH_TILE
		var pw := rng.randf_range(280.0, 480.0)
		var ph := rng.randf_range(280.0, 480.0)
		patch_rect.size = Vector2(pw, ph)
		patch_rect.position = Vector2(rng.randf_range(40.0, CHUNK_SIZE - pw - 40.0), rng.randf_range(40.0, CHUNK_SIZE - ph - 40.0))
		patch_rect.modulate = Color(0.20, 0.28, 0.22, 0.45)
		patch_rect.z_index = -19
		chunk_root.add_child(patch_rect)

			
	# 2. Papercraft Zemin Detayları (Çimen tutamları, küçük taşlar)
	var detail_count := rng.randi_range(3, 6)
	for i in range(detail_count):
		var detail := Sprite2D.new()
		detail.texture = paper_floor_props[rng.randi() % paper_floor_props.size()]
		detail.position = Vector2(rng.randf_range(50, CHUNK_SIZE - 50), rng.randf_range(50, CHUNK_SIZE - 50))
		detail.scale = Vector2(0.18, 0.18)
		detail.z_index = -10
		chunk_root.add_child(detail)
		
	if coord == Vector2i.ZERO:
		# Başlangıç chunk'ında oyuncunun yakınına 2 adet kırılabilir fıçı/testi ekle (güvenli mesafe)
		var p1 = prop_barrel_scene.instantiate()
		p1.position = Vector2(240, 180)
		chunk_root.add_child(p1)
		var p2 = prop_jar_scene.instantiate()
		p2.position = Vector2(-220, 160)
		chunk_root.add_child(p2)
		# Oyuncudan uzakta 2 ağaç/kaya yerleştir
		var t1 = tree_scene.instantiate()
		t1.position = Vector2(450, 420)
		chunk_root.add_child(t1)
		var r1 = rock_scene.instantiate()
		r1.position = Vector2(520, -380)
		chunk_root.add_child(r1)
		return
		
	# 3. Y-Sort Papercraft Engelleri (Ağaçlar, Kayalar, Çalılar) - Dengeli Dağılım
	var obstacle_count := rng.randi_range(2, 4)
	for i in range(obstacle_count):
		var spawn_pos := Vector2(rng.randf_range(100, CHUNK_SIZE - 100), rng.randf_range(100, CHUNK_SIZE - 100))
		var r := rng.randf()
		if r < 0.45:
			var tree = tree_scene.instantiate()
			tree.position = spawn_pos
			chunk_root.add_child(tree)
		elif r < 0.75:
			var rock = rock_scene.instantiate()
			rock.position = spawn_pos
			chunk_root.add_child(rock)
		else:
			var bush := Sprite2D.new()
			bush.texture = bush_tex
			bush.position = spawn_pos
			bush.scale = Vector2(0.26, 0.26)
			bush.offset = Vector2(0, -20)
			chunk_root.add_child(bush)
			
	# 4. Kırılabilir Saha Objeleri (Fıçılar, Testiler, Harap Mezarlar)
	var prop_count := rng.randi_range(1, 3)
	for i in range(prop_count):
		var prop_pos := Vector2(rng.randf_range(100, CHUNK_SIZE - 100), rng.randf_range(100, CHUNK_SIZE - 100))
		var pr := rng.randf()
		var prop_node: Node2D = null
		if pr < 0.45:
			prop_node = prop_barrel_scene.instantiate()
		elif pr < 0.80:
			prop_node = prop_jar_scene.instantiate()
		else:
			prop_node = prop_grave_scene.instantiate()
		prop_node.position = prop_pos
		chunk_root.add_child(prop_node)
