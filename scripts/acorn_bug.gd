extends CharacterBody2D
class_name AcornBug

@export var move_speed: float = 50.0
@export var max_hp: int = 20
@export var defense: int = 1
@export var contact_damage: int = 5
@export var contact_cooldown: float = 0.6

var element: int = Combat.Element.NATURE
var current_hp: int
var _attack_cd: float = 0.0
var _active: bool = false

signal died(enemy: Node)

func _ready() -> void:
	add_to_group("enemies")
	if not _active:
		_set_active(false)

func activate(at_position: Vector2) -> void:
	global_position = at_position
	current_hp = max_hp
	_attack_cd = 0.0
	velocity = Vector2.ZERO
	_set_active(true)

func deactivate() -> void:
	_set_active(false)

func _set_active(active: bool) -> void:
	_active = active
	visible = active
	set_physics_process(active)
	set_process(active)
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if col != null:
		col.set_deferred("disabled", not active)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	_attack_cd = max(_attack_cd - delta, 0.0)
	var player := _get_player()
	if player == null:
		velocity = Vector2.ZERO
	else:
		var to_player: Vector2 = player.global_position - global_position
		if to_player.length() > 1.0:
			velocity = to_player.normalized() * move_speed
			$AnimatedSprite2D.flip_h = to_player.x < 0
		else:
			velocity = Vector2.ZERO
	move_and_slide()
	_check_contact_damage()

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
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
