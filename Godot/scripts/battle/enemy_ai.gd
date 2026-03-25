extends Node
class_name EnemyAI
## Enemy AI: matches Core DoEnemyAi — if HP <= 20 heal MaxHealth/3, else attack random for Power*3.

func get_enemy_intent_value(enemies: Array[Dictionary]) -> int:
	if enemies.is_empty():
		return 30
	return enemies[0].get("intent_value", 30) as int

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
		result["heal_amount"] = GameSettings.get_enemy_heal_amount(max_hp)
		return result
	result["action"] = "attack"
	result["target_idx"] = choose_target_index(party)
	result["damage"] = power * 3
	return result


## Hard mode: decides which party members to hit (1 to all). Returns array of indices.
## "Best for him": killable first, then low-HP or high-threat, else spread for Sad pressure.
func decide_hard_attack_targets(party: Array[Dictionary], total_damage: int) -> Array[int]:
	var alive: Array[int] = get_alive_party_indices(party)
	if alive.is_empty():
		return []
	# 1. If someone is one-shot killable, focus on them.
	var killable: Array[int] = []
	for idx in alive:
		var hp: int = party[idx].get("hp", 100) as int
		if hp > 0 and hp <= total_damage:
			killable.append(idx)
	if killable.size() > 0:
		return [killable[randi() % killable.size()]]
	# 2. Varied patterns: ~33% focus 1, ~33% spread 3, ~33% spread all.
	var n: int = alive.size()
	var num_targets: int
	var r := randf()
	if r < 0.33:
		num_targets = 1
	elif r < 0.66:
		num_targets = mini(3, n)
	else:
		num_targets = n
	# 3. Pick targets "best for him": prioritize lowest HP (pressure kills) and high threat (Angry/Happy = damage to Jeff).
	alive.sort_custom(func(a: int, b: int) -> bool:
		var pa: Dictionary = party[a]
		var pb: Dictionary = party[b]
		var hp_a: int = pa.get("hp", 100) as int
		var hp_b: int = pb.get("hp", 100) as int
		var em_a: Dictionary = pa.get("emotions", {}) as Dictionary
		var em_b: Dictionary = pb.get("emotions", {}) as Dictionary
		var threat_a: int = (em_a.get("Angry", 0) as int) + (em_a.get("Happy", 0) as int)
		var threat_b: int = (em_b.get("Angry", 0) as int) + (em_b.get("Happy", 0) as int)
		if hp_a != hp_b:
			return hp_a < hp_b
		return threat_a > threat_b
	)
	return alive.slice(0, num_targets)
