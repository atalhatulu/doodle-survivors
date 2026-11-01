extends Node3D

# HTML prototipindeki TPS kamera parametreleri:
# const tpsDistance = 11;
# const tpsHeight = 6.8;
# camera.lookAt(lookTarget.y += 2.2);

@onready var camera_3d: Camera3D = $Camera3D
@onready var sub_viewport: SubViewport = $SubViewport2D
@onready var ground_plane: MeshInstance3D = $GroundPlane

var player_2d: CharacterBody2D = null
var main_2d: Node = null

var tps_distance: float = 12.0
var tps_height: float = 7.2
var camera_pitch: float = 34.0 # Derece cinsinden aşağı eğim

func _ready() -> void:
	if sub_viewport:
		sub_viewport.size = get_viewport().size
		main_2d = sub_viewport.get_node_or_null("Main")
		if main_2d:
			player_2d = main_2d.get_node_or_null("YSortEntities/Player")
			
	# Ground plane'e 2D dünyanın dokusunu bağla
	if ground_plane and sub_viewport:
		var vp_tex = sub_viewport.get_texture()
		var mat = StandardMaterial3D.new()
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_texture = vp_tex
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		ground_plane.material_override = mat

func _process(delta: float) -> void:
	# Pencere boyutu değiştikçe viewport'u eşitle
	if sub_viewport and get_viewport():
		var vp_size = get_viewport().size
		if sub_viewport.size != vp_size:
			sub_viewport.size = vp_size

	# Fare ve tuş girdilerini alt 2D viewport'a doğrudan ilet
	# böylece oyunun tüm 2D mekanikleri (hareket, ateş, dash, menüler) çalışır
