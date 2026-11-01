extends Node3D

const CHUNK_SIZE: float = 48.0
const CHUNK_RADIUS: int = 2

@onready var player: Node3D = get_tree().get_first_node_in_group("player")

# 3D Engeller ve Çevre Elemanları
var barrel_scene: PackedScene = preload("res://scenes/world/barrel_3d.tscn")
var jar_scene: PackedScene = preload("res://scenes/world/jar_3d.tscn")
var grave_scene: PackedScene = preload("res://scenes/world/grave_3d.tscn")
var lantern_scene: PackedScene = preload("res://scenes/world/lantern_3d.tscn")
var rock_scene: PackedScene = preload("res://scenes/world/rock_3d.tscn")
var tree_scene: PackedScene = preload("res://scenes/world/tree_3d.tscn")
var pine_scene: PackedScene = preload("res://scenes/world/pine_3d.tscn")
var bush_scene: PackedScene = preload("res://scenes/world/bush_3d.tscn")
var giant_tree_scene: PackedScene = preload("res://scenes/world/giant_tree_3d.tscn")
var flower_scene: PackedScene = preload("res://scenes/world/flower_3d.tscn")
var grass_scene: PackedScene = preload("res://scenes/world/grass_clump_3d.tscn")
var shrine_scene: PackedScene = preload("res://scenes/world/shrine_3d.tscn")
var pillar_scene: PackedScene = preload("res://scenes/world/ruin_pillar_3d.tscn")

var terrain_shader: Shader = preload("res://scenes/world/ground_terrain.gdshader")
var tex_grass: Texture2D = preload("res://assets/sprites/terrain/tile_lush_grass.png")
var tex_dirt: Texture2D = preload("res://assets/sprites/terrain/tile_dark_earth.png")
var tex_rock: Texture2D = preload("res://assets/sprites/terrain/tile_seamless_dirt.png")

var terrain_material: ShaderMaterial = null

var loaded_chunks: Dictionary = {}
var current_player_chunk: Vector2i = Vector2i(9999, 9999)

# LOD & Culling Takipçisi
# chunk_coord -> { "small": [Node3D], "medium": [Node3D], "large": [Node3D], "center": Vector3 }
var chunk_lod_groups: Dictionary = {}
var culling_check_timer: float = 0.0

func _ready() -> void:
	_init_terrain_material()
	if not player:
		player = get_tree().get_first_node_in_group("player")
	_update_chunks(true)

func _init_terrain_material() -> void:
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = terrain_shader
	terrain_material.set_shader_parameter("texture_grass", tex_grass)
	terrain_material.set_shader_parameter("texture_dirt", tex_dirt)
	terrain_material.set_shader_parameter("texture_rock", tex_rock)
	terrain_material.set_shader_parameter("grass_tint", Color(0.55, 0.65, 0.42, 1.0))
	terrain_material.set_shader_parameter("dirt_tint", Color(0.72, 0.58, 0.42, 1.0))
	terrain_material.set_shader_parameter("path_tint", Color(0.75, 0.62, 0.46, 1.0))
	terrain_material.set_shader_parameter("uv_scale_grass", 38.0)
	terrain_material.set_shader_parameter("uv_scale_dirt", 30.0)
	terrain_material.set_shader_parameter("uv_scale_rock", 28.0)
	terrain_material.set_shader_parameter("roughness_val", 0.88)

func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return
			
	var player_chunk := _world_to_chunk(player.global_position)
	if player_chunk != current_player_chunk:
		current_player_chunk = player_chunk
		_update_chunks(false)

	# LOD ve Kamera Yönelim Culling (Frustum/Orientation) Güncellemesi (Her 0.08 sn bir kontrol)
	culling_check_timer += delta
	if culling_check_timer >= 0.08:
		culling_check_timer = 0.0
		_update_lod_and_culling()

func _world_to_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / CHUNK_SIZE)),
		int(floor(pos.z / CHUNK_SIZE))
	)

func _update_chunks(_force: bool) -> void:
	var needed_coords: Array[Vector2i] = []
	for x in range(current_player_chunk.x - CHUNK_RADIUS, current_player_chunk.x + CHUNK_RADIUS + 1):
		for z in range(current_player_chunk.y - CHUNK_RADIUS, current_player_chunk.y + CHUNK_RADIUS + 1):
			needed_coords.append(Vector2i(x, z))
			
	var to_remove: Array[Vector2i] = []
	for coord in loaded_chunks.keys():
		if not coord in needed_coords:
			to_remove.append(coord)
			
	for coord in to_remove:
		var chunk_node: Node3D = loaded_chunks[coord]
		chunk_node.queue_free()
		loaded_chunks.erase(coord)
		chunk_lod_groups.erase(coord)
		
	for coord in needed_coords:
		if not loaded_chunks.has(coord):
			_spawn_chunk(coord)

	_update_lod_and_culling()

