extends Area2D

@export var xp_amount: int = 15
@export var magnet_speed: float = 450.0

@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D = null
var is_attracted: bool = false
var velocity: Vector2 = Vector2.ZERO
var merge_timer: float = 0.0
var tier: int = 1

func _ready() -> void:
	add_to_group("xp_gems")
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	_update_tier_visuals()
	
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func setup(amount: int) -> void:
	xp_amount = amount
	_update_tier_visuals()

func _update_tier_visuals() -> void:
	if not sprite:
		return
		
	# Aşama ve renk skalası
	if xp_amount < 25:
		tier = 1
		sprite.modulate = Color(0.3, 0.65, 1.0, 1.0) # Açık Mavi Mürekkep
		sprite.scale = Vector2(0.65, 0.65)
	elif xp_amount < 80:
		tier = 2
		sprite.modulate = Color(0.2, 0.9, 0.4, 1.0) # Parlak Zümrüt Yeşili
		sprite.scale = Vector2(0.78, 0.78)
	elif xp_amount < 250:
		tier = 3
		sprite.modulate = Color(0.95, 0.3, 0.2, 1.0) # Kırmızı Çini Mürekkebi
		sprite.scale = Vector2(0.92, 0.92)
	elif xp_amount < 800:
		tier = 4
		sprite.modulate = Color(0.95, 0.8, 0.1, 1.0) # Parlak Altın Sarısı
		sprite.scale = Vector2(1.10, 1.10)
	else:
		tier = 5
		sprite.modulate = Color(0.85, 0.2, 0.95, 1.0) # Destansı Mor Mühür
		sprite.scale = Vector2(1.30, 1.30)

func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	var dist := global_position.distance_to(player.global_position)
	
	# Mıknatıs çekim menzili
	var reach: float = 180.0
	if player and "magnet_range_mult" in player:
		reach *= player.magnet_range_mult
	if dist < reach:
		is_attracted = true
		
	if is_attracted:
		var dir := (player.global_position - global_position).normalized()
		velocity = velocity.move_toward(dir * magnet_speed, 1600.0 * delta)
		global_position += velocity * delta
		
		# Mesafe çok yaklaştığında doğrudan topla
		if dist < 24.0:
			_collect(player)
	else:
		# Çekilmiyorken periyodik olarak yakınındaki XP'lerle birleşme kontrolü yap
		merge_timer += delta
		if merge_timer >= 1.2:
			merge_timer = randf_range(0.0, 0.4)
			_check_merge_nearby()

func _check_merge_nearby() -> void:
	# Eğer bu kristal zaten çekiliyorsa birleşmesin
	if is_attracted:
		return
		
	var gems := get_tree().get_nodes_in_group("xp_gems")
	var nearby: Array[Node2D] = []
	for g in gems:
		if g != self and is_instance_valid(g) and not g.is_attracted:
			if global_position.distance_squared_to(g.global_position) < (60.0 * 60.0):
				nearby.append(g)
				
	# 3 veya daha fazla kristal dip dibeyse birleşip değerlerini bu kristale aktarsınlar
	if nearby.size() >= 2:
		for other in nearby:
			if is_instance_valid(other) and other.has_method("absorb_into"):
				xp_amount += other.absorb_into()
		_update_tier_visuals()
		# Birleşme nabız efekti
		var tw := create_tween()
		tw.tween_property(sprite, "scale", sprite.scale * 1.35, 0.12)
		tw.tween_property(sprite, "scale", sprite.scale, 0.12)

func absorb_into() -> int:
	var amt := xp_amount
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()
	return amt

func _on_body_entered(body: Node2D) -> void:
	_collect(body)

func _on_area_entered(area: Area2D) -> void:
	_collect(area.get_parent())

func _collect(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	var p: Node2D = target if target.is_in_group("player") else get_tree().get_first_node_in_group("player")
	if p and p.has_method("add_xp"):
		p.add_xp(xp_amount)
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_sfx("xp", 0.15)
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		queue_free()
