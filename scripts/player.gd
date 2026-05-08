extends CharacterBody2D
class_name Player

@export var move_speed: float = 110.0
@export var max_hp: int = 80
@export var defense: int = 2
@export var attack_damage: int = 10
@export var attack_speed: float = 1.2
@export var attack_range: float = 120.0
@export var skill_cooldown: float = 8.0

var current_hp: int
var joystick: Node = null
var skill_button: Node = null
var _skill_cd: float = 0.0
var _alive: bool = true

@onready var attack_timer: Timer = $AttackTimer

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")
const ROLLING_ACORN_SCENE: PackedScene = preload("res://scenes/rolling_acorn.tscn")

signal hp_changed(new_hp: int, max_hp: int)
signal skill_cooldown_changed(remaining: float, total: float)
signal died

func _ready() -> void:
	current_hp = max_hp
	add_to_group("player")
	attack_timer.wait_time = 1.0 / attack_speed
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()
	hp_changed.emit(current_hp, max_hp)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if _skill_cd > 0.0:
		_skill_cd = max(_skill_cd - delta, 0.0)
		skill_cooldown_changed.emit(_skill_cd, skill_cooldown)
	var dir := Vector2.ZERO
	if joystick != null and joystick.has_method("get_direction"):
		dir = joystick.get_direction()
	if dir == Vector2.ZERO:
		dir.x = Input.get_axis("ui_left", "ui_right")
		dir.y = Input.get_axis("ui_up", "ui_down")
		if dir.length() > 1.0:
			dir = dir.normalized()
	velocity = dir * move_speed
	move_and_slide()

func _on_attack_timer_timeout() -> void:
	if not _alive:
		return
	var target := _find_nearest_enemy()
	if target == null:
		return
	if global_position.distance_to(target.global_position) > attack_range:
		return
	_spawn_projectile(target)

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := INF
	for e in enemies:
		if not (e is Node2D) or not is_instance_valid(e):
			continue
		var n2d := e as Node2D
		if not n2d.visible:
			continue
		var d: float = global_position.distance_squared_to(n2d.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = n2d
	return nearest

func _spawn_projectile(target: Node2D) -> void:
	var p := PROJECTILE_SCENE.instantiate()
	p.global_position = global_position
	var dir: Vector2 = (target.global_position - global_position).normalized()
	p.set_direction(dir)
	p.damage = attack_damage
	p.damage_type = Combat.DamageType.PHYSICAL
	get_tree().current_scene.add_child(p)

func use_skill() -> void:
	if not _alive or _skill_cd > 0.0:
		return
	var dir := Vector2.RIGHT
	if joystick != null and joystick.has_method("get_direction"):
		var jd: Vector2 = joystick.get_direction()
		if jd != Vector2.ZERO:
			dir = jd.normalized()
		else:
			var nearest := _find_nearest_enemy()
			if nearest != null:
				dir = (nearest.global_position - global_position).normalized()
	var acorn := ROLLING_ACORN_SCENE.instantiate()
	acorn.global_position = global_position
	acorn.set_direction(dir)
	acorn.damage = attack_damage * 2
	get_tree().current_scene.add_child(acorn)
	_skill_cd = skill_cooldown
	skill_cooldown_changed.emit(_skill_cd, skill_cooldown)

func take_damage(amount: int, dmg_type: int = Combat.DamageType.PHYSICAL) -> void:
	if not _alive:
		return
	var actual: int = Combat.calculate_damage(amount, dmg_type, defense)
	current_hp = max(current_hp - actual, 0)
	hp_changed.emit(current_hp, max_hp)
	if current_hp == 0:
		_alive = false
		died.emit()

func is_alive() -> bool:
	return _alive
