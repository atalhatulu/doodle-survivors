extends Node

# Ses havuzu boyutu
const POOL_SIZE: int = 18

var sound_streams: Dictionary = {
	"hit": preload("res://assets/audio/sfx/sfx_hit.wav"),
	"pencil_slash": preload("res://assets/audio/sfx/sfx_pencil_slash.wav"),
	"shoot": preload("res://assets/audio/sfx/sfx_shoot_bullet.wav"),
	"axe_throw": preload("res://assets/audio/sfx/sfx_axe_throw.wav"),
	"coin": preload("res://assets/audio/sfx/sfx_coin_paperclip.wav"),
	"xp": preload("res://assets/audio/sfx/sfx_xp_pickup.wav"),
	"level_up": preload("res://assets/audio/sfx/sfx_level_up.wav"),
	"enemy_die": preload("res://assets/audio/sfx/sfx_enemy_die.wav"),
	"button_click": preload("res://assets/audio/sfx/sfx_button_click.wav"),
	"game_over": preload("res://assets/audio/sfx/sfx_game_over.wav")
}

# Aynı sesin saniyede onlarca kez çalarak kulak tırmalamasını önleyen bekleme süreleri
var cooldown_times: Dictionary = {
	"hit": 0.045,
	"xp": 0.035,
	"coin": 0.040,
	"enemy_die": 0.050,
	"shoot": 0.040,
	"pencil_slash": 0.060,
	"axe_throw": 0.080,
	"button_click": 0.050,
	"level_up": 0.200,
	"game_over": 1.000
}

# Ses başına temel desibel dengesi
var volume_offsets: Dictionary = {
	"hit": -4.0,
	"pencil_slash": -2.0,
	"shoot": -3.0,
	"axe_throw": -1.0,
	"coin": -2.0,
	"xp": -6.0,
	"level_up": 2.0,
	"enemy_die": -3.0,
	"button_click": 0.0,
	"game_over": 1.0
}

var last_played_times: Dictionary = {}
var player_pool: Array[AudioStreamPlayer] = []
var next_player_index: int = 0
var music_player: AudioStreamPlayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Oyun duraklatıldığında da UI sesleri çalsın
	_setup_buses()
	
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		player_pool.append(p)
		
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

func _setup_buses() -> void:
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var sfx_idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var mus_idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(mus_idx, "Music")
		AudioServer.set_bus_send(mus_idx, "Master")

func set_bus_volume_linear(bus_name: String, linear_val: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		if linear_val <= 0.001:
			AudioServer.set_bus_mute(idx, true)
		else:
			AudioServer.set_bus_mute(idx, false)
			AudioServer.set_bus_volume_db(idx, linear_to_db(linear_val))

func set_volume(bus_name: String, linear_val: float) -> void:
	set_bus_volume_linear(bus_name.capitalize(), linear_val)

func apply_audio_settings(master_vol: float, sfx_vol: float, music_vol: float) -> void:
	set_bus_volume_linear("Master", master_vol)
	set_bus_volume_linear("SFX", sfx_vol)
	set_bus_volume_linear("Music", music_vol)

func play_sfx(sound_name: String, pitch_range: float = 0.12, volume_db_mod: float = 0.0) -> void:
	if not sound_streams.has(sound_name):
		return
		
	var now := Time.get_ticks_msec() / 1000.0
	var min_interval: float = cooldown_times.get(sound_name, 0.0)
	
	if last_played_times.has(sound_name):
		if (now - last_played_times[sound_name]) < min_interval:
			return
			
	last_played_times[sound_name] = now
	
	# Boşta olan veya sıradaki oynatıcıyı bul
	var player := _get_available_player()
	player.stream = sound_streams[sound_name]
	
	# Ton varyasyonu (Pitch shifting)
	var base_pitch := 1.0
	if pitch_range > 0.0:
		player.pitch_scale = randf_range(base_pitch - pitch_range, base_pitch + pitch_range)
	else:
		player.pitch_scale = 1.0
		
	var base_vol: float = volume_offsets.get(sound_name, 0.0)
	player.volume_db = base_vol + volume_db_mod
	player.play()

func _get_available_player() -> AudioStreamPlayer:
	# Önce çalmada olmayan bir oyuncu ara
	for p in player_pool:
		if not p.playing:
			return p
			
	# Hepsi meşgulse sıradakini ödünç al (round-robin)
	var p = player_pool[next_player_index]
	next_player_index = (next_player_index + 1) % POOL_SIZE
	return p
