extends CanvasLayer
class_name HUD

@onready var _hp_fill: ColorRect = $TopLeft/HPBar/Fill
@onready var _hp_label: Label = $TopLeft/HPBar/Label
@onready var _kills_label: Label = $TopLeft/KillsLabel
@onready var _room_label: Label = $TopRight/RoomLabel

var _hp_bar_width: float = 120.0

func _ready() -> void:
	_hp_bar_width = ($TopLeft/HPBar as Control).size.x

func set_hp(current: int, max_hp: int) -> void:
	if _hp_fill == null:
		return
	var ratio: float = clamp(float(current) / max(float(max_hp), 1.0), 0.0, 1.0)
	_hp_fill.size = Vector2(_hp_bar_width * ratio, _hp_fill.size.y)
	_hp_label.text = "%d / %d" % [current, max_hp]

func set_kills(kills: int) -> void:
	_kills_label.text = "처치 %d" % kills

func set_room(room: int, total: int) -> void:
	_room_label.text = "방 %d/%d" % [room, total]
