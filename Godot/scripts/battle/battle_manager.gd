extends Node
class_name BattleManager

signal state_changed(state: Dictionary)
signal energy_changed(energy: int, max_energy: int)
signal enemy_intent_changed(intent_value: int, intent_type: String)
signal card_played(card_data: Dictionary)
signal card_effect_for_ui(card_data: Dictionary)
## Emitted when the battle ends. result is "win" or "loss".
signal battle_ended(result: String)
## Emitted when the enemy heals. Amount is the actual HP restored.
signal enemy_heal_action(amount: int)
signal target_character_changed(index: int)

var deck_manager: DeckManager
var combat_resolver: CombatResolver
var card_effects: CardEffects
var enemy_ai: EnemyAI
var turn_manager: TurnManager
var input_controller: InputController
var _core_adapter: Node

var _party: Array[Dictionary] = []
var _enemies: Array[Dictionary] = []
var _energy: int = 0
var _max_energy: int = 4
var _turn: int = 1
var _battle_over: bool = false
var _target_character_index: int = 0

func _ready() -> void:
	deck_manager = DeckManager.new()
	combat_resolver = CombatResolver.new()
	card_effects = CardEffects.new()
	enemy_ai = EnemyAI.new()
	turn_manager = TurnManager.new()
	input_controller = InputController.new()
	add_child(deck_manager)
	add_child(combat_resolver)
	add_child(card_effects)
	add_child(enemy_ai)
	add_child(turn_manager)
	add_child(input_controller)
	_core_adapter = get_tree().get_root().get_node_or_null("BattleScene/CoreAdapter")
	if _core_adapter and _core_adapter.has_signal("EnemyHealed"):
		_core_adapter.EnemyHealed.connect(func(amount: int) -> void:
			enemy_heal_action.emit(amount)
		)
	_init_state()
	turn_manager.setup(enemy_ai, combat_resolver, deck_manager)
	_connect_signals()
	_emit_full_state()

func _init_state() -> void:
	var default_emotions := {"Angry": 0, "Sad": 0, "Happy": 0}
	_party = [
		{"name": "Niko", "hp": 100, "max_hp": 100, "emotions": default_emotions.duplicate()},
		{"name": "Remi", "hp": 100, "max_hp": 100, "emotions": default_emotions.duplicate()},
		{"name": "Arna", "hp": 100, "max_hp": 100, "emotions": default_emotions.duplicate()},
		{"name": "Caelum", "hp": 100, "max_hp": 100, "emotions": default_emotions.duplicate()},
		{"name": "Syd", "hp": 100, "max_hp": 100, "emotions": default_emotions.duplicate()},
	]
	_enemies = [{
		"name": "Jeff",
		"hp": 60,
		"max_hp": 60,
		"power": 4,
		"intent_value": 12,
		"intent_type": "attack",
	}]
	_energy = 0
	_max_energy = 4
	_turn = 1
	_target_character_index = 0
	deck_manager.reset_with_full_deck(3)

func _connect_signals() -> void:
	deck_manager.hand_changed.connect(func(_h: Array[Dictionary]) -> void:
		_emit_full_state()
	)
	deck_manager.deck_discard_changed.connect(func(_d: int, _c: int) -> void:
		_emit_full_state()
	)
	turn_manager.turn_ended.connect(_on_turn_ended)
	turn_manager.enemy_heal_action.connect(_on_enemy_heal_action)
	input_controller.play_card_by_index.connect(_on_play_card_by_index)
	input_controller.draw_card_requested.connect(_on_draw_requested)
	input_controller.end_turn_requested.connect(_on_end_turn_requested)
	input_controller.quit_requested.connect(func() -> void:
		get_tree().quit()
	)

func set_target_character_index(index: int) -> void:
	if index >= 0 and index < _party.size():
		_target_character_index = index
		target_character_changed.emit(index)

func request_play_card(card_data: Dictionary) -> void:
	if _battle_over:
		return
	if not _meets_requirements(card_data):
		return
	var cost: int = card_data.get("cost", 0) as int
	_energy -= cost
	deck_manager.play_card(card_data)
	var effect := card_effects.resolve_card_effect(
		card_data,
		_party,
		_target_character_index,
		_enemies,
		_energy,
		combat_resolver
	)
	_energy = mini(effect["energy"], _max_energy)
	card_played.emit(card_data)
	card_effect_for_ui.emit(card_data)
	_sync_from_core_snapshot()
	_update_enemy_intent()
	_emit_full_state()
	_check_game_ended()

func _meets_requirements(card_data: Dictionary) -> bool:
	var cost: int = card_data.get("cost", 0) as int
	if _energy < cost:
		return false
	if card_data.get("requires_target", false) as bool:
		if _target_character_index < 0 or _target_character_index >= _party.size():
			return false
		var target_p: Dictionary = _party[_target_character_index]
		var target_hp: int = target_p.get("hp", 100) as int
		if target_hp <= 0:
			return false
	var emotion_req: Variant = card_data.get("emotion_requirement", null)
	if emotion_req != null and emotion_req is Dictionary:
		var em: String = emotion_req.get("emotion", "") as String
		var amount: int = emotion_req.get("amount", 0) as int
		if amount > 0 and (_target_character_index < 0 or _target_character_index >= _party.size()):
			return false
		var target_p: Dictionary = _party[_target_character_index]
		var emotions: Dictionary = target_p.get("emotions", {}) as Dictionary
		var have: int = emotions.get(em, 0) as int
		if have < amount:
			return false
	return true

