extends CanvasLayer
class_name ResultScreen

signal retry_requested

@onready var _title: Label = $Panel/Title
@onready var _kills_label: Label = $Panel/KillsRow/Value
@onready var _time_label: Label = $Panel/TimeRow/Value
@onready var _rooms_label: Label = $Panel/RoomsRow/Value
@onready var _retry: Button = $Panel/RetryButton

func _ready() -> void:
	visible = false
	_retry.pressed.connect(_on_retry_pressed)

func show_result(victory: bool, kills: int, run_time: float, rooms_cleared: int) -> void:
	_title.text = "방 클리어!" if victory else "사망"
	_title.modulate = Color(0.6, 1.0, 0.6) if victory else Color(1.0, 0.5, 0.5)
	_kills_label.text = str(kills)
	_time_label.text = _format_time(run_time)
	_rooms_label.text = str(rooms_cleared)
	visible = true

func _format_time(t: float) -> String:
	var m: int = int(t) / 60
	var s: int = int(t) % 60
	return "%02d:%02d" % [m, s]

func _on_retry_pressed() -> void:
	retry_requested.emit()
