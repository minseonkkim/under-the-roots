extends CharacterBody2D
class_name AcornKing

@export var max_hp: int = 300
@export var defense: int = 5
@export var move_speed: float = 60.0
@export var acorn_damage: int = 12
@export var contact_damage: int = 15
@export var contact_cooldown: float = 1.0

var current_hp: int
var _phase: int = 1
var _active: bool = true

var _contact_cd: float = 0.0
var _shoot_cd: float = 3.0
var _charge_cd: float = 5.0
var _summon_cd: float = 8.0
var _spike_cd: float = 6.0

var _charging: bool = false
var _charge_dir: Vector2 = Vector2.ZERO
var _charge_time: float = 0.0

signal died(boss: Node)
signal hp_changed(current_hp: int, max_hp: int)

const ENEMY_PROJ_SCENE: PackedScene = preload("res://scenes/acorn_king_projectile.tscn")
const ACORN_BUG_SCENE: PackedScene = preload("res://scenes/acorn_bug.tscn")
const SPIKE_ZONE_SCENE: PackedScene = preload("res://scenes/spike_zone.tscn")

const PHASE_FRAMES: Array = [
	preload("res://resources/sprite_frames/acron_king_phase1.tres"),
	preload("res://resources/sprite_frames/acron_king_phase2.tres"),
	preload("res://resources/sprite_frames/acron_king_phase3.tres"),
]

func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	_contact_cd = max(_contact_cd - delta, 0.0)
	var player := _get_player()
	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_update_ai(delta, player)
	move_and_slide()
	_check_contact_damage()

func _update_ai(delta: float, player: Node2D) -> void:
	match _phase:
		1: _ai_phase1(delta, player)
		2: _ai_phase2(delta, player)
		3: _ai_phase3(delta, player)

func _ai_phase1(delta: float, player: Node2D) -> void:
	_shoot_cd -= delta
	_charge_cd -= delta

	if _charging:
		_charge_time -= delta
		velocity = _charge_dir * 210.0
		if _charge_time <= 0.0:
			_charging = false
		return

	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > 80.0:
		velocity = to_player.normalized() * move_speed
		_play_anim("walk")
	else:
		velocity = to_player.normalized().rotated(PI * 0.45) * move_speed
		_play_anim("idle")
	_flip_to(to_player)

	if _shoot_cd <= 0.0:
		_shoot_burst(player, 3, 0.35)
		_shoot_cd = 3.5

	if _charge_cd <= 0.0:
		_start_charge(player, 0.4, 5.0)

func _ai_phase2(delta: float, player: Node2D) -> void:
	_shoot_cd -= delta
	_charge_cd -= delta
	_summon_cd -= delta

	if _charging:
		_charge_time -= delta
		velocity = _charge_dir * 230.0
		if _charge_time <= 0.0:
			_charging = false
		return

	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > 50.0:
		velocity = to_player.normalized() * (move_speed * 1.25)
		_play_anim("walk")
	else:
		velocity = Vector2.ZERO
		_play_anim("idle")
	_flip_to(to_player)

	if _shoot_cd <= 0.0:
		_shoot_barrage(8)
		_shoot_cd = 4.0

	if _charge_cd <= 0.0:
		_start_charge(player, 0.35, 4.0)

	if _summon_cd <= 0.0:
		_summon_minions(3)
		_summon_cd = 12.0

func _ai_phase3(delta: float, player: Node2D) -> void:
	_shoot_cd -= delta
	_charge_cd -= delta
	_spike_cd -= delta

	if _charging:
		_charge_time -= delta
		velocity = _charge_dir * 290.0
		if _charge_time <= 0.0:
			_charging = false
		return

	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > 30.0:
		velocity = to_player.normalized() * move_speed
		_play_anim("walk")
	else:
		velocity = Vector2.ZERO
		_play_anim("idle")
	_flip_to(to_player)

	if _shoot_cd <= 0.0:
		_shoot_burst(player, 5, 0.6)
		_shoot_cd = 2.2

	if _charge_cd <= 0.0:
		_start_charge(player, 0.35, 3.0)

	if _spike_cd <= 0.0:
		_spawn_spike_zones(player.global_position)
		_spike_cd = 5.0

