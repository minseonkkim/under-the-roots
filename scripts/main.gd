extends Node2D

@export var enemy_scene: PackedScene
@export var portal_offset: Vector2 = Vector2(0, -120)

const PORTAL_SCENE: PackedScene = preload("res://scenes/portal.tscn")

@onready var player: Player = $Player
@onready var background: Polygon2D = $Background
@onready var joystick: Node = $UI/VirtualJoystick
@onready var skill_button: Node = $UI/SkillButton
@onready var hud: HUD = $HUD
@onready var result_screen: ResultScreen = $ResultScreen
@onready var spawner: SpawnManager = $SpawnManager

var _run_time: float = 0.0
var _rooms_cleared: int = 0
var _current_room: int = 1
var _portal: Portal = null
var _running: bool = false
var _rune_manager: RuneManager = null

func _ready() -> void:
	if enemy_scene != null:
		spawner.enemy_scene = enemy_scene

	_rune_manager = RuneManager.new()
	add_child(_rune_manager)
	_rune_manager.load_from_json("res://data/runes.json")

	player.joystick = joystick
	player.rune_manager = _rune_manager
	player.hp_changed.connect(_on_player_hp_changed)
	player.died.connect(_on_player_died)
	player.skill_cooldown_changed.connect(_on_skill_cd_changed)

	if skill_button.has_signal("pressed_skill"):
		skill_button.pressed_skill.connect(player.use_skill)

	spawner.enemy_killed.connect(_on_enemy_killed)
	spawner.room_cleared.connect(_on_room_cleared)

	result_screen.retry_requested.connect(_on_retry)

	hud.set_hp(player.current_hp, player.max_hp)
	hud.set_kills(0)
	hud.set_room(_current_room, _current_room)

	_start_room()

func _process(delta: float) -> void:
	if _running:
		_run_time += delta
	background.position = player.global_position

func _start_room() -> void:
	_running = true
	if _portal != null and is_instance_valid(_portal):
		_portal.queue_free()
		_portal = null
	spawner.start_room(player)
	hud.set_room(_current_room, _current_room)

func _on_enemy_killed(total: int) -> void:
	hud.set_kills(total)

func _on_room_cleared() -> void:
	_rooms_cleared += 1
	_show_rune_pick()

func _show_rune_pick() -> void:
	var picks := _rune_manager.draw_three(_current_room)
	var ui := RunePickUI.new()
	ui.setup(_rune_manager, picks)
	add_child(ui)
	ui.rune_chosen.connect(_on_rune_chosen)

func _on_rune_chosen(rune_id: String) -> void:
	_rune_manager.apply_rune(rune_id, player)
	player.play_rune_pickup_effect()
	_spawn_portal()

func _spawn_portal() -> void:
	_portal = PORTAL_SCENE.instantiate()
	_portal.global_position = player.global_position + portal_offset
	_portal.entered.connect(_on_portal_entered)
	add_child(_portal)

func _on_portal_entered() -> void:
	_current_room += 1
	_start_room()

func _on_player_hp_changed(current: int, max_hp: int) -> void:
	hud.set_hp(current, max_hp)

func _on_player_died() -> void:
	_running = false
	spawner.stop()
	result_screen.show_result(false, spawner.get_kills(), _run_time, _rooms_cleared)

func _on_skill_cd_changed(remaining: float, total: float) -> void:
	if skill_button.has_method("set_cooldown"):
		skill_button.set_cooldown(remaining, total)

func _on_retry() -> void:
	_rune_manager.reset()
	get_tree().reload_current_scene()
