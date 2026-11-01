extends StaticBody3D

@export var shrine_active: bool = true

@onready var sprite: Sprite3D = $Sprite3D
@onready var prompt_label: Label3D = $PromptLabel3D
@onready var popup_layer: CanvasLayer = $PopupLayer
@onready var card_blood: Button = $PopupLayer/Dimmer/Center/VBox/Cards/BloodPact
@onready var card_greed: Button = $PopupLayer/Dimmer/Center/VBox/Cards/GreedPact
@onready var card_soul: Button = $PopupLayer/Dimmer/Center/VBox/Cards/SoulPact
@onready var close_btn: Button = $PopupLayer/Dimmer/Center/VBox/CloseButton
@onready var interaction_area: Area3D = $InteractionArea3D

var player_in_range: Node3D = null

func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
		
	if prompt_label:
		prompt_label.visible = false
	if popup_layer:
		popup_layer.visible = false
		
	if card_blood:
		card_blood.pressed.connect(_on_blood_pact_selected)
	if card_greed:
		card_greed.pressed.connect(_on_greed_pact_selected)
	if card_soul:
		card_soul.pressed.connect(_on_soul_pact_selected)
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
		
	# Yere iniş animasyonu
	if sprite:
		sprite.scale = Vector3(0.01, 0.01, 0.01)
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_setup_shrine_particles()

func _setup_shrine_particles() -> void:
	var particles := CPUParticles3D.new()
	particles.name = "PortalParticles"
	particles.amount = 26
	particles.lifetime = 1.6
	particles.randomness = 0.35
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	particles.emission_ring_radius = 1.2
	particles.emission_ring_inner_radius = 0.5
	particles.gravity = Vector3(0, 1.2, 0)
	particles.initial_velocity_min = 0.2
	particles.initial_velocity_max = 0.8
	particles.scale_amount_min = 0.1
	particles.scale_amount_max = 0.25
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var spark_tex = load("res://assets/sprites/particles/particle_spark_soft.png")
	if spark_tex:
		mat.albedo_texture = spark_tex
	particles.material_override = mat
	
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.28, 0.28)
	particles.mesh = mesh
	
	var grad := Gradient.new()
	grad.set_color(0, Color(0.1, 0.9, 0.95, 0.0))
	grad.add_point(0.25, Color(0.2, 0.95, 0.9, 0.95))
	grad.add_point(0.7, Color(0.4, 0.5, 0.95, 0.8))
	grad.set_color(grad.get_point_count() - 1, Color(0.6, 0.2, 0.9, 0.0))
	particles.color_ramp = grad
	
	particles.position = Vector3(0, 0.2, 0)
	add_child(particles)

func _unhandled_input(event: InputEvent) -> void:
	if not shrine_active:
		return
	var is_e_key: bool = false
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY_E:
			is_e_key = true
	var is_action: bool = event.is_action_pressed("ui_accept") or (InputMap.has_action("interact") and event.is_action_pressed("interact"))
	if player_in_range and (is_e_key or is_action):
		if popup_layer and not popup_layer.visible:
			_open_pact_menu()
			get_viewport().set_input_as_handled()

func _on_body_entered(body: Node3D) -> void:
	if not shrine_active:
		return
	if body and body.is_in_group("player"):
		player_in_range = body
		if prompt_label:
			prompt_label.visible = true
			var tw := create_tween().set_loops()
			tw.tween_property(prompt_label, "scale", Vector3(1.12, 1.12, 1.12), 0.4)
			tw.tween_property(prompt_label, "scale", Vector3.ONE, 0.4)

func _on_body_exited(body: Node3D) -> void:
	if body == player_in_range:
		player_in_range = null
		if prompt_label:
			prompt_label.visible = false

func _open_pact_menu() -> void:
	if popup_layer:
		popup_layer.visible = true
		get_tree().paused = true
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_sfx("button_click", 0.08)

func _close_pact_menu() -> void:
	if popup_layer:
		popup_layer.visible = false
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.paused = false

func _on_close_pressed() -> void:
	_close_pact_menu()

func _on_blood_pact_selected() -> void:
	if player_in_range:
		# Kan Paktı: Canının %35'ini ver -> +%20 Hasar ve +%15 Kritik
		player_in_range.current_health = maxf(1.0, player_in_range.current_health * 0.65)
		player_in_range.damage_multiplier *= 1.20
		player_in_range.crit_chance = minf(1.0, player_in_range.crit_chance + 0.15)
		player_in_range.emit_signal("health_changed", player_in_range.current_health, player_in_range.max_health)
	_seal_pact("KAN PAKTI: +%20 Hasar ve +%15 Kritik mühürlendi!")

func _on_greed_pact_selected() -> void:
	if player_in_range:
		# Açgözlülük Paktı: Düşmanları %25 artır -> Altınları 2 katına çıkar
		player_in_range.curse_mult *= 1.25
		player_in_range.gold_multiplier *= 2.0
	_seal_pact("AÇGÖZLÜLÜK PAKTI: Düşman akını arttı, altın kazanımı 2 katına çıktı!")

func _on_soul_pact_selected() -> void:
	if player_in_range:
		# Ruh Paktı: -15 Maksimum Can -> +1 Yeniden Doğma Hakkı
		player_in_range.max_health = maxf(20.0, player_in_range.max_health - 15.0)
		player_in_range.current_health = minf(player_in_range.current_health, player_in_range.max_health)
		player_in_range.revives_remaining += 1
		player_in_range.emit_signal("health_changed", player_in_range.current_health, player_in_range.max_health)
	_seal_pact("RUH PAKTI: +1 Yeniden Doğma Hakkı kazanıldı!")

func _seal_pact(banner_msg: String) -> void:
	shrine_active = false
	_close_pact_menu()
	if prompt_label:
		prompt_label.visible = false
		
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var hud = tree.current_scene.get_node_or_null("HUD") if (tree and tree.current_scene) else null
	if hud and hud.has_method("show_announcement"):
		hud.show_announcement(banner_msg, Color(0.9, 0.3, 0.4))
		
	var audio = tree.root.get_node_or_null("AudioManager") if (tree and tree.root) else null
	if audio:
		audio.play_sfx("level_up", 0.0, 2.2)
		
	# Sunak yok olma animasyonu
	if sprite:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(sprite, "modulate", Color(2.5, 0.5, 0.5, 0.0), 0.6)
		tw.tween_property(sprite, "scale", Vector3.ZERO, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(queue_free)
	else:
		queue_free()
