extends Node2D

@onready var player: Node2D = $YSortEntities/Player
@onready var level_up_menu: CanvasLayer = $LevelUpMenu
@onready var enemy_spawner: Node2D = $EnemySpawner
@onready var hud: CanvasLayer = $HUD
@onready var game_over_menu: CanvasLayer = $GameOverMenu

var is_game_finished: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	if player:
		player.level_up.connect(_on_player_level_up)
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
			
	if level_up_menu:
		level_up_menu.upgrade_selected.connect(_on_upgrade_selected)
		
	if enemy_spawner and enemy_spawner.has_signal("king_boss_defeated"):
		enemy_spawner.king_boss_defeated.connect(_on_king_boss_defeated)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # ESC tuşu
		if is_game_finished:
			return
		if level_up_menu and level_up_menu.visible:
			return
		if game_over_menu:
			if game_over_menu.visible:
				game_over_menu._on_primary_pressed()
			else:
				game_over_menu.show_pause()

func _on_player_level_up(_new_level: int) -> void:
	if is_game_finished:
		return
	if level_up_menu:
		level_up_menu.show_level_up_options()

func _on_upgrade_selected(upgrade_data: Dictionary) -> void:
	if player and player.has_method("apply_upgrade"):
		player.apply_upgrade(upgrade_data)

func _on_player_died() -> void:
	if is_game_finished:
		return
	is_game_finished = true
	
	var time_str := "00:00"
	if hud and "timer_label" in hud and hud.timer_label:
		time_str = hud.timer_label.text
	var lvl: int = player.current_level if player and "current_level" in player else 1
	
	# Kısa dramatik gecikme (0.6 saniye sonra göster)
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(func():
		if game_over_menu:
			game_over_menu.show_game_over(time_str, lvl)
	)

func _on_king_boss_defeated() -> void:
	if is_game_finished:
		return
	is_game_finished = true
	
	var time_str := "00:00"
	if hud and "timer_label" in hud and hud.timer_label:
		time_str = hud.timer_label.text
		
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(func():
		if game_over_menu:
			game_over_menu.show_victory(time_str)
	)
