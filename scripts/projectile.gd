extends Area2D
class_name Projectile

@export var speed: float = 200.0
@export var lifetime: float = 1.5
@export var damage: int = 10
@export var damage_type: int = 0

var direction: Vector2 = Vector2.RIGHT
var attacker_element: int = Combat.Element.NONE
var _life: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func set_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	direction = dir.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	_life += delta
	if _life >= lifetime:
		queue_free()
		return
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _try_hit(node: Node) -> void:
	if node.is_in_group("enemies") and node.has_method("take_damage"):
		node.take_damage(damage, damage_type, attacker_element)
		queue_free()
