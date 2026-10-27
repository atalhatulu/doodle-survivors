extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var shop_button: Button = $VBoxContainer/ShopButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var coin_label: Label = $TopRightContainer/CoinContainer/CoinLabel

func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if shop_button:
		shop_button.pressed.connect(_on_shop_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		
	_update_coins()

func _update_coins() -> void:
	var meta = get_node_or_null("/root/MetaProgression")
	if meta and coin_label:
		coin_label.text = str(meta.total_coins)

func _play_btn_sfx() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.08)

func _on_play_pressed() -> void:
	_play_btn_sfx()
	get_tree().change_scene_to_file("res://scenes/world/main.tscn")

func _on_shop_pressed() -> void:
	_play_btn_sfx()
	get_tree().change_scene_to_file("res://scenes/ui/shop_menu.tscn")

func _on_quit_pressed() -> void:
	_play_btn_sfx()
	get_tree().quit()
