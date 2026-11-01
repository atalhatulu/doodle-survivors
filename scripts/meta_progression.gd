extends Node

const SAVE_PATH: String = "user://doodle_save.json"

var total_coins: int = 0

var selected_character_id: String = "knight"

const CHARACTERS: Dictionary = {
	"knight": {
		"id": "knight",
		"name": "Sürgün Şövalye",
		"title": "Sadakat Yemini",
		"desc": "Ağır çelik zırh kuşanmış, hayatta kalan son şövalye.",
		"weapon_id": "weapon_sword",
		"weapon_title": "Şövalye Kılıcı",
		"weapon_scene": "res://scenes/weapons/weapon_sword.tscn",
		"weapon_icon": "res://assets/sprites/weapons/weapon_sword.png",
		"portrait": "res://assets/sprites/characters/char_knight.png",
		"tint": Color(0.9, 0.95, 1.0),
		"stat_mods": {
			"armor": 0.15,
			"max_health": 25.0,
			"move_speed_mult": 0.95
		},
		"bonuses_text": "+%15 Zırh\n+25 Maks. Can\n-%5 Hareket Hızı"
	},
	"mage": {
		"id": "mage",
		"name": "Karanlık Büyücü",
		"title": "Yasak Arkana",
		"desc": "Kadim arşivi ateşe verip yasak büyüleri kuşanan alim.",
		"weapon_id": "weapon_staff",
		"weapon_title": "Büyü Asası",
		"weapon_scene": "res://scenes/weapons/weapon_staff.tscn",
		"weapon_icon": "res://assets/sprites/weapons/weapon_staff.png",
		"portrait": "res://assets/sprites/characters/char_mage.png",
		"tint": Color(0.85, 0.65, 1.0),
		"stat_mods": {
			"area_mult": 1.20,
			"cooldown_mult": 0.90,
			"max_health": -15.0
		},
		"bonuses_text": "+%20 Etki Alanı\n-%10 Bekleme Süresi\n-15 Maks. Can"
	},
	"ranger": {
		"id": "ranger",
		"name": "Orman Korucusu",
		"title": "Gölge Avcısı",
		"desc": "Fısıldayan koruların en çevik ve ölümcül gölge izcisi.",
		"weapon_id": "weapon_bow",
		"weapon_title": "Avcı Yayı",
		"weapon_scene": "res://scenes/weapons/weapon_bow.tscn",
		"weapon_icon": "res://assets/sprites/weapons/weapon_bow.png",
		"portrait": "res://assets/sprites/characters/char_ranger.png",
		"tint": Color(0.75, 1.0, 0.75),
		"stat_mods": {
			"move_speed_mult": 1.15,
			"luck": 0.15,
			"projectile_speed_mult": 1.10
		},
		"bonuses_text": "+%15 Hareket Hızı\n+%15 Şans\n+%10 Mermi Hızı"
	},
	"alchemist": {
		"id": "alchemist",
		"name": "Kızıl Simyager",
		"title": "İksir Ustası",
		"desc": "Zehirli asitler damıtıp bedeni sürekli tazeleyen kan simyacısı.",
		"weapon_id": "weapon_potion",
		"weapon_title": "İksir Şişesi",
		"weapon_scene": "res://scenes/weapons/weapon_potion.tscn",
		"weapon_icon": "res://assets/sprites/weapons/weapon_potion.png",
		"portrait": "res://assets/sprites/characters/char_alchemist.png",
		"tint": Color(1.0, 0.75, 0.75),
		"stat_mods": {
			"duration_mult": 1.25,
			"hp_regen": 0.40,
			"xp_multiplier": 1.10
		},
		"bonuses_text": "+%25 Süre\n+0.4 Can/sn Yenilenme\n+%10 Büyüme (XP)"
	},
	"necromancer": {
		"id": "necromancer",
		"name": "Gölge Çağırıcı",
		"title": "Ruhların Efendisi",
		"desc": "Ölümün kadim sırlarına vakıf, ölen düşmanların ruhlarından sadık bir iskelet ordusu toplayan alim.",
		"weapon_id": "weapon_spirit_wolf",
		"weapon_title": "Ruhani Kurt",
		"weapon_scene": "res://scenes/weapons/weapon_spirit_wolf.tscn",
		"weapon_icon": "res://assets/sprites/weapons/spirit_wolf.png",
		"portrait": "res://assets/sprites/characters/char_necromancer.png",
		"tint": Color(0.65, 0.95, 0.7),
		"stat_mods": {
			"extra_projectiles": 1,
			"duration_mult": 1.25,
			"max_health": -10.0
		},
		"bonuses_text": "+1 Ekstra Mermi\n+%25 Süre\n-10 Maks. Can\n(Ruh Bağı: Ölenlerden İskelet Toplar)"
	}
}

var settings: Dictionary = {
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"music_volume": 0.8,
	"screen_shake": 1.0,
	"show_damage_numbers": true
}

# Satın Alınan Kalıcı Seviyeler (0-5)
var upgrades: Dictionary = {
	"health": 0,    # +10 Max Can
	"damage": 0,    # +%5 Hasar
	"speed": 0,     # +%4 Hareket Hızı
	"magnet": 0,    # +%15 Mıknatıs Alanı
	"crit": 0,      # +%3 Kritik Şansı
	"armor": 0      # +%3 Hasar İndirimi
}

