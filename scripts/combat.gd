class_name Combat
extends RefCounted

enum DamageType { PHYSICAL, MAGIC, TRUE }

static func calculate_damage(raw: int, dmg_type: int, defense: int, type_mult: float = 1.0) -> int:
	if dmg_type == DamageType.TRUE:
		return max(1, int(round(raw * type_mult)))
	var reduced: float = float(raw) * type_mult - float(defense)
	return max(1, int(round(reduced)))
