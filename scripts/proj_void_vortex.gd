extends Node2D

@export var vortex_radius: float = 140.0
@export var duration: float = 3.0
@export var tick_damage: float = 16.0
@export var is_crit: bool = false
@export var tick_interval: float = 0.28

var elapsed_time: float = 0.0
var tick_timer: float = 0.1 # İlk vuruş 0.1 sn sonra başlar
var is_exploding: bool = false

@onready var swirl: Sprite2D = $SwirlSprite
@onready var core: Sprite2D = $CoreSprite

func initialize(pos: Vector2, p_radius: float, p_duration: float, p_tick_damage: float, p_is_crit: bool) -> void:
	global_position = pos
	vortex_radius = p_radius
	duration = p_duration
	tick_damage = p_tick_damage
	is_crit = p_is_crit

func _init() -> void:
	add_to_group("void_vortices")

func _enter_tree() -> void:
	add_to_group("void_vortices")

func _ready() -> void:
	add_to_group("void_vortices")
	z_index = -1
	var target_scale: float = (vortex_radius * 2.0) / 256.0
	if swirl:
		swirl.scale = Vector2.ZERO
		swirl.modulate = Color(0.65, 0.2, 1.4, 0.85) # Mor kozmik girdap
	if core:
		core.scale = Vector2.ZERO
		core.modulate = Color(0.2, 0.05, 0.4, 0.95) # Çekirdek karanlık delik
		
	# Büyüme ve açılış animasyonu
	var tw := create_tween()
	if swirl:
		tw.parallel().tween_property(swirl, "scale", Vector2(target_scale, target_scale), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if core:
		tw.parallel().tween_property(core, "scale", Vector2(target_scale * 0.4, target_scale * 0.4), 0.25)
		
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("spell_cast", 0.12, 0.6)
		
	# Failsafe: Her halükarda süre + 1.2 saniye sonra nesnenin silinmesini garantiye al
	var safety_timer := get_tree().create_timer(duration + 1.2, false)
	safety_timer.timeout.connect(func():
		if is_instance_valid(self) and not is_queued_for_deletion():
			queue_free()
	)

func _physics_process(delta: float) -> void:
	if is_exploding:
		return
		
	elapsed_time += delta
	
	# Pürüzsüz görsel dönüş
	if swirl:
		swirl.rotation -= 3.2 * delta
	if core:
		core.rotation += 4.5 * delta
		
	var enemies := get_tree().get_nodes_in_group("enemies")
	
	# Gravitasyonel çekim
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			if "is_dead" in e and e.is_dead:
				continue
			var dist: float = global_position.distance_to(e.global_position)
			if dist <= vortex_radius:
				var pull_dir: Vector2 = (global_position - e.global_position).normalized()
				var pull_force: float = (1.0 - (dist / vortex_radius)) * 260.0
				if "knockback_velocity" in e:
					e.knockback_velocity += pull_dir * (pull_force * delta * 60.0)
					
	# Periyodik DoT hasarı
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		for e in enemies:
			if is_instance_valid(e) and e.has_method("take_damage"):
				if "is_dead" in e and e.is_dead:
					continue
				if global_position.distance_to(e.global_position) <= vortex_radius:
					e.take_damage(tick_damage, is_crit, global_position, "weapon_void_vortex")
					
	# Süre bittiğinde çöküş ve patlama
	if elapsed_time >= duration:
		_explode_and_cleanup()

func _explode_and_cleanup() -> void:
	if is_exploding:
		return
	is_exploding = true
	set_physics_process(false)
	
	# Çöküş patlaması: Ani yüksek alan hasarı ve savurma
	var burst_damage: float = tick_damage * 2.8
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			if "is_dead" in e and e.is_dead:
				continue
			if global_position.distance_to(e.global_position) <= vortex_radius * 1.25:
				e.take_damage(burst_damage, true, global_position, "weapon_void_vortex")
				if "knockback_velocity" in e:
					var blast_dir: Vector2 = (e.global_position - global_position).normalized()
					e.knockback_velocity += blast_dir * 220.0
					
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_sfx("potion_splash", 0.15, 0.7)
		
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)

func trigger_superconduct(player_ref: Node2D = null) -> void:
	if is_exploding:
		return
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var p = player_ref if player_ref else (tree.get_first_node_in_group("player") if tree else null)
	var mult: float = p.damage_multiplier if (p and "damage_multiplier" in p) else 1.0
	var zap_damage: float = 60.0 * mult
	
	if not swirl:
		swirl = get_node_or_null("SwirlSprite")
	if swirl:
		swirl.modulate = Color(0.3, 1.4, 2.8, 1.0) # Parlak elektrik mavisi
		var tw := create_tween()
		tw.tween_property(swirl, "modulate", Color(0.65, 0.2, 1.4, 0.85), 0.4)
		
	var audio = tree.root.get_node_or_null("AudioManager") if (tree and tree.root) else null
	if audio:
		audio.play_sfx("shoot", 0.2, 2.0)
		
	var enemies: Array = tree.get_nodes_in_group("enemies") if tree else []
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead):
			if global_position.distance_to(e.global_position) <= vortex_radius:
				if p and p.has_method("record_weapon_damage"):
					p.record_weapon_damage("rezonans_super_iletken", zap_damage)
				if e.has_method("take_damage"):
					e.take_damage(zap_damage, true, global_position, "rezonans_super_iletken")
				if e.has_method("apply_status"):
					e.apply_status("shock", 2.0)