func _spawn_chunk(coord: Vector2i) -> void:
	var chunk_root := Node3D.new()
	chunk_root.name = "Chunk_%d_%d" % [coord.x, coord.y]
	# Chunk merkezi: (coord.x + 0.5) * CHUNK_SIZE, (coord.y + 0.5) * CHUNK_SIZE
	var center_x: float = (float(coord.x) + 0.5) * CHUNK_SIZE
	var center_z: float = (float(coord.y) + 0.5) * CHUNK_SIZE
	chunk_root.position = Vector3(center_x, 0.0, center_z)
	add_child(chunk_root)
	loaded_chunks[coord] = chunk_root

	var lod_dict := {
		"small": [] as Array[Node3D],
		"medium": [] as Array[Node3D],
		"large": [] as Array[Node3D],
		"center": chunk_root.position
	}
	chunk_lod_groups[coord] = lod_dict
	
	# 1. 48x48m Zemin MeshInstance3D (PlaneMesh)
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	mesh_inst.mesh = plane
	mesh_inst.material_override = terrain_material
	chunk_root.add_child(mesh_inst)
	
	# Deterministik Seed Hesabı
	var seed_val: int = (coord.x * 73856093) ^ (coord.y * 19349663)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	
	# Başlangıç Chunk'ı (Vector2i.ZERO) için oyuncu etrafında temiz güvenli alan
	var is_start_chunk: bool = (coord == Vector2i.ZERO)
	
	# Engel ve Nesne Üretimi
	var half: float = (CHUNK_SIZE * 0.5) - 2.5
	var placed_positions: Array[Vector3] = []
	
	var is_valid_local_pos = func(test_pos: Vector3, min_d: float) -> bool:
		var world_pos: Vector3 = chunk_root.position + test_pos
		# Oyuncunun spawn noktası (0,0,0) etrafında temiz güvenli alan (r = 6.5m)
		if world_pos.length_squared() < (6.5 * 6.5):
			return false
		for p in placed_positions:
			if p.distance_squared_to(test_pos) < (min_d * min_d):
				return false
		return true

	# 2. Kırılabilir Fıçılar, Testiler ve Mezarlar (LOD: Küçük Nesneler)
	var prop_count := rng.randi_range(2, 4)
	for i in range(prop_count):
		for attempt in range(8):
			var lx := rng.randf_range(-half, half)
			var lz := rng.randf_range(-half, half)
			var pos := Vector3(lx, 0.0, lz)
			if is_valid_local_pos.call(pos, 2.8):
				placed_positions.append(pos)
				var roll := rng.randf()
				var prop: Node3D = null
				if roll < 0.45:
					prop = barrel_scene.instantiate()
				elif roll < 0.80:
					prop = jar_scene.instantiate()
				else:
					prop = grave_scene.instantiate()
				prop.position = pos
				chunk_root.add_child(prop)
				lod_dict["small"].append(prop)
				break

	# 3. Fenerler (Lanterns) (LOD: Küçük/Dekoratif)
	if rng.randf() < 0.65:
		for attempt in range(6):
			var lx := rng.randf_range(-half, half)
			var lz := rng.randf_range(-half, half)
			var pos := Vector3(lx, 0.0, lz)
			if is_valid_local_pos.call(pos, 4.0):
				placed_positions.append(pos)
				var lantern = lantern_scene.instantiate()
				lantern.position = pos
				chunk_root.add_child(lantern)
				lod_dict["small"].append(lantern)
				break

	# 4. Kayalar ve Harabe Sütunları (LOD: Orta/Büyük Çevre Nesneleri)
	var rock_count := rng.randi_range(1, 3)
	for i in range(rock_count):
		for attempt in range(6):
			var lx := rng.randf_range(-half, half)
			var lz := rng.randf_range(-half, half)
			var pos := Vector3(lx, 0.0, lz)
			if is_valid_local_pos.call(pos, 3.2):
				placed_positions.append(pos)
				var r_obj: Node3D = null
				if rng.randf() < 0.75:
					r_obj = rock_scene.instantiate()
					# Kayalar orta kategori
					lod_dict["medium"].append(r_obj)
				else:
					r_obj = pillar_scene.instantiate()
					# Sütunlar orta kategori
					lod_dict["medium"].append(r_obj)
				r_obj.position = pos
				chunk_root.add_child(r_obj)
				break

	# 5. Ağaçlar ve Çamlar (LOD: Büyük Çevre Nesneleri & Dev Silüetler)
	var tree_count := rng.randi_range(2, 4)
	for i in range(tree_count):
		for attempt in range(6):
			var lx := rng.randf_range(-half, half)
			var lz := rng.randf_range(-half, half)
			var pos := Vector3(lx, 0.0, lz)
			if is_valid_local_pos.call(pos, 4.2):
				placed_positions.append(pos)
				var t_roll := rng.randf()
				var t_node: Node3D = null
				if t_roll < 0.35:
					t_node = giant_tree_scene.instantiate()
					# Dev meşe/çam ağacı: Her mesafede (70m+) görünür en üst LOD
					lod_dict["large"].append(t_node)
				elif t_roll < 0.70:
					t_node = tree_scene.instantiate()
					# Normal ağaç: 0-70m orta kategori
					lod_dict["medium"].append(t_node)
				else:
					t_node = pine_scene.instantiate()
					# Çam ağacı: 0-70m orta kategori
					lod_dict["medium"].append(t_node)
				t_node.position = pos
				chunk_root.add_child(t_node)
				break

	# 6. Çiçek ve Ot Öbekleri (LOD: Küçük Çarpışmasız Zemin Süsleri)
	var flora_count := rng.randi_range(4, 8)
	for i in range(flora_count):
		var lx := rng.randf_range(-half, half)
		var lz := rng.randf_range(-half, half)
		var pos := Vector3(lx, 0.0, lz)
		var world_pos := chunk_root.position + pos
		if world_pos.length_squared() < (4.0 * 4.0):
			continue
		var plant: Node3D = null
		if rng.randf() < 0.5:
			plant = flower_scene.instantiate()
		else:
			plant = grass_scene.instantiate()
		plant.position = pos
		chunk_root.add_child(plant)
		lod_dict["small"].append(plant)

	# 7. Kadim Sunak (Nadir Çıkış - %20 ihtimal, başlangıç chunk'ında değilse)
	if not is_start_chunk and rng.randf() < 0.20:
		for attempt in range(6):
			var lx := rng.randf_range(-half, half)
			var lz := rng.randf_range(-half, half)
			var pos := Vector3(lx, 0.0, lz)
			if is_valid_local_pos.call(pos, 6.0):
				placed_positions.append(pos)
				var shrine = shrine_scene.instantiate()
				shrine.position = pos
				chunk_root.add_child(shrine)
				lod_dict["medium"].append(shrine)
				break

