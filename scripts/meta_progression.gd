extends Node

const SAVE_PATH: String = "user://doodle_save.json"

var total_coins: int = 0

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
		"title": "Doodle Sağlığı",
		"desc": "Kalıcı maksimum canı +10 artırır.",
		"costs": [10, 20, 40, 80, 150],
		"icon": "res://assets/sprites/passives/passive_heart.png"
	},
	"damage": {
		"title": "Kurşun Kalem Ucu",
		"desc": "Tüm silahların hasarını kalıcı %5 artırır.",
		"costs": [15, 30, 60, 120, 250],
		"icon": "res://assets/sprites/passives/passive_bomb.png"
	},
	"speed": {
		"title": "Hızlı Silgi",
		"desc": "Hareket hızını kalıcı %4 artırır.",
		"costs": [10, 20, 40, 80, 160],
		"icon": "res://assets/sprites/passives/passive_shoes.png"
	},
	"magnet": {
		"title": "Dev Mıknatıs",
		"desc": "XP ve ataş çekim menzilini kalıcı %15 artırır.",
		"costs": [8, 16, 32, 64, 128],
		"icon": "res://assets/sprites/passives/passive_magnet.png"
	},
	"crit": {
		"title": "Dört Yapraklı Yonca",
		"desc": "Kritik vuruş şansını kalıcı %3 artırır.",
		"costs": [20, 40, 80, 160, 300],
		"icon": "res://assets/sprites/passives/passive_clover.png"
	},
	"armor": {
		"title": "Mürekkep Zırhı",
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
			"upgrades": upgrades
		}
		file.store_string(JSON.stringify(data))
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
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
		file.close()

# Oyuncu doğduğunda bu fonksiyon kalıcı statları aktarır
func apply_to_player(player: Node2D) -> void:
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
	player.crit_chance += crit_lvl * 0.03
	
	# 6. Armor
	var arm_lvl: int = upgrades.get("armor", 0)
	player.armor = minf(0.70, player.armor + arm_lvl * 0.03)
