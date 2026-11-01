extends CanvasLayer

@onready var xp_bar: ProgressBar = $BottomContainer/XPBar
@onready var level_label: Label = get_node_or_null("BottomContainer/XPBar/LevelLabel")
@onready var xp_text: Label = get_node_or_null("BottomContainer/XPBar/XPText")
@onready var timer_label: Label = $TopContainer/TimerLabel
@onready var fps_label: Label = $TopContainer/FPSLabel
@onready var coin_label: Label = get_node_or_null("TopContainer/CoinContainer/CoinPanel/Margin/HBox/CoinLabel") if get_node_or_null("TopContainer/CoinContainer/CoinPanel/Margin/HBox/CoinLabel") != null else get_node_or_null("TopContainer/CoinContainer/CoinLabel")
@onready var speed_button: Button = $TopContainer/SpeedButton
@onready var health_bar: ProgressBar = get_node_or_null("TopContainer/HealthContainer/HealthBar")
@onready var health_text: Label = get_node_or_null("TopContainer/HealthContainer/HealthText")
@onready var dash_bar: ProgressBar = get_node_or_null("DashContainer/DashBar")
@onready var dash_status: Label = get_node_or_null("DashContainer/DashStatus")

var total_time: float = 0.0

func _ready() -> void:
	call_deferred("_connect_player")
	if speed_button:
		speed_button.pressed.connect(toggle_speed)
		_update_speed_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			toggle_speed()
			get_viewport().set_input_as_handled()

func toggle_speed() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.1)
	if Engine.time_scale >= 1.8:
		Engine.time_scale = 1.0
	else:
		Engine.time_scale = 2.0
	_update_speed_ui()

func _update_speed_ui() -> void:
	if not speed_button:
		return
	if Engine.time_scale >= 1.8:
		speed_button.text = "HIZ: 2x (T)"
		speed_button.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		speed_button.text = "HIZ: 1x (T)"
		speed_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

func _connect_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if not player.xp_changed.is_connected(_on_xp_changed):
			player.xp_changed.connect(_on_xp_changed)
		if player.has_signal("health_changed") and not player.health_changed.is_connected(_on_health_changed):
			player.health_changed.connect(_on_health_changed)
		if player.has_signal("coins_changed") and not player.coins_changed.is_connected(_on_coins_changed):
			player.coins_changed.connect(_on_coins_changed)
		if player.has_signal("dash_cooldown_updated") and not player.dash_cooldown_updated.is_connected(_on_dash_cooldown_updated):
			player.dash_cooldown_updated.connect(_on_dash_cooldown_updated)
		# Başlangıç değerlerini elle eşitle
		_on_xp_changed(player.current_xp, player.xp_to_next_level, player.current_level)
		if "current_health" in player and "max_health" in player:
			_on_health_changed(player.current_health, player.max_health)
		if "total_coins" in player:
			_on_coins_changed(player.total_coins, 0)

func _process(delta: float) -> void:
	total_time += delta
	var minutes := int(total_time) / 60
	var seconds := int(total_time) % 60
	if timer_label:
		timer_label.text = "%02d:%02d" % [minutes, seconds]
		
	# FPS Sayacı
	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func _on_xp_changed(current_xp: int, max_xp: int, level: int) -> void:
	if xp_bar:
		xp_bar.max_value = max_xp
		var tw = create_tween()
		tw.tween_property(xp_bar, "value", float(current_xp), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if level_label:
		level_label.text = "SEVİYE %d" % level
	if xp_text:
		xp_text.text = "%d / %d XP" % [current_xp, max_xp]

func _on_health_changed(current_hp: float, max_hp: float) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		var tw = create_tween()
		tw.tween_property(health_bar, "value", float(current_hp), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if health_text:
		health_text.text = "%d / %d" % [int(ceil(current_hp)), int(ceil(max_hp))]

func _on_coins_changed(total_coins: int, _run_coins: int) -> void:
	if coin_label:
		coin_label.text = str(total_coins)
		var tw = coin_label.create_tween()
		tw.tween_property(coin_label, "scale", Vector2(1.25, 1.25), 0.08)
		tw.tween_property(coin_label, "scale", Vector2.ONE, 0.12)

func _on_dash_cooldown_updated(current_cd: float, max_cd: float) -> void:
	if not dash_bar or not dash_status:
		return
	dash_bar.max_value = max_cd
	dash_bar.value = max_cd - current_cd
	if current_cd <= 0.001:
		dash_status.text = "HAZIR"
		dash_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	else:
		dash_status.text = "%.1fs" % current_cd
		dash_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))

func show_pickup_notification(text: String, icon_path: String = "") -> void:
	var notif := HBoxContainer.new()
	notif.alignment = BoxContainer.ALIGNMENT_CENTER
	notif.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	notif.position = Vector2(1280 - 280, 640)
	notif.size = Vector2(260, 36)
	
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.14, 0.88)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.85, 0.72, 0.3, 0.9)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", sb)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tr := TextureRect.new()
		tr.texture = load(icon_path)
		tr.custom_minimum_size = Vector2(24, 24)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(tr)
		
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 1.0))
	lbl.add_theme_constant_override("outline_size", 3)
	hbox.add_child(lbl)
	
	panel.add_child(hbox)
	notif.add_child(panel)
	add_child(notif)
	
	notif.modulate.a = 0.0
	notif.position.y = 660
	var tw := notif.create_tween()
	tw.parallel().tween_property(notif, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(notif, "position:y", 620, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.8)
	tw.parallel().tween_property(notif, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(notif, "position:y", 600, 0.3)
	tw.tween_callback(notif.queue_free)

func show_announcement(text: String, color: Color = Color(1.0, 0.35, 0.2)) -> void:
	var banner := Label.new()
	banner.text = text
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 22)
	banner.add_theme_color_override("font_color", color)
	banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	banner.add_theme_constant_override("outline_size", 6)
	banner.anchors_preset = Control.PRESET_CENTER_TOP
	banner.position = Vector2(1280 * 0.5 - 350, 110)
	banner.size = Vector2(700, 50)
	add_child(banner)
	
	banner.scale = Vector2(0.3, 0.3)
	banner.pivot_offset = Vector2(350, 25)
	var tw := banner.create_tween()
	tw.tween_property(banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.5)
	tw.tween_property(banner, "modulate:a", 0.0, 0.5)
	tw.tween_callback(banner.queue_free)

func _exit_tree() -> void:
	Engine.time_scale = 1.0
