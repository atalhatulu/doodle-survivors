extends CanvasLayer

@onready var panel: Panel = $CenterContainer/Panel
@onready var stats_label: Label = $CenterContainer/Panel/VBoxContainer/StatsLabel
@onready var weapons_label: Label = $CenterContainer/Panel/VBoxContainer/WeaponsLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle()

func toggle() -> void:
	visible = !visible
	get_tree().paused = visible
	if visible:
		_update_display()

func _update_display() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	# İstatistikler
	var stats_text := ""
	stats_text += "• Seviye: %d\n" % player.current_level
	stats_text += "• Can: %d / %d\n" % [int(player.current_health), int(player.max_health)]
	stats_text += "• Hareket Hızı: %d\n" % int(player.move_speed)
	stats_text += "• Hasar Çarpanı: x%.2f\n" % player.damage_multiplier
	stats_text += "• Mevcut XP: %d / %d\n" % [player.current_xp, player.xp_to_next_level]
	stats_label.text = stats_text
	
	# Kuşanılan Silahlar
	var weapons_text := ""
	var slot_index := 1
	if player.weapon_slots:
		for slot in player.weapon_slots.get_children():
			if slot.get_child_count() > 0:
				var weapon_node = slot.get_child(0)
				weapons_text += "Slot %d: %s\n" % [slot_index, weapon_node.name.replace("Weapon", "")]
			else:
				weapons_text += "Slot %d: [Boş]\n" % slot_index
			slot_index += 1
	weapons_label.text = weapons_text
