extends Node
class_name RuneManager

# rune_id -> definition dict
var _definitions: Dictionary = {}
# rune_id -> current stack count (for this run)
var _active: Dictionary = {}

func load_from_json(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("RuneManager: cannot open %s" % path)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("RuneManager: JSON parse error in %s" % path)
		return
	for entry: Dictionary in json.data:
		_definitions[entry["id"]] = entry

func get_definition(rune_id: String) -> Dictionary:
	return _definitions.get(rune_id, {})

# Returns up to 3 rune IDs, filtering out fully-stacked ones
func draw_three(_floor_num: int = 1) -> Array[String]:
	var pool: Array[String] = []
	for id: String in _definitions:
		var def: Dictionary = _definitions[id]
		if _active.get(id, 0) < int(def.get("stack_limit", 3)):
			pool.append(id)
	pool.shuffle()
	var result: Array[String] = []
	for id: String in pool:
		if result.size() >= 3:
			break
		result.append(id)
	return result

func apply_rune(rune_id: String, player: Player) -> void:
	var def: Dictionary = _definitions.get(rune_id, {})
	if def.is_empty():
		return
	var stack: int = _active.get(rune_id, 0)
	if stack >= int(def.get("stack_limit", 3)):
		return
	_active[rune_id] = stack + 1
	_apply_effect(def, player)

func _apply_effect(def: Dictionary, player: Player) -> void:
	var effect_type: String = def.get("effect_type", "")
	var value: float = float(def.get("effect_value", 0.0))
	match effect_type:
		"atk_percent":
			player.attack_damage = maxi(1, int(round(float(player.attack_damage) * (1.0 + value))))
		"max_hp_flat":
			var added := int(value)
			player.max_hp += added
			player.current_hp = mini(player.current_hp + added, player.max_hp)
			player.hp_changed.emit(player.current_hp, player.max_hp)
		"move_speed_flat":
			player.move_speed += value
		"attack_speed_percent":
			player.attack_speed *= (1.0 + value)
			player.attack_timer.wait_time = 1.0 / player.attack_speed
		"thorn_reflect":
			pass  # read via get_thorn_factor() during take_damage

# Returns total thorn reflect fraction (e.g. 0.9 for 3 stacks of 0.3)
func get_thorn_factor() -> float:
	var total := 0.0
	for id: String in _active:
		var def: Dictionary = _definitions.get(id, {})
		if def.get("effect_type", "") == "thorn_reflect":
			total += float(def.get("effect_value", 0.0)) * float(_active[id])
	return total

func get_active() -> Dictionary:
	return _active

func reset() -> void:
	_active.clear()
