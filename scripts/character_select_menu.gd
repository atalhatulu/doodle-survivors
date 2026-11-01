extends Control

@onready var back_button: Button = $BottomContainer/BackButton

@onready var card_knight: TextureRect = $CardsContainer/CardKnight
@onready var btn_knight: Button = $CardsContainer/CardKnight/Content/SelectButton

@onready var card_mage: TextureRect = $CardsContainer/CardMage
@onready var btn_mage: Button = $CardsContainer/CardMage/Content/SelectButton

@onready var card_ranger: TextureRect = $CardsContainer/CardRanger
@onready var btn_ranger: Button = $CardsContainer/CardRanger/Content/SelectButton

@onready var card_alchemist: TextureRect = $CardsContainer/CardAlchemist
@onready var btn_alchemist: Button = $CardsContainer/CardAlchemist/Content/SelectButton

@onready var card_necromancer: TextureRect = $CardsContainer.get_node_or_null("CardNecromancer")
@onready var btn_necromancer: Button = $CardsContainer.get_node_or_null("CardNecromancer/Content/SelectButton")

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		
	_setup_card_listeners(card_knight, btn_knight, "knight")
	_setup_card_listeners(card_mage, btn_mage, "mage")
	_setup_card_listeners(card_ranger, btn_ranger, "ranger")
	_setup_card_listeners(card_alchemist, btn_alchemist, "alchemist")
	if card_necromancer and btn_necromancer:
		_setup_card_listeners(card_necromancer, btn_necromancer, "necromancer")

func _setup_card_listeners(card: TextureRect, btn: Button, char_id: String) -> void:
	if btn:
		btn.pressed.connect(func(): _select_character(char_id))
	if card:
		card.pivot_offset = card.custom_minimum_size * 0.5
		card.mouse_entered.connect(func():
			var tw := card.create_tween()
			tw.set_parallel(true)
			tw.tween_property(card, "scale", Vector2(1.04, 1.04), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "rotation_degrees", 0.8, 0.15)
			tw.tween_property(card, "modulate", Color(1.08, 1.06, 0.98), 0.15)
		)
		card.mouse_exited.connect(func():
			var tw := card.create_tween()
			tw.set_parallel(true)
			tw.tween_property(card, "scale", Vector2.ONE, 0.15)
			tw.tween_property(card, "rotation_degrees", 0.0, 0.15)
			tw.tween_property(card, "modulate", Color.WHITE, 0.15)
		)
		card.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_select_character(char_id)
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			_select_character("knight")
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			_select_character("mage")
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			_select_character("ranger")
		elif event.keycode == KEY_4 or event.keycode == KEY_KP_4:
			_select_character("alchemist")
		elif event.keycode == KEY_5 or event.keycode == KEY_KP_5:
			_select_character("necromancer")
		elif event.keycode == KEY_ESCAPE:
			_on_back_pressed()

func _select_character(char_id: String) -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.08, 1.8)
		
	var meta = get_node_or_null("/root/MetaProgression")
	if meta:
		meta.selected_character_id = char_id
		
	get_tree().change_scene_to_file("res://scenes/world/main_3d.tscn")

func _on_back_pressed() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.08)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
