extends CanvasLayer

signal upgrade_selected(upgrade_data: Dictionary)

@onready var root_control: Control = $CenterContainer/RootControl
@onready var cards_container: HBoxContainer = $CenterContainer/RootControl/CardsContainer
@onready var card_nodes: Array[Node] = [
	$CenterContainer/RootControl/CardsContainer/Card0,
	$CenterContainer/RootControl/CardsContainer/Card1,
	$CenterContainer/RootControl/CardsContainer/Card2
]
@onready var reroll_button: Button = $CenterContainer/RootControl/BottomBar/RerollButton
@onready var skip_button: Button = $CenterContainer/RootControl/BottomBar/SkipButton

var rerolls_remaining: int = 2
var pending_levels: int = 0
var is_selecting: bool = false
var current_choices: Array[Dictionary] = []
var valid_pool: Array[Dictionary] = []

var available_upgrades: Array[Dictionary] = [
	# --- 14 SİLAH ---
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
	{
		"id": "weapon_aura",
		"title": "Kutsal Aura",
		"desc": "Etrafında kadim bir rün aurası yayarak yaklaşan düşmanları yakar ve geri iter.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_aura.tscn",
		"icon": "res://assets/sprites/weapons/weapon_aura.png"
	},
	{
		"id": "weapon_lightning",
		"title": "Yıldırım Çağrısı",
		"desc": "Gökyüzünden düşmanların tepesine anlık yıldırımlar indirir ve elektrik şoku bırakır.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_lightning.tscn",
		"icon": "res://assets/sprites/weapons/weapon_lightning.png"
	},
	{
		"id": "weapon_dragon_breath",
		"title": "Ejderha Nefesi",
		"desc": "Baktığın yöne doğru aralıksız ejderha alevi püskürterek önündeki sürüleri süpürür.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_dragon_breath.tscn",
		"icon": "res://assets/sprites/weapons/weapon_dragon_breath.png"
	},
	{
		"id": "weapon_void_vortex",
		"title": "Hiçlik Girdabı",
		"desc": "Düşman kümesinin ortasında kara delik açarak içine çeker, ezer ve patlatır.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_void_vortex.tscn",
		"icon": "res://assets/sprites/weapons/weapon_void_vortex.png"
	},
	{
		"id": "weapon_spirit_wolf",
		"title": "Ruhani Kurt",
		"desc": "Savaş alanında özgürce koşan, en yakın düşmanlara atılıp parçalayan bir yoldaş çağırır.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_spirit_wolf.tscn",
		"icon": "res://assets/sprites/weapons/spirit_wolf.png"
	},
	{
		"id": "weapon_earthquake",
		"title": "Savaş Narası",
		"desc": "360 derece sismik şok dalgasıyla düşmanları savurur. Zırhın ve canınla güçlenir.",
		"type": "weapon",
		"scene": "res://scenes/weapons/weapon_earthquake.tscn",
		"icon": "res://assets/sprites/weapons/weapon_earthquake.png"
	},
	
	# --- 19 PASİF EŞYA ---
	{
		"id": "passive_shoes",
		"title": "Rüzgar Çizmeleri",
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
		"title": "Kuvvet Tılsımı",
		"desc": "Tüm silahların hasarını %20 artırır.",
		"type": "stat",
		"stat": "damage_mult",
		"value": 1.20,
		"icon": "res://assets/sprites/passives/passive_bomb.png"
	},
	{
		"id": "passive_magnet",
		"title": "Çekim Küresi",
		"desc": "XP kristalleri çekim menzilini %40 artırır.",
		"type": "stat",
		"stat": "magnet_range",
		"value": 1.40,
		"icon": "res://assets/sprites/passives/passive_magnet.png"
	},
	{
		"id": "passive_stopwatch",
		"title": "Zaman Mührü",
		"desc": "Silahların saldırı bekleme süresini %15 azaltır.",
		"type": "stat",
		"stat": "cooldown_mult",
		"value": 0.85,
		"icon": "res://assets/sprites/passives/passive_stopwatch.png"
	},
	{
		"id": "passive_armor",
		"title": "Şövalye Zırhı",
		"desc": "Alınan darbe hasarını kalıcı olarak %15 azaltır.",
		"type": "stat",
		"stat": "armor",
		"value": 0.15,
		"icon": "res://assets/sprites/passives/passive_armor.png"
	},
	{
		"id": "passive_clover",
		"title": "Şanslı Yonca",
		"desc": "Şansı %15 artırır (Kritik vuruş ve sandık ödülü ihtimalini yükseltir).",
		"type": "stat",
		"stat": "luck",
		"value": 0.15,
		"icon": "res://assets/sprites/passives/passive_clover.png"
	},
	{
		"id": "passive_magnifier",
		"title": "Büyü Merceği",
		"desc": "Silahların savurma ve mermi etki alanını %20 büyütür.",
		"type": "stat",
		"stat": "area_mult",
		"value": 1.20,
		"icon": "res://assets/sprites/passives/passive_magnifier.png"
	},
	{
		"id": "passive_carbon_paper",
		"title": "Çoğaltıcı Mühür",
		"desc": "Silahların fırlattığı mermi ve saldırı sayısını +1 artırır (Maks +2).",
		"type": "stat",
		"stat": "extra_projectiles",
		"value": 1.0,
		"max_level": 2,
		"icon": "res://assets/sprites/passives/passive_carbon_paper.png"
	},
	{
		"id": "passive_bandage",
		"title": "Yaşam Sargısı",
		"desc": "Saniyede +0.3 Can yenilenmesi sağlar.",
		"type": "stat",
		"stat": "hp_regen",
		"value": 0.30,
		"icon": "res://assets/sprites/passives/passive_bandage.png"
	},
	{
		"id": "passive_rubber_band",
		"title": "Rüzgar Kolçağı",
		"desc": "Mermilerin ve fırlatılan silahların uçuş hızını %15 artırır.",
		"type": "stat",
		"stat": "projectile_speed",
		"value": 1.15,
		"icon": "res://assets/sprites/passives/passive_rubber_band.png"
	},
	{
		"id": "passive_hourglass",
		"title": "Kadim Kum Saati",
		"desc": "İksir havuzları ve silahların sahada kalma süresini %20 uzatır.",
		"type": "stat",
		"stat": "duration",
		"value": 1.20,
		"icon": "res://assets/sprites/passives/passive_hourglass.png"
	},
	{
		"id": "passive_graduation_cap",
		"title": "Bilgelik Tacı",
		"desc": "Kazanılan deneyim puanını (XP) %12 artırır.",
		"type": "stat",
		"stat": "xp_mult",
		"value": 1.12,
		"icon": "res://assets/sprites/passives/passive_graduation_cap.png"
	},
	{
		"id": "passive_piggy_bank",
		"title": "Taş Maske",
		"desc": "Düşen ve toplanan altın miktarını %20 artırır.",
		"type": "stat",
		"stat": "gold_mult",
		"value": 1.20,
		"icon": "res://assets/sprites/passives/passive_piggy_bank.png"
	},
	{
		"id": "passive_eraser_backup",
		"title": "Diriliş Tılsımı",
		"desc": "Ölünce %50 can ve şok dalgasıyla dirilme hakkı verir (+1 Can).",
		"type": "stat",
		"stat": "revive",
		"value": 1.0,
		"max_level": 2,
		"icon": "res://assets/sprites/passives/passive_eraser_backup.png"
	},
	{
		"id": "passive_ruler_shield",
		"title": "Muhafız Kalkanı",
		"desc": "Hasar aldıktan sonraki dokunulmazlık süresini 0.12sn uzatır.",
		"type": "stat",
		"stat": "invulnerability",
		"value": 0.12,
		"icon": "res://assets/sprites/passives/passive_ruler_shield.png"
	},
	{
		"id": "passive_ink_skull",
		"title": "Lanetli Kuru Kafa",
		"desc": "Lanet: Düşman gücü %10 artar ancak XP ve altın kazanımı %15 artar.",
		"type": "stat",
		"stat": "curse",
		"value": 1.10,
		"icon": "res://assets/sprites/passives/passive_ink_skull.png"
	},
	{
		"id": "passive_origami_box",
		"title": "Torrona'nın Kutusu",
		"desc": "Hasar, hız, alan ve süreyi %5 artırır. Son seviyede lanet katar.",
		"type": "stat",
		"stat": "torrona",
		"value": 1.05,
		"icon": "res://assets/sprites/passives/passive_origami_box.png"
	},
	{
		"id": "passive_sharpener",
		"title": "Mana Odağı",
		"desc": "Düşman akın sıklığını artırır ve altın düşürme şansını %35 katlar.",
		"type": "stat",
		"stat": "sharpener",
		"value": 1.15,
		"icon": "res://assets/sprites/passives/passive_sharpener.png"
	}
]

