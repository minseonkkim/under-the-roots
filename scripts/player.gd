extends CharacterBody2D
class_name Player

@export var move_speed: float = 110.0
@export var max_hp: int = 80
@export var defense: int = 2
@export var attack_damage: int = 10
@export var attack_speed: float = 1.2
@export var attack_range: float = 120.0
@export var skill_cooldown: float = 8.0
@export var crit_rate: float = 0.05
@export var crit_damage: float = 1.5
@export var element: int = Combat.Element.NATURE

var current_hp: int
var base_attack_damage: int = 0
var thorn_factor: float = 0.0
var joystick: Node = null
var skill_button: Node = null
var rune_manager: RuneManager = null
var _skill_cd: float = 0.0
var _alive: bool = true
var _action_lock: bool = false
var _rune_particles: CPUParticles2D = null

@onready var attack_timer: Timer = $AttackTimer
@onready var anim: AnimatedSprite2D = $Sprite

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")
const ROLLING_ACORN_SCENE: PackedScene = preload("res://scenes/rolling_acorn.tscn")

signal hp_changed(new_hp: int, max_hp: int)
signal skill_cooldown_changed(remaining: float, total: float)
signal died

func _ready() -> void:
	current_hp = max_hp
	base_attack_damage = attack_damage
	add_to_group("player")
	attack_timer.wait_time = 1.0 / attack_speed
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()
	anim.animation_finished.connect(_on_anim_finished)
	hp_changed.emit(current_hp, max_hp)
	_setup_rune_particles()

func _setup_rune_particles() -> void:
	_rune_particles = CPUParticles2D.new()
	_rune_particles.emitting = false
	_rune_particles.one_shot = true
	_rune_particles.explosiveness = 0.85
	_rune_particles.amount = 20
	_rune_particles.lifetime = 0.9
	_rune_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_rune_particles.emission_sphere_radius = 6.0
	_rune_particles.direction = Vector2(0.0, -1.0)
	_rune_particles.spread = 150.0
	_rune_particles.gravity = Vector2(0.0, 60.0)
	_rune_particles.initial_velocity_min = 30.0
	_rune_particles.initial_velocity_max = 70.0
	_rune_particles.scale_amount_min = 2.0
	_rune_particles.scale_amount_max = 4.0
	_rune_particles.color = Color(0.7, 1.0, 0.35)
	add_child(_rune_particles)

func play_rune_pickup_effect() -> void:
	if _rune_particles != null:
		_rune_particles.restart()

func _on_anim_finished() -> void:
	if anim.animation in [&"attack", &"hit", &"skill"]:
		_action_lock = false

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
	if _action_lock:
		if velocity.x != 0.0:
			anim.flip_h = velocity.x < 0.0
		return
	if velocity.length() > 1.0:
		anim.play(&"walk")
		if velocity.x != 0.0:
			anim.flip_h = velocity.x < 0.0
	else:
		anim.play(&"idle")

func _on_attack_timer_timeout() -> void:
	if not _alive:
		return
	var target := _find_nearest_enemy()
	if target == null:
		return
	if global_position.distance_to(target.global_position) > attack_range:
		return
	_spawn_projectile(target)
	if anim.animation == &"hit" or anim.animation == &"skill":
		return
	_action_lock = true
	anim.play(&"attack")

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
	var crit_mult: float = Combat.roll_crit(crit_rate, crit_damage)
	p.damage = maxi(1, int(round(float(attack_damage) * crit_mult)))
	p.damage_type = Combat.DamageType.PHYSICAL
	p.attacker_element = element
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
	var crit_mult: float = Combat.roll_crit(crit_rate, crit_damage)
	acorn.damage = maxi(1, int(round(float(attack_damage) * 2.0 * crit_mult)))
	acorn.attacker_element = element
	get_tree().current_scene.add_child(acorn)
	_skill_cd = skill_cooldown
	skill_cooldown_changed.emit(_skill_cd, skill_cooldown)
	_action_lock = true
	anim.play(&"skill")

func take_damage(amount: int, dmg_type: int = Combat.DamageType.PHYSICAL) -> void:
	if not _alive:
		return
	var actual: int = Combat.calculate_damage(amount, dmg_type, defense)
	current_hp = max(current_hp - actual, 0)
	hp_changed.emit(current_hp, max_hp)

	if thorn_factor > 0.0:
		var reflect_dmg := maxi(1, int(float(actual) * thorn_factor))
		var nearest := _find_nearest_enemy()
		if nearest != null and nearest.has_method("take_damage"):
			nearest.take_damage(reflect_dmg, Combat.DamageType.TRUE)

	if current_hp == 0:
		_alive = false
		anim.play(&"death")
		await anim.animation_finished
		died.emit()
	else:
		_action_lock = true
		anim.play(&"hit")

func heal(amount: int) -> void:
	if not _alive:
		return
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)

func is_alive() -> bool:
	return _alive
