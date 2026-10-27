extends Control

@onready var coin_label: Label = $HeaderContainer/CoinContainer/CoinLabel
@onready var cards_grid: GridContainer = $ScrollContainer/CardsGrid
@onready var refund_button: Button = $BottomContainer/RefundButton
@onready var back_button: Button = $BottomContainer/BackButton

func _ready() -> void:
	if refund_button:
		refund_button.pressed.connect(_on_refund_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		
	refresh_ui()

func refresh_ui() -> void:
	var meta = get_node_or_null("/root/MetaProgression")
	if not meta:
		return
		
	if coin_label:
		coin_label.text = str(meta.total_coins)
		
	# Grid içindeki mevcut kartları temizle
	for child in cards_grid.get_children():
		child.queue_free()
		
	# Her bir yükseltme için kart oluştur
	for stat_id in meta.UPGRADE_DATA.keys():
		var data: Dictionary = meta.UPGRADE_DATA[stat_id]
		var card := _create_upgrade_card(stat_id, data, meta)
		cards_grid.add_child(card)

func _create_upgrade_card(stat_id: String, data: Dictionary, meta: Node) -> PanelContainer:
	var current_lvl: int = meta.upgrades.get(stat_id, 0)
	var max_lvl: int = data["costs"].size()
	var cost: int = meta.get_upgrade_cost(stat_id)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 160)
	
	# Stil Kutusu
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.94, 0.88, 0.95) # Parşömen kağıdı
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.3, 0.25, 0.2, 1.0) # Mürekkep çerçevesi
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	# Üst Satır: İkon + Başlık + Seviye Barı
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	vbox.add_child(top_row)
	
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(data["icon"]):
		icon.texture = load(data["icon"])
	top_row.add_child(icon)
	
	var title_vbox := VBoxContainer.new()
	top_row.add_child(title_vbox)
	
	var title := Label.new()
	title.text = data["title"]
	title.add_theme_color_override("font_color", Color(0.18, 0.14, 0.1, 1.0))
	title.add_theme_font_size_override("font_size", 16)
	title_vbox.add_child(title)
	
	var pips := Label.new()
	var pips_str := ""
	for i in range(max_lvl):
		pips_str += "◆ " if i < current_lvl else "◇ "
	pips.text = pips_str + "(%d/%d)" % [current_lvl, max_lvl]
	pips.add_theme_color_override("font_color", Color(0.85, 0.5, 0.1, 1.0))
	pips.add_theme_font_size_override("font_size", 13)
	title_vbox.add_child(pips)
	
	# Açıklama
	var desc := Label.new()
	desc.text = data["desc"]
	desc.add_theme_color_override("font_color", Color(0.35, 0.3, 0.25, 1.0))
	desc.add_theme_font_size_override("font_size", 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)
	
	# Satın Alma Butonu
	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(0, 36)
	
	var btn_style := StyleBoxFlat.new()
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.corner_radius_bottom_left = 6
	
	if current_lvl >= max_lvl:
		buy_btn.text = "MAKSİMUM"
		buy_btn.disabled = true
		btn_style.bg_color = Color(0.5, 0.5, 0.5, 0.8)
	else:
		buy_btn.text = "GELİŞTİR (%d Ataş)" % cost
		if meta.total_coins >= cost:
			btn_style.bg_color = Color(0.2, 0.55, 0.25, 0.95)
			btn_style.border_color = Color(0.6, 0.9, 0.5, 1.0)
			btn_style.border_width_bottom = 2
		else:
			buy_btn.disabled = true
			btn_style.bg_color = Color(0.45, 0.45, 0.45, 0.6)
			
	buy_btn.add_theme_stylebox_override("normal", btn_style)
	buy_btn.add_theme_stylebox_override("hover", btn_style)
	buy_btn.add_theme_stylebox_override("pressed", btn_style)
	buy_btn.add_theme_stylebox_override("disabled", btn_style)
	
	buy_btn.pressed.connect(func():
		var audio = get_node_or_null("/root/AudioManager")
		if meta.buy_upgrade(stat_id):
			if audio:
				audio.play_sfx("coin", 0.08, 2.0)
			refresh_ui()
		else:
			if audio:
				audio.play_sfx("button_click", 0.05, -3.0)
	)
	vbox.add_child(buy_btn)
	
	return panel

func _on_refund_pressed() -> void:
	var meta = get_node_or_null("/root/MetaProgression")
	if meta:
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_sfx("coin", 0.05, 3.0)
		meta.refund_all()
		refresh_ui()

func _on_back_pressed() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.08)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
