extends Node
class_name DeckManager

signal hand_changed(hand: Array[Dictionary])
signal deck_discard_changed(deck_size: int, discard_size: int)
signal card_drawn(card_data: Dictionary)
signal card_played(card_data: Dictionary)
signal deck_reshuffled()

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
	_ensure_opening_hand_has_gain_energy()
	_emit_state()

func _build_full_deck() -> Array[Dictionary]:
	var templates: Array[Dictionary] = [
		{"id": "gain_energy", "title": "Gain Energy", "cost": 0, "type": "POWER", "description": "Gain 8 energy.", "requires_target": false},
		{"id": "basic_punch", "title": "Basic Punch", "cost": 1, "type": "ATTACK", "description": "Deal 4 damage to Jeff.", "requires_target": false},
		{"id": "get_angry", "title": "Get Angry", "cost": 0, "type": "SKILL", "description": "Add 2 Angry to ally.", "requires_target": true},
		{"id": "angry_punch", "title": "Angry Punch", "cost": 0, "type": "SKILL", "description": "10 damage. Uses 1 Angry.", "requires_target": true, "emotion_requirement": {"emotion": "Angry", "amount": 1}},
		{"id": "cheer_up", "title": "Cheer Up", "cost": 1, "type": "SKILL", "description": "Clear Angry & Sad, add 2 Happy to ally.", "requires_target": true},
	]
	var counts: Array[int] = [3, 4, 3, 2, 1]
	var out: Array[Dictionary] = []
	for i in range(templates.size()):
		for _c in range(counts[i]):
			var d: Dictionary = templates[i].duplicate()
			d["id"] = "%s_%d" % [d["id"], out.size()]
			out.append(d)
	return out

## If the opening hand has no Gain Energy card, swap one random hand card with a Gain Energy from the deck.
## Prevents a soft-lock at 0 energy with no way to play.
func _ensure_opening_hand_has_gain_energy() -> void:
	if _hand.is_empty():
		return
	for c in _hand:
		if (c.get("id", "") as String).begins_with("gain_energy"):
			return
	var swap_idx := -1
	for i in range(_deck.size()):
		if (_deck[i].get("id", "") as String).begins_with("gain_energy"):
			swap_idx = i
			break
	if swap_idx < 0:
		return
	var ge_card: Dictionary = _deck.pop_at(swap_idx)
	var hand_idx: int = randi() % _hand.size()
	var removed: Dictionary = _hand[hand_idx]
	_hand[hand_idx] = ge_card
	_deck.append(removed)
	_deck.shuffle()

## Energy to take the next card from the deck into hand: 0 if that card's data `cost` is 0 ("Free"), else 1.
## If the deck is empty and the next draw would reshuffle discard, returns 1 (order unknown until shuffle).
func get_energy_cost_for_next_draw() -> int:
	if _deck.is_empty() and _discard.is_empty():
		return 999
	if not _deck.is_empty():
		var next_card: Dictionary = _deck[_deck.size() - 1]
		var c: int = next_card.get("cost", 0) as int
		return 0 if c == 0 else 1
	return 1


func draw_cards(amount: int) -> void:
	for _i in range(amount):
		if _deck.is_empty():
			if _discard.is_empty():
				break
			_deck = _discard.duplicate()
			_discard.clear()
			_deck.shuffle()
			deck_reshuffled.emit()
		if _deck.is_empty():
			break
		var card: Dictionary = _deck.pop_back()
		_hand.append(card)
		card_drawn.emit(card)
	_emit_state()

## After drawing a full hand at turn boundaries, guarantee at least one free Gain Energy if any remain in deck or discard.
func ensure_hand_has_gain_energy_if_possible() -> void:
	if _hand.is_empty():
		return
	for c in _hand:
		if (c.get("id", "") as String).begins_with("gain_energy"):
			return
	var swap_idx := -1
	for i in range(_deck.size()):
		if (_deck[i].get("id", "") as String).begins_with("gain_energy"):
			swap_idx = i
			break
	if swap_idx >= 0:
		var ge_card: Dictionary = _deck.pop_at(swap_idx)
		var hand_idx: int = randi() % _hand.size()
		var removed: Dictionary = _hand[hand_idx]
		_hand[hand_idx] = ge_card
		_deck.append(removed)
		_deck.shuffle()
		_emit_state()
		return
	for i in range(_discard.size()):
		if (_discard[i].get("id", "") as String).begins_with("gain_energy"):
			var ge_from_disc: Dictionary = _discard.pop_at(i)
			var hi: int = randi() % _hand.size()
			var removed_h: Dictionary = _hand[hi]
			_hand[hi] = ge_from_disc
			_deck.append(removed_h)
			_deck.shuffle()
			_emit_state()
			return

func play_card(card_data: Dictionary) -> void:
	var card_id: String = card_data.get("id", "") as String
	var idx := -1
	for i in range(_hand.size()):
		if (_hand[i].get("id", "") as String) == card_id:
			idx = i
			break
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

## Grouped counts for deck / discard popups (sorted by title).
func get_deck_preview_entries() -> Array[Dictionary]:
	return _pile_preview_entries(_deck)


func get_discard_preview_entries() -> Array[Dictionary]:
	return _pile_preview_entries(_discard)


func _pile_preview_entries(pile: Array) -> Array[Dictionary]:
	var by_title: Dictionary = {}
	for c in pile:
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var cd: Dictionary = c
		var title: String = str(cd.get("title", "?"))
		var ctype: String = str(cd.get("type", "CARD"))
		if by_title.has(title):
			var entry: Dictionary = by_title[title]
			entry["count"] = int(entry["count"]) + 1
		else:
			by_title[title] = {"title": title, "count": 1, "type": ctype}
	var result: Array[Dictionary] = []
	for k in by_title.keys():
		result.append(by_title[k] as Dictionary)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("title", "")).to_lower() < str(b.get("title", "")).to_lower()
	)
	return result

func _emit_state() -> void:
	hand_changed.emit(_hand.duplicate())
	deck_discard_changed.emit(_deck.size(), _discard.size())

