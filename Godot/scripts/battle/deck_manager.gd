extends Node
class_name DeckManager

signal hand_changed(hand: Array[Dictionary])
signal deck_discard_changed(deck_size: int, discard_size: int)
signal card_drawn(card_data: Dictionary)
signal card_played(card_data: Dictionary)

const MAX_HAND_SIZE: int = 4

var _deck: Array[Dictionary] = []
var _discard: Array[Dictionary] = []
var _hand: Array[Dictionary] = []

func reset_with_full_deck(initial_draw: int) -> void:
	var full_deck := _build_full_deck()
	_deck = full_deck.duplicate()
	_deck.shuffle()
	_discard.clear()
	_hand.clear()
	for i in range(min(initial_draw, _deck.size())):
		_hand.append(_deck.pop_back())
	_emit_state()

func _build_full_deck() -> Array[Dictionary]:
	var templates: Array[Dictionary] = [
		{"id": "gain_energy", "title": "Gain Energy", "cost": 0, "type": "POWER", "description": "Gain 8 energy.", "requirement": "—", "requires_target": false},
		{"id": "basic_punch", "title": "Basic Punch", "cost": 1, "type": "ATTACK", "description": "Deal 2 damage to enemy.", "requirement": "1 energy", "requires_target": false},
		{"id": "get_angry", "title": "Get Angry", "cost": 0, "type": "SKILL", "description": "Add 2 Angry to target.", "requirement": "—", "requires_target": true},
		{"id": "angry_punch", "title": "Angry Punch", "cost": 0, "type": "ATTACK", "description": "Deal 5 damage (consume 1 Angry from target).", "requirement": "1 Angry", "requires_target": true, "emotion_requirement": {"emotion": "Angry", "amount": 1}},
		{"id": "cheer_up", "title": "Cheer Up", "cost": 1, "type": "SKILL", "description": "Set Angry/Sad 0, add 2 Happy to target.", "requirement": "1 energy", "requires_target": true},
	]
	var counts: Array[int] = [3, 4, 3, 2, 1]
	var out: Array[Dictionary] = []
	for i in range(templates.size()):
		for _c in range(counts[i]):
			var d: Dictionary = templates[i].duplicate()
			d["id"] = "%s_%d" % [d["id"], out.size()]
			out.append(d)
	return out

func draw_cards(amount: int) -> void:
	for _i in range(amount):
		if _deck.is_empty():
			if _discard.is_empty():
				break
			_deck = _discard.duplicate()
			_discard.clear()
			_deck.shuffle()
		if _deck.is_empty():
			break
		var card: Dictionary = _deck.pop_back()
		if _hand.size() >= MAX_HAND_SIZE:
			_hand.remove_at(0)
		_hand.append(card)
		card_drawn.emit(card)
	_emit_state()

func play_card(card_data: Dictionary) -> void:
	var idx := _hand.find(card_data)
	if idx >= 0:
		_hand.remove_at(idx)
	_discard.append(card_data)
	card_played.emit(card_data)
	_emit_state()

func discard_hand_into_discard() -> void:
	var discard_with_hand := _hand.duplicate()
	discard_with_hand.append_array(_discard)
	_discard = discard_with_hand
	_hand.clear()
	_emit_state()

func get_hand() -> Array[Dictionary]:
	return _hand.duplicate()

func get_deck_size() -> int:
	return _deck.size()

func get_discard_size() -> int:
	return _discard.size()

func _emit_state() -> void:
	hand_changed.emit(_hand.duplicate())
	deck_discard_changed.emit(_deck.size(), _discard.size())

