extends Area2D
class_name Portal

signal entered

var _used: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _used:
		return
	if body.is_in_group("player"):
		_used = true
		entered.emit()
