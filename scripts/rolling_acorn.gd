extends Area2D
class_name RollingAcorn

@export var speed: float = 180.0
@export var lifetime: float = 1.6
@export var damage: int = 20
@export var damage_type: int = 0
@export var rehit_interval: float = 0.35
@export var max_pierce: int = 5

var direction: Vector2 = Vector2.RIGHT
var attacker_element: int = Combat.Element.NONE
var _life: float = 0.0
var _hit_log: Dictionary = {}
var _hits: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func set_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	_life += delta
	if _life >= lifetime or _hits >= max_pierce:
		queue_free()
		return
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _try_hit(node: Node) -> void:
	if not node.is_in_group("enemies") or not node.has_method("take_damage"):
		return
	var id: int = node.get_instance_id()
	var now: float = _life
	if _hit_log.has(id) and now - float(_hit_log[id]) < rehit_interval:
		return
	_hit_log[id] = now
	node.take_damage(damage, damage_type, attacker_element)
	_hits += 1
