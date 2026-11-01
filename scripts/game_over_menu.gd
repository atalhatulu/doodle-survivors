extends CanvasLayer

signal restart_requested()
signal resume_requested()

@onready var title_label: Label = $Dimmer/CenterContainer/VBox/TitleLabel
@onready var desc_label: Label = $Dimmer/CenterContainer/VBox/DescLabel
@onready var stats_panel: PanelContainer = $Dimmer/CenterContainer/VBox/StatsPanel
@onready var stat_time_val: Label = $Dimmer/CenterContainer/VBox/StatsPanel/StatsMargin/StatsVBox/SummaryGrid/TimeVal
@onready var stat_kills_val: Label = $Dimmer/CenterContainer/VBox/StatsPanel/StatsMargin/StatsVBox/SummaryGrid/KillsVal
@onready var stat_gold_val: Label = $Dimmer/CenterContainer/VBox/StatsPanel/StatsMargin/StatsVBox/SummaryGrid/GoldVal
@onready var stat_level_val: Label = $Dimmer/CenterContainer/VBox/StatsPanel/StatsMargin/StatsVBox/SummaryGrid/LevelVal
@onready var dps_container: VBoxContainer = $Dimmer/CenterContainer/VBox/StatsPanel/StatsMargin/StatsVBox/DpsScroll/DpsContainer

@onready var primary_button: Button = $Dimmer/CenterContainer/VBox/Buttons/PrimaryButton
@onready var settings_button: Button = $Dimmer/CenterContainer/VBox/Buttons/SettingsButton
@onready var secondary_button: Button = $Dimmer/CenterContainer/VBox/Buttons/SecondaryButton
@onready var menu_button: Button = $Dimmer/CenterContainer/VBox/Buttons/MenuButton

var current_mode: String = "game_over" # "game_over", "victory", "pause"
var settings_scene: PackedScene = preload("res://scenes/ui/settings_menu.tscn")
const XPGem = preload("res://scripts/xp_gem.gd")
var active_settings_instance: Node = null

