class_name Combat
extends RefCounted

enum DamageType { PHYSICAL, MAGIC, TRUE }
enum Element { NONE, NATURE, FIRE, WATER, EARTH }

# [attacker_element][defender_element] = damage multiplier
# 기획서 기준: 자연>대지, 불>자연, 물>불 / 자연<불, 불<물, 물<자연 / 대지 중립
const ELEMENT_TABLE: Array = [
	[1.0, 1.0, 1.0, 1.0, 1.0],  # NONE
	[1.0, 1.0, 0.8, 1.0, 1.3],  # NATURE: 강함↑대지(1.3), 약함↓불(0.8)
	[1.0, 1.3, 1.0, 0.8, 1.0],  # FIRE:   강함↑자연(1.3), 약함↓물(0.8)
	[1.0, 0.8, 1.3, 1.0, 1.0],  # WATER:  강함↑불(1.3),   약함↓자연(0.8)
	[1.0, 1.0, 1.0, 1.0, 1.0],  # EARTH:  중립
]

static func get_element_mult(attacker_elem: int, defender_elem: int) -> float:
	if attacker_elem < 0 or attacker_elem >= ELEMENT_TABLE.size():
		return 1.0
	var row: Array = ELEMENT_TABLE[attacker_elem]
	if defender_elem < 0 or defender_elem >= row.size():
		return 1.0
	return float(row[defender_elem])

static func roll_crit(crit_rate: float, crit_damage: float) -> float:
	if randf() < crit_rate:
		return crit_damage
	return 1.0

static func calculate_damage(raw: int, dmg_type: int, defense: int,
		attacker_elem: int = 0, defender_elem: int = 0) -> int:
	var elem_mult: float = get_element_mult(attacker_elem, defender_elem)
	if dmg_type == DamageType.TRUE:
		return max(1, int(round(float(raw) * elem_mult)))
	var reduced: float = float(raw) * elem_mult - float(defense)
	return max(1, int(round(reduced)))
