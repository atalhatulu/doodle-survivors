extends CanvasLayer

signal restart_requested()
signal resume_requested()

@onready var title_label: Label = $Dimmer/CenterContainer/VBox/TitleLabel
@onready var desc_label: Label = $Dimmer/CenterContainer/VBox/DescLabel
@onready var primary_button: Button = $Dimmer/CenterContainer/VBox/Buttons/PrimaryButton
@onready var secondary_button: Button = $Dimmer/CenterContainer/VBox/Buttons/SecondaryButton
@onready var menu_button: Button = $Dimmer/CenterContainer/VBox/Buttons/MenuButton

var current_mode: String = "game_over" # "game_over", "victory", "pause"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if primary_button:
		primary_button.pressed.connect(_on_primary_pressed)
	if secondary_button:
		secondary_button.pressed.connect(_on_secondary_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var level_up = get_parent().get_node_or_null("LevelUpMenu")
		if level_up and level_up.visible:
			return
		if visible:
			if current_mode == "pause":
				_on_primary_pressed()
		else:
			show_pause()

func show_pause() -> void:
	current_mode = "pause"
	title_label.text = "OYUN DURAKLATILDI"
	title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	desc_label.text = "Çizim masasına kısa bir mola."
	primary_button.text = "DEVAM ET"
	secondary_button.visible = true
	secondary_button.text = "YENİDEN BAŞLAT"
	if menu_button:
		menu_button.visible = true
	visible = true
	get_tree().paused = true

func show_game_over(survival_time_str: String, level_reached: int) -> void:
	current_mode = "game_over"
	title_label.text = "KAĞIT YIRTILDI!"
	title_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.25))
	desc_label.text = "Karakterin mürekkebi tükendi...\nHayatta Kalma: %s | Ulaşılan Seviye: %d" % [survival_time_str, level_reached]
	primary_button.text = "TEKRAR DENE"
	secondary_button.visible = false
	if menu_button:
		menu_button.visible = true
	visible = true
	get_tree().paused = true

func show_victory(survival_time_str: String) -> void:
	current_mode = "victory"
	title_label.text = "DESTANSI ZAFER!"
	title_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	desc_label.text = "Doodle Krallığı'nı dize getirdin!\nToplam Süre: %s" % survival_time_str
	primary_button.text = "YENİDEN OYNA"
	secondary_button.visible = false
	if menu_button:
		menu_button.visible = true
	visible = true
	get_tree().paused = true

func _play_btn_sfx() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.08)

func _on_primary_pressed() -> void:
	_play_btn_sfx()
	if current_mode == "pause":
		visible = false
		get_tree().paused = false
		resume_requested.emit()
	else:
		_restart_game()

func _on_secondary_pressed() -> void:
	_play_btn_sfx()
	_restart_game()

func _on_menu_pressed() -> void:
	_play_btn_sfx()
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _restart_game() -> void:
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()

