extends CanvasLayer

signal settings_closed()

@onready var master_slider: HSlider = $Dimmer/CenterContainer/VBox/Grid/MasterSlider
@onready var master_val_label: Label = $Dimmer/CenterContainer/VBox/Grid/MasterValLabel
@onready var sfx_slider: HSlider = $Dimmer/CenterContainer/VBox/Grid/SFXSlider
@onready var sfx_val_label: Label = $Dimmer/CenterContainer/VBox/Grid/SFXValLabel
@onready var music_slider: HSlider = $Dimmer/CenterContainer/VBox/Grid/MusicSlider
@onready var music_val_label: Label = $Dimmer/CenterContainer/VBox/Grid/MusicValLabel
@onready var shake_slider: HSlider = $Dimmer/CenterContainer/VBox/Grid/ShakeSlider
@onready var shake_val_label: Label = $Dimmer/CenterContainer/VBox/Grid/ShakeValLabel
@onready var damage_check: CheckButton = $Dimmer/CenterContainer/VBox/DamageBox/DamageCheck
@onready var close_btn: Button = $Dimmer/CenterContainer/VBox/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
	if master_slider:
		master_slider.value_changed.connect(_on_master_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if shake_slider:
		shake_slider.value_changed.connect(_on_shake_changed)
	if damage_check:
		damage_check.toggled.connect(_on_damage_toggled)

func open_settings() -> void:
	var meta = get_node_or_null("/root/MetaProgression")
	if meta:
		var s: Dictionary = meta.settings
		master_slider.value = float(s.get("master_volume", 1.0)) * 100.0
		sfx_slider.value = float(s.get("sfx_volume", 1.0)) * 100.0
		music_slider.value = float(s.get("music_volume", 0.8)) * 100.0
		shake_slider.value = float(s.get("screen_shake", 1.0)) * 100.0
		damage_check.button_pressed = bool(s.get("show_damage_numbers", true))
		_update_labels()
	visible = true

func _update_labels() -> void:
	if master_val_label:
		master_val_label.text = "%%%d" % int(master_slider.value)
	if sfx_val_label:
		sfx_val_label.text = "%%%d" % int(sfx_slider.value)
	if music_val_label:
		music_val_label.text = "%%%d" % int(music_slider.value)
	if shake_val_label:
		shake_val_label.text = "%%%d" % int(shake_slider.value)

func _on_master_changed(val: float) -> void:
	_update_labels()
	_apply_live()

func _on_sfx_changed(val: float) -> void:
	_update_labels()
	_apply_live()

func _on_music_changed(val: float) -> void:
	_update_labels()
	_apply_live()

func _on_shake_changed(val: float) -> void:
	_update_labels()
	_apply_live()

func _on_damage_toggled(_toggled: bool) -> void:
	_apply_live()

func _apply_live() -> void:
	var meta = get_node_or_null("/root/MetaProgression")
	if meta:
		meta.settings["master_volume"] = master_slider.value / 100.0
		meta.settings["sfx_volume"] = sfx_slider.value / 100.0
		meta.settings["music_volume"] = music_slider.value / 100.0
		meta.settings["screen_shake"] = shake_slider.value / 100.0
		meta.settings["show_damage_numbers"] = damage_check.button_pressed
		meta.apply_settings()

func _on_close_pressed() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.08)
	var meta = get_node_or_null("/root/MetaProgression")
	if meta:
		meta.save_data()
	visible = false
	settings_closed.emit()