func _start_charge(player: Node2D, duration: float, cooldown: float) -> void:
	_charging = true
	_charge_dir = (player.global_position - global_position).normalized()
	_charge_time = duration
	_charge_cd = cooldown

func _shoot_burst(player: Node2D, count: int, spread_rad: float) -> void:
	var base_dir: Vector2 = (player.global_position - global_position).normalized()
	var half := spread_rad * 0.5
	var step: float = spread_rad / max(count - 1, 1)
	for i in count:
		_spawn_proj(base_dir.rotated(-half + step * i))

func _shoot_barrage(count: int) -> void:
	for i in count:
		_spawn_proj(Vector2.RIGHT.rotated(TAU * i / count))

func _spawn_proj(dir: Vector2) -> void:
	var proj := ENEMY_PROJ_SCENE.instantiate()
	proj.global_position = global_position
	proj.damage = acorn_damage
	proj.set_direction(dir)
	get_tree().current_scene.add_child(proj)

func _summon_minions(count: int) -> void:
	for i in count:
		var bug := ACORN_BUG_SCENE.instantiate()
		var angle: float = TAU * i / count
		get_tree().current_scene.add_child(bug)
		bug.activate(global_position + Vector2.RIGHT.rotated(angle) * 80.0)

func _spawn_spike_zones(near: Vector2) -> void:
	for i in 3:
		var zone := SPIKE_ZONE_SCENE.instantiate()
		var offset := Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, 100.0))
		zone.global_position = near + offset
		get_tree().current_scene.add_child(zone)

func _play_anim(anim: String) -> void:
	var spr := get_node_or_null("AnimatedSprite2D")
	if spr != null and spr.animation != anim:
		spr.play(anim)

func _flip_to(dir: Vector2) -> void:
	if dir.x == 0.0:
		return
	var spr := get_node_or_null("AnimatedSprite2D")
	if spr != null:
		spr.flip_h = dir.x < 0.0

func _check_contact_damage() -> void:
	if _contact_cd > 0.0:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider != null and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(contact_damage, Combat.DamageType.PHYSICAL)
			_contact_cd = contact_cooldown
			return

func _get_player() -> Node2D:
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node2D and is_instance_valid(p) and p.has_method("is_alive") and p.is_alive():
			return p as Node2D
	return null

func take_damage(amount: int, dmg_type: int = Combat.DamageType.PHYSICAL) -> void:
	if not _active:
		return
	var actual: int = Combat.calculate_damage(amount, dmg_type, defense)
	current_hp = max(current_hp - actual, 0)
	hp_changed.emit(current_hp, max_hp)
	_play_anim("hit")
	_check_phase_change()
	if current_hp <= 0:
		_die()

func _check_phase_change() -> void:
	var new_phase: int = 1
	if current_hp <= int(max_hp * 0.3):
		new_phase = 3
	elif current_hp <= int(max_hp * 0.7):
		new_phase = 2

	if new_phase > _phase:
		_apply_phase(new_phase)
		_phase = new_phase

func _apply_phase(new_phase: int) -> void:
	var spr := get_node_or_null("AnimatedSprite2D")
	match new_phase:
		2:
			_shoot_cd = minf(_shoot_cd, 1.0)
			_summon_cd = minf(_summon_cd, 2.0)
			if spr != null:
				spr.sprite_frames = PHASE_FRAMES[1]
				spr.play("idle")
		3:
			move_speed = move_speed * 1.5
			acorn_damage = int(acorn_damage * 1.5)
			contact_damage = int(contact_damage * 1.5)
			_shoot_cd = minf(_shoot_cd, 0.8)
			_spike_cd = minf(_spike_cd, 1.0)
			if spr != null:
				spr.sprite_frames = PHASE_FRAMES[2]
				spr.play("idle")

func _die() -> void:
	_active = false
	set_physics_process(false)
	var spr := get_node_or_null("AnimatedSprite2D")
	if spr != null:
		spr.play("death")
		await spr.animation_finished
	visible = false
	died.emit(self)