var weapon_evolutions: Array[Dictionary] = [
	{
		"id": "weapon_evo_divine_sun",
		"base_weapon_id": "weapon_aura",
		"required_passive_id": "passive_armor",
		"title": "İlahi Güneş Mabedi",
		"desc": "Kutsal Aura evrimi! Devasa güneş mandalası yakar ve her vuruşta can yeniler.",
		"type": "evolution",
		"scene": "res://scenes/weapons/weapon_evo_divine_sun.tscn",
		"icon": "res://assets/sprites/weapons/weapon_evo_divine_sun.png"
	},
	{
		"id": "weapon_evo_hellfire_storm",
		"base_weapon_id": "weapon_dragon_breath",
		"required_passive_id": "passive_hourglass",
		"title": "Cehennem Kıyameti",
		"desc": "Ejderha Nefesi evrimi! 360 derece dönen alev kasırgası ve yerde kalan lav havuzları.",
		"type": "evolution",
		"scene": "res://scenes/weapons/weapon_evo_hellfire_storm.tscn",
		"icon": "res://assets/sprites/weapons/weapon_evo_hellfire_storm.png"
	},
	{
		"id": "weapon_evo_king_cleaver",
		"base_weapon_id": "weapon_sword",
		"required_passive_id": "passive_bomb",
		"title": "Kral Celladı",
		"desc": "Şövalye Kılıcı evrimi! Çift devasa cellat palası 360 derece döner, biçer ve sersemletir.",
		"type": "evolution",
		"scene": "res://scenes/weapons/weapon_evo_king_cleaver.tscn",
		"icon": "res://assets/sprites/weapons/weapon_evo_king_cleaver.png"
	},
	{
		"id": "weapon_evo_storm_quiver",
		"base_weapon_id": "weapon_bow",
		"required_passive_id": "passive_carbon_paper",
		"title": "Fırtına Yaylımı",
		"desc": "Avcı Yayı evrimi! 7 adet delici göksel ok fırlatır ve şimşek kıvılcımları zincirlenir.",
		"type": "evolution",
		"scene": "res://scenes/weapons/weapon_evo_storm_quiver.tscn",
		"icon": "res://assets/sprites/weapons/weapon_evo_storm_quiver.png"
	},
	{
		"id": "weapon_evo_cosmic_archon",
		"base_weapon_id": "weapon_staff",
		"required_passive_id": "passive_magnifier",
		"title": "Kozmik Hükümdar",
		"desc": "Büyü Asası evrimi! 3 süpernova küresi dönerek düşmanlara kesintisiz kozmik lazerler sıkar.",
		"type": "evolution",
		"scene": "res://scenes/weapons/weapon_evo_cosmic_archon.tscn",
		"icon": "res://assets/sprites/weapons/weapon_evo_cosmic_archon.png"
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
		
	for i in range(card_nodes.size()):
		var card = card_nodes[i]
		if not card:
			continue
		var btn = card.get_node_or_null("CardContent/SelectButton")
		if btn:
			btn.pressed.connect(func(): _select_card(i))
		card.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_select_card(i)
		)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			_select_card(0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			_select_card(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			_select_card(2)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			_on_reroll_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE:
			_on_skip_pressed()
			get_viewport().set_input_as_handled()

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

func get_available_evolutions(player_node: Node = null) -> Array[Dictionary]:
	var p: Node = player_node if player_node else _find_player()
	var list: Array[Dictionary] = []
	if not p or not p.has_method("has_weapon") or not p.has_method("has_passive"):
		return list
	for evo in weapon_evolutions:
		var base_id: String = evo["base_weapon_id"]
		var req_passive: String = evo["required_passive_id"]
		var evo_id: String = evo["id"]
		if p.has_weapon(base_id) and p.get_weapon_level(base_id) >= 7:
			if p.has_passive(req_passive) and p.get_passive_level(req_passive) >= 1:
				if not p.has_weapon(evo_id):
					list.append(evo.duplicate())
	return list

func show_level_up_options(from_chest: bool = false) -> void:
	pending_levels += 1
	if visible:
		return
	_open_menu(from_chest)

func _open_menu(from_chest: bool = false) -> void:
	is_selecting = false
	if get_tree():
		get_tree().paused = true
	visible = true
	_build_valid_pool(null, from_chest)
	_roll_choices(from_chest)
	_update_reroll_button()

func _build_valid_pool(custom_player: Node = null, from_chest: bool = false) -> void:
	valid_pool.clear()
	var player: Node = custom_player if custom_player else _find_player()
	
	# Eğer sandıktan açılıyorsa ve hazır efsanevi evrim varsa havuzun en başına koy
	var available_evos := get_available_evolutions(player)
	for evo in available_evos:
		valid_pool.append(evo.duplicate())
	
	for item in available_upgrades:
		if item["type"] == "weapon":
			var w_id: String = item["id"]
			if player and player.has_method("has_weapon"):
				var has_it: bool = player.has_weapon(w_id)
				var cur_lvl: int = player.get_weapon_level(w_id)
				if has_it:
					if cur_lvl < 7:
						var copy_item: Dictionary = item.duplicate()
						copy_item["is_upgrade"] = true
						copy_item["target_level"] = cur_lvl + 1
						valid_pool.append(copy_item)
				else:
					if player.has_free_weapon_slot():
						var copy_item: Dictionary = item.duplicate()
						copy_item["is_upgrade"] = false
						copy_item["target_level"] = 1
						valid_pool.append(copy_item)
			else:
				valid_pool.append(item)
		else:
			# Pasif özellikler
			var p_id: String = item["id"]
			if player and player.has_method("has_passive"):
				var has_p: bool = player.has_passive(p_id)
				var cur_p_lvl: int = player.get_passive_level(p_id)
				var max_p_lvl: int = int(item.get("max_level", 5))
				if has_p:
					if cur_p_lvl < max_p_lvl:
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
				
	# Normal seviye atlamada da evrim havuzu mevcutsa ekle (eğer daha önce eklenmediyse)
	if not from_chest:
		for evo in available_evos:
			var already_in := false
			for v in valid_pool:
				if v.get("id") == evo.get("id"):
					already_in = true
					break
			if not already_in:
				valid_pool.append(evo.duplicate())
				
	if valid_pool.is_empty():
		valid_pool = [
			{
				"id": "pickup_heal",
				"title": "Şifa İksiri",
				"desc": "Anında 35 Can puanı yeniler.",
				"type": "consumable",
				"stat": "heal",
				"value": 35.0,
				"icon": "res://assets/sprites/passives/passive_heart.png"
			},
			{
				"id": "pickup_gold",
				"title": "Altın Kesesi",
				"desc": "Anında 50 Altın kazandırır.",
				"type": "consumable",
				"stat": "gold",
				"value": 50.0,
				"icon": "res://assets/sprites/passives/passive_piggy_bank.png"
			}
		]

func _roll_choices(from_chest: bool = false) -> void:
	valid_pool.shuffle()
	current_choices.clear()
	
	# Evrimler varsa her zaman en başa öncelikle yerleştir
	var evos: Array[Dictionary] = []
	var normals: Array[Dictionary] = []
	for it in valid_pool:
		if it.get("type") == "evolution":
			evos.append(it)
		else:
			normals.append(it)
			
	for e in evos:
		if current_choices.size() < 3:
			current_choices.append(e)
			
	var norm_idx := 0
	while current_choices.size() < mini(3, valid_pool.size()) and norm_idx < normals.size():
		current_choices.append(normals[norm_idx])
		norm_idx += 1
		
	# Havuzda 3'ten az farklı seçenek kaldıysa kopyalarla 3'e tamamla
	while current_choices.size() < 3 and not valid_pool.is_empty():
		current_choices.append(valid_pool.pick_random())
		
	_display_cards()

func _display_cards() -> void:
	for i in range(card_nodes.size()):
		var card = card_nodes[i]
		if i >= current_choices.size():
			card.visible = false
			continue
			
		card.visible = true
		var data: Dictionary = current_choices[i]
		
		var icon_rect: TextureRect = card.get_node_or_null("CardContent/IconContainer/IconRect")
		var title_label: Label = card.get_node_or_null("CardContent/TitleLabel")
		var badge_label: Label = card.get_node_or_null("CardContent/BadgeLabel")
		var desc_label: Label = card.get_node_or_null("CardContent/DescLabel")
		var select_btn: Button = card.get_node_or_null("CardContent/SelectButton")
		
		if title_label:
			title_label.text = data.get("title", "")
			title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
			title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
			title_label.add_theme_constant_override("outline_size", 5)
			
		if select_btn:
			select_btn.text = "SEÇ [%d]" % (i + 1)
			
		if badge_label and desc_label:
			badge_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
			badge_label.add_theme_constant_override("outline_size", 4)
			desc_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
			desc_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
			desc_label.add_theme_constant_override("outline_size", 4)
			
			if data.get("type", "") == "evolution":
				badge_label.text = "[EFSANEVİ EVRİM]"
				badge_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
				desc_label.text = data.get("desc", "")
			elif data.get("is_upgrade", false):
				var next_lvl: int = int(data.get("target_level", 2))
				badge_label.text = "[YÜKSELTME Lv.%d]" % next_lvl
				badge_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
				if data.get("type", "") == "weapon":
					var bonus_desc := "Hasar (+%35) ve Saldırı Hızı (+%10)."
					if next_lvl == 7:
						bonus_desc += "\nZirve Seviye Güç Patlaması!"
					desc_label.text = bonus_desc
				else:
					desc_label.text = data.get("desc", "") + "\n(Seviye %d etkisi)." % next_lvl
			elif data.get("type", "") == "weapon":
				badge_label.text = "[YENİ SİLAH]"
				badge_label.add_theme_color_override("font_color", Color(0.4, 0.82, 1.0))
				desc_label.text = data.get("desc", "")
			elif data.get("type", "") == "consumable":
				badge_label.text = "[SAHA ÖDÜLÜ]"
				badge_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
				desc_label.text = data.get("desc", "")
			else:
				badge_label.text = "[YENİ PASİF]"
				badge_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55))
				desc_label.text = data.get("desc", "")
				
		if icon_rect and data.has("icon"):
			var tex: Texture2D = load(data["icon"])
			icon_rect.texture = tex

func _update_reroll_button() -> void:
	if not reroll_button:
		return
	if rerolls_remaining > 0:
		reroll_button.disabled = false
		reroll_button.text = "YENİDEN ÇEK (%d Kaldı) [R]" % rerolls_remaining
	else:
		reroll_button.disabled = true
		reroll_button.text = "YENİDEN ÇEK (Tükendi) [R]"

func _on_reroll_pressed() -> void:
	if rerolls_remaining <= 0:
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.08, 1.2)
	rerolls_remaining -= 1
	_roll_choices()
	_update_reroll_button()

func _on_skip_pressed() -> void:
	if is_selecting:
		return
	is_selecting = true
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.08)
		
	# Pas geçildiğinde telafi olarak bir sonraki seviye için +%25 XP ödülü ver
	var player: Node = _find_player()
	if player and player.has_method("add_xp"):
		var next_xp_val: int = int(player.get("xp_to_next_level")) if "xp_to_next_level" in player else 25
		var bonus_xp: int = maxi(10, int(float(next_xp_val) * 0.25))
		player.add_xp(bonus_xp)
		
	pending_levels = maxi(0, pending_levels - 1)
	if pending_levels > 0:
		_open_menu()
	else:
		visible = false
		get_tree().paused = false
		is_selecting = false

func _select_card(index: int) -> void:
	if is_selecting:
		return
	if index < 0 or index >= current_choices.size():
		return
	is_selecting = true
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("button_click", 0.05, 2.0)
		
	var chosen: Dictionary = current_choices[index]
	upgrade_selected.emit(chosen)
	
	pending_levels = maxi(0, pending_levels - 1)
	if pending_levels > 0:
		_open_menu()
	else:
		visible = false
		get_tree().paused = false
		is_selecting = false
