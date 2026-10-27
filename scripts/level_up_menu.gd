extends CanvasLayer

signal upgrade_selected(upgrade_data: Dictionary)

@onready var root_control: Control = $CenterContainer/RootControl
@onready var left_stack: TextureRect = $CenterContainer/RootControl/LeftStack
@onready var right_stack: TextureRect = $CenterContainer/RootControl/RightStack
@onready var step_indicator: Label = $CenterContainer/RootControl/ActiveParchment/CardContent/StepIndicator
@onready var icon_rect: TextureRect = $CenterContainer/RootControl/ActiveParchment/CardContent/IconContainer/IconRect
@onready var title_label: Label = $CenterContainer/RootControl/ActiveParchment/CardContent/TitleLabel
@onready var badge_label: Label = $CenterContainer/RootControl/ActiveParchment/CardContent/BadgeLabel
@onready var desc_label: Label = $CenterContainer/RootControl/ActiveParchment/CardContent/DescLabel
@onready var accept_button: Button = $CenterContainer/RootControl/ButtonsContainer/AcceptButton
@onready var skip_button: Button = $CenterContainer/RootControl/ButtonsContainer/SkipButton

var available_upgrades: Array[Dictionary] = [
	# --- 8 PAPERCRAFT SİLAH ---
	{
		"id": "weapon_bow",
		"title": "Avcı Yayı",
		"desc": "Hızlı ve düz hatlı delici oklar fırlatır.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_bow.tscn",
		"icon": "res://assets/sprites/weapons/weapon_bow.png"
	},
	{
		"id": "weapon_staff",
		"title": "Büyü Asası",
		"desc": "Yüksek hasarlı kristal enerji küreleri fırlatır.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_staff.tscn",
		"icon": "res://assets/sprites/weapons/weapon_staff.png"
	},
	{
		"id": "weapon_sword",
		"title": "Şövalye Kılıcı",
		"desc": "Geniş alanda kavisli savurma. Düşmanları biçer.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_sword.tscn",
		"icon": "res://assets/sprites/weapons/weapon_sword.png"
	},
	{
		"id": "weapon_axe",
		"title": "Savaş Baltası",
		"desc": "Ağır, ezici ve yüksek hasarlı kavisli balta savurması.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_axe.tscn",
		"icon": "res://assets/sprites/weapons/weapon_axe.png"
	},
	{
		"id": "weapon_dagger",
		"title": "Fırlatma Hançeri",
		"desc": "En yakın düşmana son derece seri hançerler atar.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_dagger.tscn",
		"icon": "res://assets/sprites/weapons/weapon_dagger.png"
	},
	{
		"id": "weapon_boomerang",
		"title": "Bumerang",
		"desc": "Düşmanları delip geçer ve dönerek tekrar vurur.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_boomerang.tscn",
		"icon": "res://assets/sprites/weapons/weapon_boomerang.png"
	},
	{
		"id": "weapon_spellbook",
		"title": "Büyü Kitabı",
		"desc": "Karakter etrafında dönerek yaklaşanları yakar.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_spellbook.tscn",
		"icon": "res://assets/sprites/weapons/weapon_spellbook.png"
	},
	{
		"id": "weapon_potion",
		"title": "İksir Şişesi",
		"desc": "Düşman kümesine atılır ve asit patlaması yaratır.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_potion.tscn",
		"icon": "res://assets/sprites/weapons/weapon_potion.png"
	},
	
	# --- 8 PASİF ÖZELLİK ---
	{
		"id": "passive_shoes",
		"title": "Koşu Ayakkabısı",
		"desc": "Hareket hızını %15 artırır.",
		"type": "stat",
		"stat": "move_speed",
		"value": 1.15,
		"icon": "res://assets/sprites/passives/passive_shoes.png"
	},
	{
		"id": "passive_heart",
		"title": "Kalp Kristali",
		"desc": "Maksimum canı +25 artırır ve canı yeniler.",
		"type": "stat",
		"stat": "max_health",
		"value": 25.0,
		"icon": "res://assets/sprites/passives/passive_heart.png"
	},
	{
		"id": "passive_bomb",
		"title": "Güç Bombası",
		"desc": "Tüm silahların hasarını %20 artırır.",
		"type": "stat",
		"stat": "damage_mult",
		"value": 1.20,
		"icon": "res://assets/sprites/passives/passive_bomb.png"
	},
	{
		"id": "passive_magnet",
		"title": "Çekim Mıknatısı",
		"desc": "XP kristalleri çekim menzilini %40 artırır.",
		"type": "stat",
		"stat": "magnet_range",
		"value": 1.40,
		"icon": "res://assets/sprites/passives/passive_magnet.png"
	},
	{
		"id": "passive_stopwatch",
		"title": "Hızlı Tetik",
		"desc": "Silahların saldırı bekleme süresini %15 azaltır.",
		"type": "stat",
		"stat": "cooldown_mult",
		"value": 0.85,
		"icon": "res://assets/sprites/passives/passive_stopwatch.png"
	},
	{
		"id": "passive_armor",
		"title": "Doodle Zırhı",
		"desc": "Alınan darbe hasarını kalıcı olarak %15 azaltır.",
		"type": "stat",
		"stat": "armor",
		"value": 0.15,
		"icon": "res://assets/sprites/passives/passive_armor.png"
	},
	{
		"id": "passive_clover",
		"title": "Şanslı Yonca",
		"desc": "Kritik vuruş şansını %15 artırır.",
		"type": "stat",
		"stat": "crit_chance",
		"value": 0.15,
		"icon": "res://assets/sprites/passives/passive_clover.png"
	},
	{
		"id": "passive_magnifier",
		"title": "Büyüteç",
		"desc": "Silahların savurma ve mermi etki alanını %20 büyütür.",
		"type": "stat",
		"stat": "area_mult",
		"value": 1.20,
		"icon": "res://assets/sprites/passives/passive_magnifier.png"
	}
]