# Stat Tanımları, Açıklamaları ve Kademe Başı Maliyetleri
const UPGRADE_DATA: Dictionary = {
	"health": {
		"title": "Karakter Sağlığı",
		"desc": "Kalıcı maksimum canı +10 artırır.",
		"costs": [10, 20, 40, 80, 150],
		"icon": "res://assets/sprites/passives/passive_heart.png"
	},
	"damage": {
		"title": "Savaş Gücü",
		"desc": "Tüm silahların hasarını kalıcı %5 artırır.",
		"costs": [15, 30, 60, 120, 250],
		"icon": "res://assets/sprites/passives/passive_bomb.png"
	},
	"speed": {
		"title": "Çeviklik",
		"desc": "Hareket hızını kalıcı %4 artırır.",
		"costs": [10, 20, 40, 80, 160],
		"icon": "res://assets/sprites/passives/passive_shoes.png"
	},
	"magnet": {
		"title": "Çekim Küresi",
		"desc": "XP ve altın çekim menzilini kalıcı %15 artırır.",
		"costs": [8, 16, 32, 64, 128],
		"icon": "res://assets/sprites/passives/passive_magnet.png"
	},
	"crit": {
		"title": "Kritik Vuruş",
		"desc": "Kritik vuruş şansını kalıcı %3 artırır.",
		"costs": [20, 40, 80, 160, 300],
		"icon": "res://assets/sprites/passives/passive_clover.png"
	},
	"armor": {
		"title": "Şövalye Zırhı",
		"desc": "Alınan hasarı kalıcı %3 azaltır.",
		"costs": [12, 24, 48, 96, 200],
		"icon": "res://assets/sprites/passives/passive_armor.png"
	}
}

func _ready() -> void:
	load_data()

func get_upgrade_cost(id: String) -> int:
	var lvl: int = upgrades.get(id, 0)
	var costs: Array = UPGRADE_DATA[id]["costs"]
	if lvl < costs.size():
		return costs[lvl]
	return -1 # Maksimum seviyede

func can_afford(id: String) -> bool:
	var cost := get_upgrade_cost(id)
	return cost != -1 and total_coins >= cost

func buy_upgrade(id: String) -> bool:
	if can_afford(id):
		var cost := get_upgrade_cost(id)
		total_coins -= cost
		upgrades[id] += 1
		save_data()
		return true
	return false

func refund_all() -> void:
	# Harcanan tüm altınları hesaplayıp iade et ve seviyeleri sıfırla
	var refund_amount := 0
	for id in upgrades.keys():
		var lvl: int = upgrades[id]
		var costs: Array = UPGRADE_DATA[id]["costs"]
		for i in range(lvl):
			refund_amount += int(costs[i])
		upgrades[id] = 0
		
	total_coins += refund_amount
	save_data()

func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data := {
			"total_coins": total_coins,
			"upgrades": upgrades,
			"settings": settings
		}
		file.store_string(JSON.stringify(data))
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		apply_settings()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_str := file.get_as_text()
		var parsed = JSON.parse_string(json_str)
		if parsed is Dictionary:
			if parsed.has("total_coins"):
				total_coins = int(parsed["total_coins"])
			if parsed.has("upgrades") and parsed["upgrades"] is Dictionary:
				for k in parsed["upgrades"].keys():
					if upgrades.has(k):
						upgrades[k] = int(parsed["upgrades"][k])
			if parsed.has("settings") and parsed["settings"] is Dictionary:
				for sk in parsed["settings"].keys():
					settings[sk] = parsed["settings"][sk]
		file.close()
	apply_settings()

func apply_settings() -> void:
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("apply_audio_settings"):
		var mv: float = float(settings.get("master_volume", 1.0))
		var sv: float = float(settings.get("sfx_volume", 1.0))
		var muv: float = float(settings.get("music_volume", 0.8))
		audio.apply_audio_settings(mv, sv, muv)

# Oyuncu doğduğunda bu fonksiyon kalıcı statları aktarır
func apply_to_player(player: Node) -> void:
	if not player:
		return
		
	# 1. Health
	var hp_lvl: int = upgrades.get("health", 0)
	player.max_health += hp_lvl * 10.0
	player.current_health = player.max_health
	
	# 2. Damage
	var dmg_lvl: int = upgrades.get("damage", 0)
	player.damage_multiplier += dmg_lvl * 0.05
	
	# 3. Speed
	var spd_lvl: int = upgrades.get("speed", 0)
	player.move_speed *= (1.0 + spd_lvl * 0.04)
	
	# 4. Magnet
	var mag_lvl: int = upgrades.get("magnet", 0)
	player.magnet_range_mult *= (1.0 + mag_lvl * 0.15)
	
	# 5. Crit
	var crit_lvl: int = upgrades.get("crit", 0)
	if "base_crit_chance" in player:
		player.base_crit_chance += crit_lvl * 0.03
	player.crit_chance += crit_lvl * 0.03
	
	# 6. Armor
	var arm_lvl: int = upgrades.get("armor", 0)
	player.armor = minf(0.70, player.armor + arm_lvl * 0.03)
