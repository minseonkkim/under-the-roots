extends Node2D
class_name SpawnManager

@export var enemy_scene: PackedScene
@export var pool_size: int = 16
@export var spawn_interval: float = 1.4
@export var spawn_radius: float = 220.0
@export var max_alive: int = 6
@export var room_quota: int = 12

var _pool: Array[Node] = []
var _player: Node2D = null
var _kills: int = 0
var _spawned_in_room: int = 0
var _spawn_timer: Timer
var _running: bool = false

signal enemy_killed(total_kills: int)
signal room_cleared

func _ready() -> void:
	if enemy_scene == null:
		enemy_scene = load("res://scenes/acorn_bug.tscn")
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_tick)
	add_child(_spawn_timer)
	_build_pool()

func _build_pool() -> void:
	for i in pool_size:
		var e: Node = enemy_scene.instantiate()
		add_child(e)
		if e.has_method("deactivate"):
			e.deactivate()
		if e.has_signal("died"):
			e.died.connect(_on_enemy_died)
		_pool.append(e)

func start_room(player: Node2D) -> void:
	_player = player
	_kills = 0
	_spawned_in_room = 0
	_running = true
	_spawn_initial_burst(4)
	_spawn_timer.start()

func stop() -> void:
	_running = false
	_spawn_timer.stop()
	for e in _pool:
		if e.has_method("deactivate"):
			e.deactivate()

func _spawn_initial_burst(count: int) -> void:
	for i in count:
		var angle: float = (TAU / count) * i
		_spawn_at_angle(angle)

func _on_spawn_tick() -> void:
	if not _running or _player == null or not is_instance_valid(_player):
		return
	if _spawned_in_room >= room_quota:
		return
	if _alive_count() >= max_alive:
		return
	_spawn_at_angle(randf() * TAU)

func _spawn_at_angle(angle: float) -> void:
	if _spawned_in_room >= room_quota:
		return
	var enemy := _get_inactive()
	if enemy == null:
		return
	var pos: Vector2 = _player.global_position + Vector2.RIGHT.rotated(angle) * spawn_radius
	enemy.activate(pos)
	_spawned_in_room += 1

func _get_inactive() -> Node:
	for e in _pool:
		if not e.visible:
			return e
	return null

func _alive_count() -> int:
	var n := 0
	for e in _pool:
		if e.visible:
			n += 1
	return n

func _on_enemy_died(_enemy: Node) -> void:
	_kills += 1
	enemy_killed.emit(_kills)
	if _running and _spawned_in_room >= room_quota and _alive_count() == 0:
		_running = false
		_spawn_timer.stop()
		room_cleared.emit()

func get_kills() -> int:
	return _kills
