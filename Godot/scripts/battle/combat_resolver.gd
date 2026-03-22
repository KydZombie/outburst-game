extends Node
class_name CombatResolver
## Applies damage and healing. Validates targets (alive only) and clamps health to valid ranges.

func deal_damage_to_enemy(enemies: Array[Dictionary], damage: int) -> void:
	if enemies.is_empty():
		return
	if damage < 0:
		return
	var cur_hp: int = enemies[0].get("hp", 60) as int
	enemies[0]["hp"] = maxi(0, cur_hp - damage)

## Attack one party member. Only applies if target index is valid and target is alive (hp > 0).
## Damage is applied and health is clamped to 0 (no negative health).
func enemy_attack_party(party: Array[Dictionary], target_idx: int, damage: int) -> void:
	if party.is_empty():
		return
	if target_idx < 0 or target_idx >= party.size():
		return
	var cur_hp: int = party[target_idx].get("hp", 100) as int
	# Do not apply damage to dead characters; only attack living targets.
	if cur_hp <= 0:
		return
	if damage < 0:
		damage = 0
	party[target_idx]["hp"] = maxi(0, cur_hp - damage)
	var hp_after: int = party[target_idx].get("hp", 0) as int
	if hp_after <= 0:
		party[target_idx]["emotions"] = {"Angry": 0, "Sad": 0, "Happy": 0}
	elif hp_after > 0:
		var emotions: Dictionary = party[target_idx].get("emotions", {}) as Dictionary
		emotions["Sad"] = (emotions.get("Sad", 0) as int) + 1
		party[target_idx]["emotions"] = emotions

## Heal the first enemy (e.g. Jeff). Caps at max_hp. Returns actual amount healed.
func enemy_heal(enemies: Array[Dictionary], amount: int) -> int:
	if enemies.is_empty():
		return 0
	if amount <= 0:
		return 0
	var e: Dictionary = enemies[0]
	var cur_hp: int = e.get("hp", 60) as int
	var max_hp: int = e.get("max_hp", 60) as int
	if cur_hp <= 0:
		return 0
	if cur_hp >= max_hp:
		return 0
	var actual_heal: int = mini(amount, max_hp - cur_hp)
	e["hp"] = cur_hp + actual_heal
	return actual_heal
