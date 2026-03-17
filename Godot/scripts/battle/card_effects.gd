extends Node
class_name CardEffects
## Resolves card effects to match Core: energy (no cap), damage, add/set/remove emotions on target.

func resolve_card_effect(
	card_data: Dictionary,
	party: Array[Dictionary],
	target_character_index: int,
	enemies: Array[Dictionary],
	energy: int,
	combat_resolver: CombatResolver
) -> Dictionary:
	var result := {"energy": energy}
	var card_id: String = card_data.get("id", "") as String
	if card_id.begins_with("gain_energy"):
		# Gain 8 energy and heal the most vulnerable (lowest HP) party member by 8.
		result["energy"] = energy + 8
		var idx := _find_lowest_hp_index(party)
		if idx != -1:
			_heal_character(party, idx, 8)
		return result
	if card_id.begins_with("basic_punch"):
		combat_resolver.deal_damage_to_enemy(enemies, 2)
		return result
	if card_id.begins_with("get_angry"):
		_add_emotion(party, target_character_index, "Angry", 2)
		return result
	if card_id.begins_with("angry_punch"):
		_remove_emotion(party, target_character_index, "Angry", 1)
		combat_resolver.deal_damage_to_enemy(enemies, 5)
		return result
	if card_id.begins_with("cheer_up"):
		if target_character_index >= 0 and target_character_index < party.size():
			var p: Dictionary = party[target_character_index]
			if (p.get("hp", 100) as int) > 0:
				var emotions: Dictionary = p.get("emotions", {}) as Dictionary
				emotions["Angry"] = 0
				emotions["Sad"] = 0
				var happy: int = emotions.get("Happy", 0) as int
				emotions["Happy"] = happy + 2
				p["emotions"] = emotions
				_heal_character(party, target_character_index, 2)
		return result
	return result

func _add_emotion(party: Array[Dictionary], index: int, emotion: String, amount: int) -> void:
	if index < 0 or index >= party.size():
		return
	var p: Dictionary = party[index]
	if p.get("hp", 1) as int <= 0:
		return
	var emotions: Dictionary = p.get("emotions", {}) as Dictionary
	var cur: int = emotions.get(emotion, 0) as int
	emotions[emotion] = cur + amount
	p["emotions"] = emotions

func _heal_character(party: Array[Dictionary], index: int, amount: int) -> void:
	if index < 0 or index >= party.size():
		return
	if amount <= 0:
		return
	var p: Dictionary = party[index]
	var hp: int = p.get("hp", 100) as int
	var max_hp: int = p.get("max_hp", 100) as int
	if max_hp <= 0:
		return
	var new_hp: int = min(max_hp, hp + amount)
	p["hp"] = new_hp

func _find_lowest_hp_index(party: Array[Dictionary]) -> int:
	var lowest_idx := -1
	var lowest_hp := 999999
	for i in range(party.size()):
		var p: Dictionary = party[i]
		var hp: int = p.get("hp", 100) as int
		if hp <= 0:
			continue
		if lowest_idx == -1 or hp < lowest_hp:
			lowest_hp = hp
			lowest_idx = i
	return lowest_idx

func _remove_emotion(party: Array[Dictionary], index: int, emotion: String, amount: int) -> void:
	if index < 0 or index >= party.size():
		return
	var p: Dictionary = party[index]
	var emotions: Dictionary = p.get("emotions", {}) as Dictionary
	var cur: int = emotions.get(emotion, 0) as int
	emotions[emotion] = maxi(0, cur - amount)
	if emotions.get(emotion, 0) as int == 0:
		emotions.erase(emotion)
	p["emotions"] = emotions

