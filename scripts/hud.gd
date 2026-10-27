extends CanvasLayer

@onready var xp_bar: ProgressBar = $BottomContainer/XPBar
@onready var level_label: Label = $TopContainer/LevelLabel
@onready var timer_label: Label = $TopContainer/TimerLabel
@onready var fps_label: Label = $TopContainer/FPSLabel
@onready var coin_label: Label = $TopContainer/CoinContainer/CoinLabel
@onready var speed_button: Button = $TopContainer/SpeedButton

var total_time: float = 0.0

func _ready() -> void:
	call_deferred("_connect_player")
	if speed_button:
		speed_button.pressed.connect(toggle_speed)
		_update_speed_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_T:
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
		speed_button.text = "HIZ: 2x (TAB)"
		speed_button.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		speed_button.text = "HIZ: 1x (TAB)"
		speed_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

func _connect_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if not player.xp_changed.is_connected(_on_xp_changed):
			player.xp_changed.connect(_on_xp_changed)
		if player.has_signal("coins_changed") and not player.coins_changed.is_connected(_on_coins_changed):
			player.coins_changed.connect(_on_coins_changed)
		# Başlangıç değerlerini elle eşitle
		_on_xp_changed(player.current_xp, player.xp_to_next_level, player.current_level)
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
		xp_bar.value = current_xp
	if level_label:
		level_label.text = "SEVİYE %d" % level

func _on_coins_changed(total_coins: int, _run_coins: int) -> void:
	if coin_label:
		coin_label.text = str(total_coins)

func _exit_tree() -> void:
	Engine.time_scale = 1.0