const WEAPON_NAMES: Dictionary = {
	"weapon_bow": "Avcı Yayı",
	"weapon_staff": "Büyü Asası",
	"weapon_sword": "Şövalye Kılıcı",
	"weapon_axe": "Savaş Baltası",
	"weapon_dagger": "Fırlatma Hançeri",
	"weapon_boomerang": "Bumerang",
	"weapon_spellbook": "Büyü Kitabı",
	"weapon_potion": "Simyager İksiri",
	"weapon_aura": "Kutsal Aura",
	"weapon_lightning": "Yıldırım Çağrısı",
	"weapon_earthquake": "Deprem Asası",
	"weapon_spirit_wolf": "Ruh Kurdu",
	"weapon_dragon_breath": "Ejderha Nefesi",
	"weapon_void_vortex": "Boşluk Girdabı",
	"weapon_evo_divine_sun": "İlahi Güneş Mabedi",
	"weapon_evo_hellfire_storm": "Cehennem Kıyameti",
	"weapon_evo_king_cleaver": "Kral Celladı",
	"weapon_evo_storm_quiver": "Fırtına Yaylımı",
	"weapon_evo_cosmic_archon": "Kozmik Hükümdar",
	"dash_kalkan_hucumu": "Kalkanla Hücum",
	"dash_boyut_sicramasi": "Boyut Sıçraması",
	"dash_shadow_roll": "Gölge Tuzağı",
	"shadow_trap": "Gölge Tuzağı",
	"dash_toxic_flash": "Zehirli Sis",
	"toxic_cloud": "Zehirli Sis",
	"char_necromancer": "İskelet Muhafız",
	"minion_skeleton": "İskelet Muhafız",
	"rezonans_toksik_patlama": "Toksik Patlama Rezonansı",
	"rezonans_super_iletken": "Süper İletken Rezonansı"
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if primary_button:
		primary_button.pressed.connect(_on_primary_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if secondary_button:
		secondary_button.pressed.connect(_on_secondary_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if visible and current_mode == "pause" and event.is_action_pressed("ui_cancel"):
		if active_settings_instance and is_instance_valid(active_settings_instance):
			return
		_on_primary_pressed()
		get_viewport().set_input_as_handled()

func show_pause() -> void:
	current_mode = "pause"
	title_label.text = "OYUN DURAKLATILDI"
	title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	desc_label.text = "Maceraya kısa bir mola."
	primary_button.text = "DEVAM ET"
	if settings_button:
		settings_button.visible = true
	secondary_button.visible = true
	secondary_button.text = "YENİDEN"
	if menu_button:
		menu_button.visible = true
		
	var hud = get_tree().current_scene.get_node_or_null("HUD") if get_tree().current_scene else null
	var time_str := "00:00"
	if hud and "timer_label" in hud and hud.timer_label:
		time_str = hud.timer_label.text
	var player: Node = _find_player()
	var lvl: int = player.current_level if player and "current_level" in player else 1
	_populate_run_summary(time_str, lvl)
	
	visible = true
	get_tree().paused = true

func show_game_over(survival_time_str: String, level_reached: int) -> void:
	current_mode = "game_over"
	title_label.text = "YENİLGİ!"
	title_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.25))
	desc_label.text = "Karanlık ordulara yenik düştün..."
	primary_button.text = "TEKRAR DENE"
	if settings_button:
		settings_button.visible = false
	secondary_button.visible = false
	if menu_button:
		menu_button.visible = true
		
	_populate_run_summary(survival_time_str, level_reached)
	visible = true
	get_tree().paused = true

func show_victory(survival_time_str: String) -> void:
	current_mode = "victory"
	title_label.text = "DESTANSI ZAFER!"
	title_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	desc_label.text = "Karanlık Krallığı dize getirdin!"
	primary_button.text = "YENİDEN OYNA"
	if settings_button:
		settings_button.visible = false
	secondary_button.visible = false
	if menu_button:
		menu_button.visible = true
		
	var player: Node = _find_player()
	var lvl: int = player.current_level if player and "current_level" in player else 1
	_populate_run_summary(survival_time_str, lvl)
	
	visible = true
	get_tree().paused = true

func _find_player() -> Node:
	var p: Node = null
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		p = tree.get_first_node_in_group("player")
	if not p and get_parent():
		if get_parent().is_in_group("player"):
			p = get_parent()
		elif get_parent().has_node("YSortEntities/Player"):
			p = get_parent().get_node("YSortEntities/Player")
		elif get_parent().has_node("Player3D"):
			p = get_parent().get_node("Player3D")
		elif get_parent().has_node("Player"):
			p = get_parent().get_node("Player")
		elif get_parent().is_inside_tree() and get_parent().get_tree():
			p = get_parent().get_tree().get_first_node_in_group("player")
		else:
			for ch in get_parent().get_children():
				if ch.is_in_group("player"):
					p = ch
					break
	return p

func _populate_run_summary(survival_time_str: String, level_reached: int) -> void:
	if not stat_time_val:
		stat_time_val = get_node_or_null("Dimmer/CenterContainer/VBox/StatsPanel/StatsMargin/StatsVBox/SummaryGrid/TimeVal")
	if not stat_kills_val:
		stat_kills_val = get_node_or_null("Dimmer/CenterContainer/VBox/StatsPanel/StatsMargin/StatsVBox/SummaryGrid/KillsVal")
	if not stat_gold_val:
		stat_gold_val = get_node_or_null("Dimmer/CenterContainer/VBox/StatsPanel/StatsMargin/StatsVBox/SummaryGrid/GoldVal")
	if not stat_level_val:
		stat_level_val = get_node_or_null("Dimmer/CenterContainer/VBox/StatsPanel/StatsMargin/StatsVBox/SummaryGrid/LevelVal")
	if not dps_container:
		dps_container = get_node_or_null("Dimmer/CenterContainer/VBox/StatsPanel/StatsMargin/StatsVBox/DpsScroll/DpsContainer")

	var player: Node = _find_player()
	
	if stat_time_val:
		stat_time_val.text = survival_time_str
	if stat_level_val:
		stat_level_val.text = "Lv.%d" % level_reached
	if stat_kills_val:
		var kills: int = player.total_enemies_killed if (player and "total_enemies_killed" in player) else 0
		stat_kills_val.text = "%d" % kills
	if stat_gold_val:
		var gold: int = player.coins_in_run if (player and "coins_in_run" in player) else 0
		stat_gold_val.text = "%d" % gold
		
	if dps_container:
		for c in dps_container.get_children():
			c.queue_free()
			
		var tracker: Dictionary = player.weapon_damage_tracker if (player and "weapon_damage_tracker" in player) else {}
		var total_dmg: float = 0.0
		for dmg in tracker.values():
			total_dmg += float(dmg)
			
		if tracker.is_empty() or total_dmg <= 0.0:
			var empty_lbl := Label.new()
			empty_lbl.text = "Henüz kayıtlı silah hasarı bulunmuyor."
			empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
			empty_lbl.add_theme_font_size_override("font_size", 12)
			dps_container.add_child(empty_lbl)
		else:
			var time_parts := survival_time_str.split(":")
			var run_seconds: float = 1.0
			if time_parts.size() == 2:
				run_seconds = float(time_parts[0].to_int() * 60 + time_parts[1].to_int())
			elif time_parts.size() == 3:
				run_seconds = float(time_parts[0].to_int() * 3600 + time_parts[1].to_int() * 60 + time_parts[2].to_int())
			run_seconds = maxf(run_seconds, 1.0)

			var sorted_weapons: Array = tracker.keys()
			sorted_weapons.sort_custom(func(a, b): return tracker[a] > tracker[b])
			
			for w_id in sorted_weapons:
				var dmg: float = tracker[w_id]
				var pct: float = (dmg / total_dmg) * 100.0
				var dps: float = dmg / run_seconds
				var w_name: String = WEAPON_NAMES.get(w_id, w_id)
				
				var row := HBoxContainer.new()
				row.custom_minimum_size = Vector2(0, 24)
				row.add_theme_constant_override("separation", 8)
				
				var name_lbl := Label.new()
				name_lbl.text = w_name
				name_lbl.custom_minimum_size = Vector2(140, 0)
				name_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
				name_lbl.add_theme_font_size_override("font_size", 13)
				row.add_child(name_lbl)
				
				var bar := ProgressBar.new()
				bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				bar.custom_minimum_size = Vector2(70, 12)
				bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				bar.max_value = 100.0
				bar.value = pct
				bar.show_percentage = false
				
				var bg_sb := StyleBoxFlat.new()
				bg_sb.bg_color = Color(0.1, 0.08, 0.07, 0.7)
				bg_sb.corner_radius_top_left = 3
				bg_sb.corner_radius_top_right = 3
				bg_sb.corner_radius_bottom_right = 3
				bg_sb.corner_radius_bottom_left = 3
				bar.add_theme_stylebox_override("background", bg_sb)
				
				var fill_sb := StyleBoxFlat.new()
				fill_sb.bg_color = Color(0.95, 0.65, 0.25, 0.9)
				fill_sb.corner_radius_top_left = 3
				fill_sb.corner_radius_top_right = 3
				fill_sb.corner_radius_bottom_right = 3
				fill_sb.corner_radius_bottom_left = 3
				bar.add_theme_stylebox_override("fill", fill_sb)
				row.add_child(bar)
				
				var dmg_lbl := Label.new()
				dmg_lbl.text = "%d (%d%%) | %.1f DPS" % [int(dmg), int(pct), dps]
				dmg_lbl.custom_minimum_size = Vector2(140, 0)
				dmg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				dmg_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
				dmg_lbl.add_theme_font_size_override("font_size", 12)
				row.add_child(dmg_lbl)
				
				dps_container.add_child(row)

func _play_btn_sfx() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.08)

func _on_settings_pressed() -> void:
	_play_btn_sfx()
	if not active_settings_instance or not is_instance_valid(active_settings_instance):
		if settings_scene:
			active_settings_instance = settings_scene.instantiate()
			add_child(active_settings_instance)

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
	XPGem.reset_pool()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _restart_game() -> void:
	visible = false
	get_tree().paused = false
	XPGem.reset_pool()
	get_tree().reload_current_scene()
