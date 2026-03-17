extends Node
class_name EnemyAI
## Enemy AI: matches Core DoEnemyAi — if HP <= 20 heal MaxHealth/3, else attack random for Power*3.

func get_enemy_intent_value(enemies: Array[Dictionary]) -> int:
	if enemies.is_empty():
		return 12
	return enemies[0].get("intent_value", 12) as int

func get_enemy_intent_type(enemies: Array[Dictionary]) -> String:
	if enemies.is_empty():
		return "attack"
	return enemies[0].get("intent_type", "attack") as String

## Returns indices of party members with hp > 0.
func get_alive_party_indices(party: Array[Dictionary]) -> Array[int]:
	var alive: Array[int] = []
	for i in range(party.size()):
		var hp: int = party[i].get("hp", 100) as int
		if hp > 0:
			alive.append(i)
	return alive

## Picks a random living target. Returns -1 if no one is alive.
func choose_target_index(party: Array[Dictionary]) -> int:
	var alive := get_alive_party_indices(party)
	if alive.is_empty():
		return -1
	return alive[randi() % alive.size()]

## Returns true if the enemy (e.g. Jeff) is dead (hp <= 0).
func is_enemy_dead(enemies: Array[Dictionary]) -> bool:
	if enemies.is_empty():
		return true
	var hp: int = enemies[0].get("hp", 60) as int
	return hp <= 0

## Decides exactly one action for this turn (match Core DoEnemyAi).
## If HP <= 20: heal MaxHealth/3. Else: attack random character for Power*3.
## Returns { "action": "attack"|"heal"|"none", "target_idx": int, "damage": int, "heal_amount": int }
func decide_action(party: Array[Dictionary], enemies: Array[Dictionary]) -> Dictionary:
	var result := {
		"action": "none",
		"target_idx": -1,
		"damage": 0,
		"heal_amount": 0,
	}
	if is_enemy_dead(enemies):
		return result
	var alive := get_alive_party_indices(party)
	if alive.is_empty():
		return result
	var e: Dictionary = enemies[0]
	var hp: int = e.get("hp", 60) as int
	var max_hp: int = e.get("max_hp", 60) as int
	var power: int = e.get("power", 10) as int
	if hp <= 20 and max_hp > 0:
		result["action"] = "heal"
		result["heal_amount"] = max_hp / 3
		return result
	result["action"] = "attack"
	result["target_idx"] = choose_target_index(party)
	result["damage"] = power * 3
	return result
