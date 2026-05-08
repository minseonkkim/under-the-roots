extends Control
class_name SkillButton

signal pressed_skill

@export var ready_color: Color = Color(0.95, 0.75, 0.25, 0.85)
@export var cooldown_color: Color = Color(0.3, 0.3, 0.35, 0.7)

var _total_cd: float = 0.0
var _remaining: float = 0.0
var _holding_id: int = -1

@onready var _bg: Panel = $Background
@onready var _fill: ColorRect = $Background/CooldownFill
@onready var _label: Label = $Background/Label

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	_update_visual()

func set_cooldown(remaining: float, total: float) -> void:
	_remaining = remaining
	_total_cd = max(total, 0.0001)
	_update_visual()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _holding_id == -1:
			_holding_id = t.index
			_try_press()
		elif not t.pressed and t.index == _holding_id:
			_holding_id = -1
	elif event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_LEFT and m.pressed:
			_try_press()

func _try_press() -> void:
	if _remaining <= 0.0:
		pressed_skill.emit()

func _update_visual() -> void:
	if _bg == null:
		return
	if _remaining <= 0.0:
		_bg.modulate = ready_color
		_fill.size = Vector2(_bg.size.x, 0)
		_label.text = "SKILL"
	else:
		_bg.modulate = cooldown_color
		var ratio: float = clamp(_remaining / _total_cd, 0.0, 1.0)
		_fill.size = Vector2(_bg.size.x, _bg.size.y * ratio)
		_fill.position = Vector2(0, _bg.size.y - _fill.size.y)
		_label.text = "%.1f" % _remaining
