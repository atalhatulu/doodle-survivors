extends CanvasLayer

@onready var panel: Panel = $CenterContainer/Panel
@onready var stats_label: RichTextLabel = $CenterContainer/Panel/MainHBox/LeftColumn/StatsLabel
@onready var weapons_label: RichTextLabel = $CenterContainer/Panel/MainHBox/RightColumn/WeaponsLabel
@onready var passives_label: RichTextLabel = $CenterContainer/Panel/MainHBox/RightColumn/PassivesLabel

const WEAPON_NAMES := {
	"weapon_bow": "Avcı Yayı",
	"weapon_staff": "Büyü Asası",
	"weapon_sword": "Şövalye Kılıcı",
	"weapon_axe": "Savaş Baltası",
	"weapon_dagger": "Fırlatma Hançeri",
	"weapon_boomerang": "Bumerang",
	"weapon_spellbook": "Büyü Kitabı",
	"weapon_potion": "İksir Şişesi",
	"weapon_aura": "Kutsal Aura",
	"weapon_lightning": "Yıldırım Çağrısı",
	"weapon_dragon_breath": "Ejderha Nefesi",
	"weapon_void_vortex": "Hiçlik Girdabı",
	"weapon_spirit_wolf": "Ruhani Kurt",
	"weapon_earthquake": "Savaş Narası"
}

