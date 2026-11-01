extends Node2D

@export var weapon_id: String = "weapon_spellbook"
@export var current_level: int = 1

@export var damage: float = 24.0
@export var orbit_speed: float = 3.5
@export var orbit_radius: float = 120.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var hitbox: Area2D = $Hitbox
@onready var sprite: Sprite2D = $Sprite2D

var angle: float = 0.0
var damage_cooldowns: Dictionary = {}
var base_damage: float = 24.0
var base_orbit_speed: float = 3.5
var base_orbit_radius: float = 120.0

# Çoklu kitap desteği (Extra Projectiles)
var book_nodes: Array[Dictionary] = [] # Array of {"sprite": Sprite2D, "hitbox": Area2D}

func _ready() -> void:
	base_damage = damage
	base_orbit_speed = orbit_speed
	base_orbit_radius = orbit_radius
	if not player:
		player = get_tree().get_first_node_in_group("player")
	
	if hitbox:
		hitbox.collision_layer = 0
		hitbox.collision_mask = 1
		hitbox.body_entered.connect(_on_body_hit)
		book_nodes.append({"sprite": sprite, "hitbox": hitbox})

func upgrade_level(new_lvl: int) -> void:
	current_level = new_lvl
	damage = base_damage * (1.0 + (current_level - 1) * 0.35)
	orbit_speed = base_orbit_speed * (1.0 + (current_level - 1) * 0.15)
	orbit_radius = base_orbit_radius * (1.0 + (current_level - 1) * 0.08)
	if current_level >= 7:
		damage *= 1.40
		orbit_speed *= 1.30 # 7. seviyede süpersonik girdap
	
	for b in book_nodes:
		var spr: Sprite2D = b.get("sprite")
		if spr:
			var tw := create_tween()
			tw.tween_property(spr, "scale", spr.scale * 1.35, 0.15)
			tw.tween_property(spr, "scale", spr.scale, 0.15)

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	# Oyuncu merkezine kilitlen
	global_position = player.global_position + Vector2(0, -30)
	
	# Ekstra kitap sayısını güncelle
	var extra_proj: int = player.extra_projectiles if "extra_projectiles" in player else 0
	var desired_count: int = 1 + extra_proj
	_sync_book_count(desired_count)
	
	var area_scale: float = 1.0
	if "area_mult" in player:
		area_scale = player.area_mult
		
	angle += orbit_speed * delta
	var current_radius := orbit_radius * area_scale
	var total_books: int = book_nodes.size()
	
	for i in range(total_books):
		var b_angle: float = angle + (TAU / float(total_books)) * float(i)
		var b_pos := Vector2(cos(b_angle), sin(b_angle)) * current_radius
		var b_dict: Dictionary = book_nodes[i]
		var b_spr: Sprite2D = b_dict["sprite"]
		var b_hit: Area2D = b_dict["hitbox"]
		
		if b_spr:
			b_spr.position = b_pos
			b_spr.rotation = b_angle + PI * 0.5
			b_spr.scale = Vector2(0.22, 0.22) * area_scale
		if b_hit:
			b_hit.position = b_pos
			
	# Hasar bekleme sürelerini azalt
	for id in damage_cooldowns.keys():
		damage_cooldowns[id] -= delta
		if damage_cooldowns[id] <= 0:
			damage_cooldowns.erase(id)
			
	# Sürekli temas eden düşmanlara hasar ver
	for b_dict in book_nodes:
		var b_hit: Area2D = b_dict["hitbox"]
		if is_instance_valid(b_hit):
			for body in b_hit.get_overlapping_bodies():
				_damage_target_if_ready(body)

func _sync_book_count(desired: int) -> void:
	while book_nodes.size() < desired:
		var new_spr := Sprite2D.new()
		new_spr.texture = sprite.texture
		new_spr.scale = sprite.scale
		add_child(new_spr)
		
		var new_hitbox := Area2D.new()
		new_hitbox.collision_layer = 0
		new_hitbox.collision_mask = 1
		var col := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 24.0
		col.shape = circle
		new_hitbox.add_child(col)
		new_hitbox.body_entered.connect(_on_body_hit)
		add_child(new_hitbox)
		
		book_nodes.append({"sprite": new_spr, "hitbox": new_hitbox})
		
	while book_nodes.size() > desired and book_nodes.size() > 1:
		var last: Dictionary = book_nodes.pop_back()
		if is_instance_valid(last["sprite"]):
			last["sprite"].queue_free()
		if is_instance_valid(last["hitbox"]):
			last["hitbox"].queue_free()

func _on_body_hit(body: Node2D) -> void:
	_damage_target_if_ready(body)

func _damage_target_if_ready(body: Node2D) -> void:
	if not body or not is_instance_valid(body) or not body.has_method("take_damage"):
		return
	if "is_dead" in body and body.is_dead:
		return
	var id := body.get_instance_id()
	if not damage_cooldowns.has(id):
		var dmg_mult: float = player.damage_multiplier if player and "damage_multiplier" in player else 1.0
		var crit_prob: float = player.crit_chance if player and "crit_chance" in player else 0.05
		var is_crit: bool = randf() < crit_prob
		var final_dmg: float = damage * dmg_mult * (2.0 if is_crit else 1.0)
		
		damage_cooldowns[id] = 0.35
		body.take_damage(final_dmg, is_crit, global_position, "weapon_spellbook")
