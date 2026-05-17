extends Node2D
class_name SpawnManager

@export var enemy_scene: PackedScene
@export var pool_size: int = 20
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
var _recent_angles: Array[float] = []

signal enemy_killed(total_kills: int)
signal room_cleared

func _ready() -> void:
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_tick)
	add_child(_spawn_timer)
	if enemy_scene != null:
		_build_single_pool(enemy_scene, pool_size)

# 다중 적 타입으로 풀 재구성
func configure_enemies(scenes: Array, quota: int) -> void:
	stop()
	_clear_pool()
	room_quota = quota
	if scenes.is_empty():
		return
	var per_type: int = pool_size / scenes.size()
	for scene in scenes:
		_build_single_pool(scene, per_type)
	_pool.shuffle()

func _clear_pool() -> void:
	for e in _pool:
		if is_instance_valid(e):
			e.queue_free()
	_pool.clear()

func _build_single_pool(scene: PackedScene, count: int) -> void:
	for i in count:
		var e: Node = scene.instantiate()
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
	_recent_angles.clear()
	_spawn_initial_burst(4)
	_spawn_timer.start()

func stop() -> void:
	_running = false
	_spawn_timer.stop()
	for e in _pool:
		if is_instance_valid(e) and e.has_method("deactivate"):
			e.deactivate()

func _spawn_initial_burst(count: int) -> void:
	var offset: float = randf() * TAU
	for i in count:
		var angle: float = offset + (TAU / count) * i
		_spawn_at_angle(angle)

func _on_spawn_tick() -> void:
	if not _running or _player == null or not is_instance_valid(_player):
		return
	if _spawned_in_room >= room_quota:
		return
	if _alive_count() >= max_alive:
		return
	_spawn_at_angle(_pick_spread_angle())

func _pick_spread_angle() -> float:
	const MIN_SPREAD: float = PI / 3.0  # 60도 이내 연속 스폰 방지
	for _attempt in 8:
		var angle: float = randf() * TAU
		var ok := true
		for prev in _recent_angles:
			if absf(wrapf(angle - prev, -PI, PI)) < MIN_SPREAD:
				ok = false
				break
		if ok:
			_recent_angles.append(angle)
			if _recent_angles.size() > 4:
				_recent_angles.pop_front()
			return angle
	return randf() * TAU

func _spawn_at_angle(angle: float) -> void:
	if _spawned_in_room >= room_quota:
		return
	var enemy := _get_inactive()
	if enemy == null:
		return
	var pos: Vector2 = _player.global_position + Vector2.RIGHT.rotated(angle) * spawn_radius
	if enemy.has_method("activate"):
		enemy.activate(pos)
	_spawned_in_room += 1

func _get_inactive() -> Node:
	for e in _pool:
		if is_instance_valid(e) and not e.visible:
			return e
	return null

func _alive_count() -> int:
	var n := 0
	for e in _pool:
		if is_instance_valid(e) and e.visible:
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
