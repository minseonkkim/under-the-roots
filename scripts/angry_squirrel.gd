extends CharacterBody2D
class_name AngrySquirrel

@export var move_speed: float = 85.0
@export var dash_speed: float = 260.0
@export var max_hp: int = 25
@export var defense: int = 1
@export var contact_damage: int = 8
@export var contact_cooldown: float = 0.5
@export var dash_interval: float = 3.0

var element: int = Combat.Element.NATURE
var current_hp: int
var _attack_cd: float = 0.0
var _dash_cd: float = 1.5
var _active: bool = false
var _dashing: bool = false
var _dash_dir: Vector2 = Vector2.ZERO
var _dash_time: float = 0.0

signal died(enemy: Node)

func _ready() -> void:
	add_to_group("enemies")
	if not _active:
		_set_active(false)

func activate(at_position: Vector2) -> void:
	global_position = at_position
	current_hp = max_hp
	_attack_cd = 0.0
	_dash_cd = dash_interval * randf_range(0.4, 1.0)
	_dashing = false
	velocity = Vector2.ZERO
	_set_active(true)

func deactivate() -> void:
	_set_active(false)

func _set_active(active: bool) -> void:
	_active = active
	visible = active
	set_physics_process(active)
	var col := get_node_or_null("CollisionShape2D")
	if col != null:
		col.set_deferred("disabled", not active)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	_attack_cd = max(_attack_cd - delta, 0.0)
	_dash_cd = max(_dash_cd - delta, 0.0)

	var player := _get_player()
	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _dashing:
		_dash_time -= delta
		velocity = _dash_dir * dash_speed
		if _dash_time <= 0.0:
			_dashing = false
	else:
		var to_player: Vector2 = player.global_position - global_position
		if to_player.length() > 1.0:
			velocity = to_player.normalized() * move_speed
			var spr := get_node_or_null("AnimatedSprite2D")
			if spr != null and to_player.x != 0.0:
				spr.flip_h = to_player.x < 0.0
		else:
			velocity = Vector2.ZERO

		if _dash_cd <= 0.0:
			_dashing = true
			_dash_dir = (player.global_position - global_position).normalized()
			_dash_time = 0.22
			_dash_cd = dash_interval

	move_and_slide()
	_check_contact_damage()

func _get_player() -> Node2D:
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node2D and is_instance_valid(p) and p.has_method("is_alive") and p.is_alive():
			return p as Node2D
	return null

func _check_contact_damage() -> void:
	if _attack_cd > 0.0:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider != null and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(contact_damage, Combat.DamageType.PHYSICAL)
			_attack_cd = contact_cooldown
			return

func take_damage(amount: int, dmg_type: int = Combat.DamageType.PHYSICAL, attacker_elem: int = Combat.Element.NONE) -> void:
	if not _active:
		return
	var actual: int = Combat.calculate_damage(amount, dmg_type, defense, attacker_elem, element)
	current_hp -= actual
	if current_hp <= 0:
		deactivate()
		died.emit(self)