func _update_lod_and_culling() -> void:
	if not player or not is_instance_valid(player):
		return

	var cam: Camera3D = null
	if "camera" in player and player.camera:
		cam = player.camera
	elif player.has_node("CameraPivot/SpringArm3D/Camera3D"):
		cam = player.get_node("CameraPivot/SpringArm3D/Camera3D")
	else:
		cam = get_viewport().get_camera_3d()

	var p_pos := player.global_position
	var cam_forward := Vector3.FORWARD
	if cam:
		cam_forward = -cam.global_transform.basis.z.normalized()
	var cam_forward_2d := Vector2(cam_forward.x, cam_forward.z).normalized()

	for coord in chunk_lod_groups.keys():
		var group = chunk_lod_groups[coord]
		var c_center: Vector3 = group["center"]
		var dist: float = p_pos.distance_to(c_center)

		# Kamera Yönelim Culling (Frustum/Orientation):
		# Oyuncunun bulunduğu chunk ve hemen arkasındaki yakın çember (28m) haricinde,
		# kameranın arkasında kalan (dot < -0.25) chunk'lar elenir.
		var is_behind_camera := false
		if coord != current_player_chunk and dist > 28.0 and cam_forward_2d.length_squared() > 0.01:
			var to_chunk_2d := Vector2(c_center.x - p_pos.x, c_center.z - p_pos.z).normalized()
			var dot_val := cam_forward_2d.dot(to_chunk_2d)
			if dot_val < -0.25:
				is_behind_camera = true

		# LOD Katmanları:
		# 0-35m: Tam detay (küçük, orta, büyük hepsi görünür)
		# 35-70m: Yalnızca orta/büyük çevre nesneleri görünür, küçükler gizlenir.
		# 70m+: Sadece dev silüetler (büyük) görünür.
		var show_small := false
		var show_medium := false
		var show_large := true

		if not is_behind_camera:
			if dist <= 35.0:
				show_small = true
				show_medium = true
				show_large = true
			elif dist <= 70.0:
				show_small = false
				show_medium = true
				show_large = true
			else:
				show_small = false
				show_medium = false
				show_large = true
		else:
			# Kameranın arkasında kalan chunk: küçük ve orta nesneler cull edilir
			show_small = false
			show_medium = false
			show_large = (dist <= 35.0) # Çok yakın arkadaki dev gövdeler hariç

		# Küçük nesneler (çimen, çiçek, çömlek, varil, mezar, fener)
		for node in group["small"]:
			if is_instance_valid(node) and node.visible != show_small:
				node.visible = show_small

		# Orta nesneler (ağaç, çam, kaya, sütun, sunak)
		for node in group["medium"]:
			if is_instance_valid(node) and node.visible != show_medium:
				node.visible = show_medium

		# Büyük nesneler (dev meşe/çam ağacı silüetleri)
		for node in group["large"]:
			if is_instance_valid(node) and node.visible != show_large:
				node.visible = show_large
