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
		# Core: GainEnergyEffect(8) only — no heal.
		result["energy"] = energy + 8
		return result
	if card_id.begins_with("basic_punch"):
		var dmg := 2 + _emotion_damage_modifier(party, target_character_index)
		combat_resolver.deal_damage_to_enemy(enemies, maxi(0, dmg))
		return result
	if card_id.begins_with("get_angry"):
		_add_emotion(party, target_character_index, "Angry", 2)
		return result
	if card_id.begins_with("angry_punch"):
		var dmg := 5 + _emotion_damage_modifier(party, target_character_index)
		_remove_emotion(party, target_character_index, "Angry", 1)
		combat_resolver.deal_damage_to_enemy(enemies, maxi(0, dmg))
		return result
	if card_id.begins_with("cheer_up"):
		# Core: SetEmotion(Angry,0), SetEmotion(Sad,0), AddEmotion(Happy,2) on target — no heal.
		if target_character_index >= 0 and target_character_index < party.size():
			var p: Dictionary = party[target_character_index]
			if (p.get("hp", 100) as int) > 0:
				var emotions: Dictionary = (p.get("emotions", {}) as Dictionary).duplicate()
				# Core: SetEmotion(Angry,0) / SetEmotion(Sad,0) removes the emotion entry.
				emotions.erase("Angry")
				emotions.erase("Sad")
				var happy: int = emotions.get("Happy", 0) as int
				emotions["Happy"] = happy + 2
				p["emotions"] = emotions
		return result
	return result

## Returns net damage modifier from the party member's emotions.
## Happy: +1 per level (consumes 1 Happy). Sad: -1 per level (Sad stays until cleared).
func _emotion_damage_modifier(party: Array[Dictionary], index: int) -> int:
	if index < 0 or index >= party.size():
		return 0
	var p: Dictionary = party[index]
	if (p.get("hp", 1) as int) <= 0:
		return 0
	var emotions: Dictionary = p.get("emotions", {}) as Dictionary
	var happy: int = emotions.get("Happy", 0) as int
	var sad: int = emotions.get("Sad", 0) as int
	var bonus := 0
	if happy > 0:
		bonus += happy
		_remove_emotion(party, index, "Happy", 1)
	bonus -= sad
	return bonus

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

