extends Node2D

const TILE_SIZE: float = 240.0
const TILES_PER_CHUNK: int = 6
const CHUNK_SIZE: float = TILE_SIZE * TILES_PER_CHUNK
const CHUNK_RADIUS: int = 2

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

# Zemin dokusu (Kolaj El İşi Kağıdı)
var ground_tile_tex: Texture2D = preload("res://assets/sprites/terrain/paper_patchwork_ground.png")

var patchwork_tiles: Array[Texture2D] = [
	preload("res://assets/sprites/terrain/patchwork_tile_0_0.png"),
	preload("res://assets/sprites/terrain/patchwork_tile_0_1.png"),
	preload("res://assets/sprites/terrain/patchwork_tile_0_2.png"),
	preload("res://assets/sprites/terrain/patchwork_tile_1_0.png"),
	preload("res://assets/sprites/terrain/patchwork_tile_1_1.png"),
	preload("res://assets/sprites/terrain/patchwork_tile_1_2.png"),
	preload("res://assets/sprites/terrain/patchwork_tile_2_0.png"),
	preload("res://assets/sprites/terrain/patchwork_tile_2_1.png"),
	preload("res://assets/sprites/terrain/patchwork_tile_2_2.png")
]

# Papercraft Zemin Detayları
var paper_floor_props: Array[Texture2D] = [
	preload("res://assets/sprites/environment/paper_grass_tall.png"),
	preload("res://assets/sprites/environment/paper_grass_spiky.png"),
	preload("res://assets/sprites/environment/paper_rock_small.png"),
	preload("res://assets/sprites/environment/paper_stump.png")
]

# Yeni Papercraft Çevre Engelleri
var tree_scene: PackedScene = preload("res://scenes/world/tree_big.tscn")
var rock_scene: PackedScene = preload("res://scenes/world/rock_grey.tscn")
var bush_tex: Texture2D = preload("res://assets/sprites/environment/paper_bush_dense.png")
var palm_tex: Texture2D = preload("res://assets/sprites/environment/paper_tree_palm_big.png")

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
	
	# 1. Zemin Katmanı
	var ground_rect := TextureRect.new()
	ground_rect.texture = ground_tile_tex
	ground_rect.stretch_mode = TextureRect.STRETCH_TILE
	ground_rect.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	ground_rect.z_index = -20
	chunk_root.add_child(ground_rect)
			
	# 2. Papercraft Zemin Detayları (Çimen tutamları, küçük taşlar)
	var detail_count := rng.randi_range(5, 9)
	for i in range(detail_count):
		var detail := Sprite2D.new()
		detail.texture = paper_floor_props[rng.randi() % paper_floor_props.size()]
		detail.position = Vector2(rng.randf_range(40, CHUNK_SIZE - 40), rng.randf_range(40, CHUNK_SIZE - 40))
		detail.scale = Vector2(0.5, 0.5)
		detail.z_index = -10
		chunk_root.add_child(detail)
		
	if coord == Vector2i.ZERO:
		return
		
	# 3. Y-Sort Papercraft Engelleri (Ağaçlar, Kayalar, Çalılar)
	var obstacle_count := rng.randi_range(3, 6)
	for i in range(obstacle_count):
		var spawn_pos := Vector2(rng.randf_range(70, CHUNK_SIZE - 70), rng.randf_range(70, CHUNK_SIZE - 70))
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
			bush.scale = Vector2(0.65, 0.65)
			bush.offset = Vector2(0, -30)
			chunk_root.add_child(bush)
