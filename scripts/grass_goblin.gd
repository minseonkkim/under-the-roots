extends CharacterBody2D
class_name GrassGoblin

@export var move_speed: float = 55.0
@export var max_hp: int = 30
@export var defense: int = 1
@export var projectile_damage: int = 7
@export var shoot_interval: float = 2.2
@export var preferred_distance: float = 110.0

var element: int = Combat.Element.NATURE
var current_hp: int
var _shoot_cd: float = 1.0
var _active: bool = false

const ENEMY_PROJ_SCENE: PackedScene = preload("res://scenes/enemy_projectile.tscn")

signal died(enemy: Node)

func _ready() -> void:
	add_to_group("enemies")
	if not _active:
		_set_active(false)

func activate(at_position: Vector2) -> void:
	global_position = at_position
	current_hp = max_hp
	_shoot_cd = shoot_interval * randf_range(0.3, 0.9)
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
	_shoot_cd = max(_shoot_cd - delta, 0.0)
	var player := _get_player()
	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()

	if dist > preferred_distance + 20.0:
		velocity = to_player.normalized() * move_speed
	elif dist < preferred_distance - 20.0:
		velocity = -to_player.normalized() * move_speed
	else:
		velocity = to_player.normalized().rotated(PI * 0.5) * (move_speed * 0.25)

	var spr := get_node_or_null("AnimatedSprite2D")
	if spr != null and to_player.x != 0.0:
		spr.flip_h = to_player.x < 0.0

	if _shoot_cd <= 0.0:
		_shoot(player)
		_shoot_cd = shoot_interval

	move_and_slide()

func _shoot(player: Node2D) -> void:
	var proj := ENEMY_PROJ_SCENE.instantiate()
	proj.global_position = global_position
	proj.damage = projectile_damage
	proj.set_direction(player.global_position - global_position)
	get_tree().current_scene.add_child(proj)

func _get_player() -> Node2D:
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node2D and is_instance_valid(p) and p.has_method("is_alive") and p.is_alive():
			return p as Node2D
	return null

func take_damage(amount: int, dmg_type: int = Combat.DamageType.PHYSICAL, attacker_elem: int = Combat.Element.NONE) -> void:
	if not _active:
		return
	var actual: int = Combat.calculate_damage(amount, dmg_type, defense, attacker_elem, element)
	current_hp -= actual
	if current_hp <= 0:
		deactivate()
		died.emit(self)