func _on_play_card_by_index(index: int) -> void:
	var hand: Array[Dictionary] = deck_manager.get_hand()
	if index >= 0 and index < hand.size():
		if _core_adapter and _core_adapter.has_method("PlayCardByIndex"):
			_core_adapter.PlayCardByIndex(index, _target_character_index)
		request_play_card(hand[index])

func _on_draw_requested() -> void:
	# D = draw 1 card then end turn (match Terminal "d")
	if deck_manager.get_deck_size() > 0 or deck_manager.get_discard_size() > 0:
		if _core_adapter and _core_adapter.has_method("DrawCard"):
			_core_adapter.DrawCard()
		deck_manager.draw_cards(1)
	_emit_full_state()
	_end_turn()

func _sync_from_core_snapshot() -> void:
	if not _core_adapter:
		return
	if not _core_adapter.has_method("GetSnapshot"):
		return
	var snapshot: Dictionary = _core_adapter.GetSnapshot()
	var core_party: Array = snapshot.get("party", [])
	var core_enemies: Array = snapshot.get("enemies", [])
	if core_party.size() == _party.size():
		for i in range(core_party.size()):
			var src: Dictionary = core_party[i]
			var dst: Dictionary = _party[i]
			dst["hp"] = src.get("hp", dst.get("hp", 100))
			dst["max_hp"] = src.get("max_hp", dst.get("max_hp", 100))
			dst["emotions"] = src.get("emotions", dst.get("emotions", {}))
	if core_enemies.size() > 0 and _enemies.size() > 0:
		var src_e: Dictionary = core_enemies[0]
		var dst_e: Dictionary = _enemies[0]
		dst_e["hp"] = src_e.get("hp", dst_e.get("hp", 60))
		dst_e["max_hp"] = src_e.get("max_hp", dst_e.get("max_hp", 60))
		if src_e.has("power"):
			dst_e["power"] = src_e.get("power", dst_e.get("power", 4))

func _on_end_turn_requested() -> void:
	if _battle_over:
		return
	_end_turn()

func _end_turn() -> void:
	var summary := turn_manager.end_turn(_party, _enemies, _turn, _energy)
	_turn = summary["turn"]
	_energy = mini(summary["energy"], _max_energy)
	_update_enemy_intent()
	_emit_full_state()
	_check_game_ended()

func _on_turn_ended(new_turn: int, new_energy: int) -> void:
	_turn = new_turn
	_energy = mini(new_energy, _max_energy)
	_emit_full_state()

func _on_enemy_heal_action(amount: int) -> void:
	enemy_heal_action.emit(amount)

func _update_enemy_intent() -> void:
	if _enemies.is_empty():
		return
	var e: Dictionary = _enemies[0]
	var hp: int = e.get("hp", 60) as int
	var max_hp: int = e.get("max_hp", 60) as int
	var power: int = e.get("power", 10) as int
	if hp <= 20 and max_hp > 0:
		e["intent_type"] = "heal"
		e["intent_value"] = max_hp / 3
	else:
		e["intent_type"] = "attack"
		e["intent_value"] = power * 3
	enemy_intent_changed.emit(e["intent_value"], e.get("intent_type", "attack") as String)

func get_current_state() -> Dictionary:
	return {
		"party": _party,
		"enemies": _enemies,
		"energy": _energy,
		"max_energy": _max_energy,
		"turn": _turn,
		"hand": deck_manager.get_hand(),
		"deck_size": deck_manager.get_deck_size(),
		"discard_size": deck_manager.get_discard_size(),
		"target_character_index": _target_character_index,
	}

func _emit_full_state() -> void:
	var state := get_current_state()
	energy_changed.emit(_energy, _max_energy)
	state_changed.emit(state)

func _all_party_dead(party: Array[Dictionary]) -> bool:
	for p in party:
		var hp: int = p.get("hp", 100) as int
		if hp > 0:
			return false
	return party.size() > 0

func _jeff_dead(enemies: Array[Dictionary]) -> bool:
	if enemies.is_empty():
		return false
	var e: Dictionary = enemies[0]
	var hp: int = e.get("hp", 60) as int
	return hp <= 0

func _check_game_ended() -> void:
	if _battle_over:
		return
	var party_dead: bool = _all_party_dead(_party)
	var jeff_dead: bool = _jeff_dead(_enemies)
	# If both happen in the same turn, player wins.
	if party_dead and jeff_dead:
		_battle_over = true
		battle_ended.emit("win")
		return
	if jeff_dead:
		_battle_over = true
		battle_ended.emit("win")
		return
	if party_dead:
		_battle_over = true
		battle_ended.emit("loss")
		return