var current_choices: Array[Dictionary] = []
var current_step: int = 0
var pending_levels: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	if accept_button:
		accept_button.pressed.connect(_on_accept_pressed)

func show_level_up_options() -> void:
	pending_levels += 1
	if visible:
		# Zaten bir kart açık, seçim yapılınca sıradaki seviye için yenilenecek
		return
		
	_open_menu()

func _open_menu() -> void:
	get_tree().paused = true
	visible = true
	
	var player: Node2D = get_tree().get_first_node_in_group("player")
	var valid_pool: Array[Dictionary] = []
	
	for item in available_upgrades:
		if item["type"] == "weapon":
			var w_id: String = item["id"]
			if player and player.has_method("has_weapon"):
				var has_it: bool = player.has_weapon(w_id)
				var cur_lvl: int = player.get_weapon_level(w_id)
				if has_it:
					if cur_lvl < 7:
						# Yükseltme seçeneği olarak havuza dahil et
						var copy_item: Dictionary = item.duplicate()
						copy_item["is_upgrade"] = true
						copy_item["target_level"] = cur_lvl + 1
						valid_pool.append(copy_item)
				else:
					# Yeni silah: Sadece boş slot varsa öner
					if player.has_free_weapon_slot():
						var copy_item: Dictionary = item.duplicate()
						copy_item["is_upgrade"] = false
						valid_pool.append(copy_item)
			else:
				valid_pool.append(item)
		else:
			# Pasif özellikler (Maksimum 5 seviye, slot kontrolü)
			var p_id: String = item["id"]
			if player and player.has_method("has_passive"):
				var has_p: bool = player.has_passive(p_id)
				var cur_p_lvl: int = player.get_passive_level(p_id)
				if has_p:
					if cur_p_lvl < 5:
						var copy_item: Dictionary = item.duplicate()
						copy_item["is_upgrade"] = true
						copy_item["target_level"] = cur_p_lvl + 1
						valid_pool.append(copy_item)
				else:
					if player.has_free_passive_slot():
						var copy_item: Dictionary = item.duplicate()
						copy_item["is_upgrade"] = false
						copy_item["target_level"] = 1
						valid_pool.append(copy_item)
			else:
				valid_pool.append(item)
			
	if valid_pool.is_empty():
		valid_pool = available_upgrades.duplicate()
		
	valid_pool.shuffle()
	
	current_choices = []
	var take_count := mini(3, valid_pool.size())
	for i in range(take_count):
		current_choices.append(valid_pool[i])
		
	# Eğer 3'ten azsa tekrarla doldur
	while current_choices.size() < 3:
		current_choices.append(available_upgrades.pick_random())
		
	current_step = 0
	_display_current_step()

func _display_current_step() -> void:
	var data: Dictionary = current_choices[current_step]
	
	step_indicator.text = "%d. ŞANS" % [current_step + 1]
	title_label.text = data["title"]
	
	if data.get("is_upgrade", false):
		var next_lvl: int = data.get("target_level", 2)
		badge_label.text = "[YÜKSELTME Lv.%d]" % next_lvl
		badge_label.add_theme_color_override("font_color", Color(0.85, 0.5, 0.1))
		if data["type"] == "weapon":
			desc_label.text = "Hasar artışı (+%%35), atış bekleme süresi kısalması (-%%10)."
			if next_lvl == 3 or next_lvl == 5 or next_lvl == 7:
				desc_label.text += " +1 Ekstra Mermi / Savurma!"
		else:
			desc_label.text = data["desc"] + " (Seviye %d etkisi)." % next_lvl
	elif data["type"] == "weapon":
		badge_label.text = "[YENİ SİLAH]"
		badge_label.add_theme_color_override("font_color", Color(0.15, 0.4, 0.6))
		desc_label.text = data["desc"]
	else:
		badge_label.text = "[YENİ PASİF]"
		badge_label.add_theme_color_override("font_color", Color(0.2, 0.45, 0.25))
		desc_label.text = data["desc"]
		
	if data.has("icon"):
		var tex: Texture2D = load(data["icon"])
		icon_rect.texture = tex
		
	# Katman/Deste Görünürlüğü (Mockup'taki gibi)
	left_stack.visible = current_step > 0
	right_stack.visible = current_step < 2
	
	# Butonlar
	if current_step < 2:
		skip_button.visible = true
		skip_button.text = "GEÇ"
		accept_button.text = "SEÇ"
	else:
		skip_button.visible = false
		accept_button.text = "MECBURİ AL"

func _on_skip_pressed() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.08)
	if current_step < 2:
		current_step += 1
		_display_current_step()

func _on_accept_pressed() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.05, 2.0)
	var chosen: Dictionary = current_choices[current_step]
	upgrade_selected.emit(chosen)
	
	pending_levels = maxi(0, pending_levels - 1)
	if pending_levels > 0:
		# Sırada başka seviye atlama varsa hemen yeni kartları aç
		_open_menu()
	else:
		visible = false
		get_tree().paused = false