const PASSIVE_NAMES := {
	"passive_shoes": "Koşu Ayakkabısı",
	"passive_heart": "Kalp Kristali",
	"passive_bomb": "Güç Bombası",
	"passive_magnet": "Çekim Mıknatısı",
	"passive_stopwatch": "Hızlı Tetik",
	"passive_armor": "Şövalye Zırhı",
	"passive_clover": "Şanslı Yonca",
	"passive_magnifier": "Büyüteç",
	"passive_carbon_paper": "Çoğaltıcı Mühür",
	"passive_bandage": "Yaşam Sargısı",
	"passive_rubber_band": "Rüzgar Kolçağı",
	"passive_hourglass": "Kadim Kum Saati",
	"passive_graduation_cap": "Bilgelik Tacı",
	"passive_piggy_bank": "Taş Maske",
	"passive_eraser_backup": "Diriliş Tılsımı",
	"passive_ruler_shield": "Muhafız Kalkanı",
	"passive_ink_skull": "Lanetli Kuru Kafa",
	"passive_origami_box": "Torrona'nın Kutusu",
	"passive_sharpener": "Mana Odağı"
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		var root = get_tree().current_scene if get_tree() else null
		if root:
			var level_up = root.get_node_or_null("LevelUpMenu")
			var game_over = root.get_node_or_null("GameOverMenu")
			if (level_up and level_up.visible) or (game_over and game_over.visible):
				return
		toggle()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	visible = !visible
	if get_tree():
		get_tree().paused = visible
	if visible:
		_update_display()

func _update_display() -> void:
	if not get_tree():
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	if not stats_label:
		stats_label = get_node_or_null("CenterContainer/Panel/MainHBox/LeftColumn/StatsLabel")
	if not weapons_label:
		weapons_label = get_node_or_null("CenterContainer/Panel/MainHBox/RightColumn/WeaponsLabel")
	if not passives_label:
		passives_label = get_node_or_null("CenterContainer/Panel/MainHBox/RightColumn/PassivesLabel")
		
	# 1. 16 Temel Karakter İstatistiği (VS Formatı)
	var sheet: Dictionary = {}
	if player.has_method("get_stats_sheet"):
		sheet = player.get_stats_sheet()
		
	var st := ""
	st += "[color=#eedd88][b]Savaş İstatistikleri (11 Stat)[/b][/color]\n"
	st += "• [color=#9cdcfe]Maks. Can:[/color] %s  |  [color=#9cdcfe]Yenilenme:[/color] %s\n" % [
		sheet.get("max_health", {}).get("val", "%d HP" % int(player.max_health)),
		sheet.get("recovery", {}).get("val", "+%.1f HP/sn" % player.hp_regen)
	]
	st += "• [color=#9cdcfe]Zırh:[/color] %s  |  [color=#9cdcfe]Hareket Hızı:[/color] %s\n" % [
		sheet.get("armor", {}).get("val", "%%%d" % int(player.armor * 100)),
		sheet.get("move_speed", {}).get("val", "%%%d" % int((player.move_speed / 230.0) * 100))
	]
	st += "• [color=#9cdcfe]Hasar Gücü (Might):[/color] %s\n" % sheet.get("might", {}).get("val", "%%%d" % int(player.damage_multiplier * 100))
	st += "• [color=#9cdcfe]Etki Alanı (Area):[/color] %s  |  [color=#9cdcfe]Mermi Hızı:[/color] %s\n" % [
		sheet.get("area", {}).get("val", "%%%d" % int(player.area_mult * 100)),
		sheet.get("speed", {}).get("val", "%%%d" % int(player.projectile_speed_mult * 100))
	]
	st += "• [color=#9cdcfe]Süre (Duration):[/color] %s  |  [color=#9cdcfe]Bekleme Süresi:[/color] %s\n" % [
		sheet.get("duration", {}).get("val", "%%%d" % int(player.duration_mult * 100)),
		sheet.get("cooldown", {}).get("val", "%%%d" % int(player.cooldown_mult * 100))
	]
	st += "• [color=#9cdcfe]Mermi Miktarı (Amount):[/color] %s  |  [color=#9cdcfe]Şans (Luck):[/color] %s\n\n" % [
		sheet.get("amount", {}).get("val", "+%d" % player.extra_projectiles),
		sheet.get("luck", {}).get("val", "%%%d" % int(player.luck_mult * 100))
	]
	
	st += "[color=#88eebb][b]İlerleme ve Özel İstatistikler (5 Stat)[/b][/color]\n"
	st += "• [color=#9cdcfe]Büyüme (Growth - XP):[/color] %s\n" % sheet.get("growth", {}).get("val", "%%%d" % int(player.xp_multiplier * 100))
	st += "• [color=#9cdcfe]Açgözlülük (Greed - Altın):[/color] %s\n" % sheet.get("greed", {}).get("val", "%%%d" % int(player.gold_multiplier * 100))
	st += "• [color=#9cdcfe]Lanet (Curse):[/color] %s\n" % sheet.get("curse", {}).get("val", "%%%d" % int(player.curse_mult * 100))
	st += "• [color=#9cdcfe]Mıknatıs (Magnet Menzili):[/color] %s\n" % sheet.get("magnet", {}).get("val", "%%%d" % int(player.magnet_range_mult * 100))
	st += "• [color=#9cdcfe]Yeniden Doğma (Revival):[/color] %s\n" % sheet.get("revival", {}).get("val", "%d Can" % player.revives_remaining)
	
	stats_label.text = st
	
	# 2. Kuşanılan Silahlar
	var wt := ""
	var slot_index := 1
	if player.weapon_slots:
		for slot in player.weapon_slots.get_children():
			if slot.get_child_count() > 0:
				var weapon_node = slot.get_child(0)
				var w_lvl: int = 1
				var wid: String = weapon_node.weapon_id if "weapon_id" in weapon_node else ""
				if wid != "" and player.has_method("get_weapon_level"):
					w_lvl = player.get_weapon_level(wid)
				var clean_wname: String = WEAPON_NAMES.get(wid, weapon_node.name.replace("Weapon", "").capitalize())
				wt += "• [b]Slot %d:[/b] [color=#ffdd66]%s[/color] [color=#999999](Lv.%d / 7)[/color]\n" % [slot_index, clean_wname, w_lvl]
			else:
				wt += "• [color=#555555]Slot %d: [Boş Silah Yuvası][/color]\n" % slot_index
			slot_index += 1
	weapons_label.text = wt
	
	# 3. Kuşanılan Pasif Yadigar Eşyalar
	var pt := ""
	var p_count := 0
	if "owned_passives" in player and not player.owned_passives.is_empty():
		for pid in player.owned_passives.keys():
			p_count += 1
			var plvl: int = player.owned_passives[pid]
			var display_name: String = PASSIVE_NAMES.get(pid, pid.replace("passive_", "").capitalize())
			pt += "• [b]Slot %d:[/b] [color=#88ffaa]%s[/color] [color=#999999](Lv.%d / 5)[/color]\n" % [p_count, display_name, plvl]
			
	while p_count < 6:
		p_count += 1
		pt += "• [color=#555555]Slot %d: [Boş Pasif Yuvası][/color]\n" % p_count
		
	passives_label.text = pt
