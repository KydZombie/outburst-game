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
		result["energy"] = energy + 8
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
			var emotions: Dictionary = p.get("emotions", {}) as Dictionary
			emotions["Angry"] = 0
			emotions["Sad"] = 0
			var happy: int = emotions.get("Happy", 0) as int
			emotions["Happy"] = happy + 2
		return result
	return result

func _add_emotion(party: Array[Dictionary], index: int, emotion: String, amount: int) -> void:
	if index < 0 or index >= party.size():
		return
	var p: Dictionary = party[index]
	var emotions: Dictionary = p.get("emotions", {}) as Dictionary
	var cur: int = emotions.get(emotion, 0) as int
	emotions[emotion] = cur + amount

func _remove_emotion(party: Array[Dictionary], index: int, emotion: String, amount: int) -> void:
	if index < 0 or index >= party.size():
		return
	var p: Dictionary = party[index]
	var emotions: Dictionary = p.get("emotions", {}) as Dictionary
	var cur: int = emotions.get(emotion, 0) as int
	emotions[emotion] = maxi(0, cur - amount)
	if emotions.get(emotion, 0) as int == 0:
		emotions.erase(emotion)

