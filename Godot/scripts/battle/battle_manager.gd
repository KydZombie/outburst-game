extends Node
class_name BattleManager

signal state_changed(state: Dictionary)
signal energy_changed(energy: int)
signal enemy_intent_changed(intent_value: int, intent_type: String)
signal card_played(card_data: Dictionary)
signal card_effect_for_ui(card_data: Dictionary)
## Emitted when the battle ends. result is "win" or "loss".
signal battle_ended(result: String)
## Emitted when the enemy heals. Amount is the actual HP restored.
signal enemy_heal_action(amount: int)
signal target_character_changed(index: int)
signal enemy_attacked(target_idx: int, damage: int)
signal enemy_hit(damage: int)
## Hotkey (1–3) tried to play a skill that needs a party target — UI must start targeting.
signal target_skill_hotkey_needs_party(card_data: Dictionary)
signal ally_buffed(target_idx: int, card_data: Dictionary)
## Fired when the player can act (battle start and after each enemy phase + new hand).
signal player_turn_ready(turn: int)
## Emitted when the player ends their turn; UI shows "ENEMY TURN" before enemy AI runs.
signal enemy_turn_started()
## Emitted when the turn will auto-pass (empty hand, or no legal play/draw).
signal turn_auto_skipped(reason: String)

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
var _turn: int = 1
var _battle_over: bool = false
var _target_character_index: int = 0
## Card plays used this player turn (max = TurnManager.MAX_CARD_PLAYS_PER_TURN); draw blocked at limit too.
var _cards_played_this_turn: int = 0
## True while waiting for enemy-turn banner delay before `turn_manager.end_turn()` runs.
var _enemy_turn_resolving: bool = false
## Prevents stacking multiple forced end-turn timers from repeated state emits.
var _forced_end_turn_pending: bool = false
## True while waiting to auto-pass after a new hand (blocks duplicate deferred stuck checks).
var _post_enemy_auto_skip_pending: bool = false
## Manual [Draw] uses no energy for this many draws at battle start; then cost = 0 if next card is Free else 1.
const OPENING_FREE_MANUAL_DRAWS := 13
var _opening_free_draws_remaining: int = 0

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
	var tree := get_tree()
	var root: Window = tree.get_root() if tree else null
	_core_adapter = root.get_node_or_null("BattleScene/CoreAdapter") if root else null
	if _core_adapter and _core_adapter.has_signal("EnemyHealed"):
		_core_adapter.EnemyHealed.connect(func(amount: int) -> void:
			enemy_heal_action.emit(amount)
		)
	_init_state()
	turn_manager.setup(enemy_ai, combat_resolver, deck_manager)
	_connect_signals()
	_emit_full_state()
	call_deferred("_emit_initial_player_turn")

func _emit_initial_player_turn() -> void:
	if not _battle_over:
		player_turn_ready.emit(_turn)

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
		"power": 10,
		"intent_value": 30,
		"intent_type": "attack",
	}]
	_energy = TurnManager.BASE_ENERGY
	_turn = 1
	_target_character_index = 0
	_cards_played_this_turn = 0
	deck_manager.reset_with_full_deck(TurnManager.HAND_SIZE)
	_opening_free_draws_remaining = OPENING_FREE_MANUAL_DRAWS

func _connect_signals() -> void:
	# Deck signals update UI via battle_ui_manager -> on_hand_changed / on_deck_discard_changed.
	# Do not call _emit_full_state() here — request_play_card, _on_draw_requested, and _end_turn already emit once.
	turn_manager.enemy_heal_action.connect(_on_enemy_heal_action)
	turn_manager.enemy_attacked.connect(func(idx: int, dmg: int) -> void: enemy_attacked.emit(idx, dmg))
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

func request_play_card(card_data: Dictionary) -> bool:
	if _battle_over:
		return false
	if _enemy_turn_resolving:
		return false
	if _cards_played_this_turn >= TurnManager.MAX_CARD_PLAYS_PER_TURN:
		return false
	_auto_set_target_for_attack_if_needed(card_data)
	if not _meets_requirements(card_data):
		return false
	var cost: int = card_data.get("cost", 0) as int
	_energy -= cost
	deck_manager.play_card(card_data)
	_cards_played_this_turn += 1
	var hp_before: int = _enemies[0].get("hp", 60) as int if _enemies.size() > 0 else 0
	var effect := card_effects.resolve_card_effect(
		card_data,
		_party,
		_target_character_index,
		_enemies,
		_energy,
		combat_resolver
	)
	_energy = effect["energy"]
	var hp_after: int = _enemies[0].get("hp", 60) as int if _enemies.size() > 0 else 0
	var dmg_dealt: int = hp_before - hp_after
	var card_id_str: String = card_data.get("id", "") as String
	var is_enemy_strike: bool = card_id_str.begins_with("basic_punch") or card_id_str.begins_with("angry_punch")
	card_played.emit(card_data)
	card_effect_for_ui.emit(card_data)
	var is_ally_skill: bool = card_data.get("requires_target", false) as bool and (card_data.get("type", "") as String) == "SKILL"
	if is_ally_skill:
		ally_buffed.emit(_target_character_index, card_data)
	_update_enemy_intent()
	_emit_full_state()
	# After UI sync so hit VFX isn't overwritten; still fire when damage was fully mitigated (e.g. Sad) so the punch reads.
	if dmg_dealt > 0 or is_enemy_strike:
		enemy_hit.emit(dmg_dealt)
	_check_game_ended()
	if not _battle_over:
		if _cards_played_this_turn >= TurnManager.MAX_CARD_PLAYS_PER_TURN:
			_schedule_end_turn_after_max_card_plays()
		else:
			_check_auto_end_turn()
	return true

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
	if index < 0 or index >= hand.size():
		return
	var card_data: Dictionary = hand[index]
	if _is_target_skill_hotkey_card(card_data):
		target_skill_hotkey_needs_party.emit(card_data)
		return
	request_play_card(card_data)


func _is_target_skill_hotkey_card(card_data: Dictionary) -> bool:
	var needs_target: bool = card_data.get("requires_target", false) as bool
	return needs_target and (card_data.get("type", "") as String) == "SKILL"

func _auto_set_target_for_attack_if_needed(card_data: Dictionary) -> void:
	# UX rule: attacks do not ask the player to pick a party target.
	# Some attack cards still consume emotion from a specific party member
	# (via `emotion_requirement`). For those, we pick the first alive member
	# that satisfies the emotion requirement.
	if (card_data.get("type", "") as String) != "ATTACK":
		return
	if not (card_data.get("requires_target", false) as bool):
		return
	var emotion_req: Variant = card_data.get("emotion_requirement", null)
	if emotion_req == null or not (emotion_req is Dictionary):
		return
	var req_d: Dictionary = emotion_req as Dictionary
	var em: String = req_d.get("emotion", "") as String
	var amount: int = req_d.get("amount", 0) as int
	if em == "" or amount <= 0:
		return
	for i in range(_party.size()):
		var p: Dictionary = _party[i]
		var hp: int = p.get("hp", 0) as int
		if hp <= 0:
			continue
		var emotions: Dictionary = p.get("emotions", {}) as Dictionary
		var have: int = emotions.get(em, 0) as int
		if have >= amount:
			if i != _target_character_index:
				_target_character_index = i
				target_character_changed.emit(i)
			return

func _on_draw_requested() -> void:
	if _battle_over:
		return
	if _enemy_turn_resolving:
		return
	if _cards_played_this_turn >= TurnManager.MAX_CARD_PLAYS_PER_TURN:
		return
	if deck_manager.get_deck_size() <= 0 and deck_manager.get_discard_size() <= 0:
		return
	var hand_before: int = deck_manager.get_hand().size()
	var use_opening_free: bool = _opening_free_draws_remaining > 0
	var draw_cost: int = 0 if use_opening_free else deck_manager.get_energy_cost_for_next_draw()
	if not use_opening_free:
		if draw_cost >= 999:
			return
		if _energy < draw_cost:
			return
		_energy -= draw_cost
	deck_manager.draw_cards(1)
	if use_opening_free and deck_manager.get_hand().size() > hand_before:
		_opening_free_draws_remaining = maxi(0, _opening_free_draws_remaining - 1)
	_emit_full_state()
	_check_auto_end_turn()

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
			dst_e["power"] = src_e.get("power", dst_e.get("power", 10))

func _on_end_turn_requested() -> void:
	if _battle_over:
		return
	if _enemy_turn_resolving:
		return
	_end_turn()

func _end_turn() -> void:
	if _battle_over:
		return
	if _enemy_turn_resolving:
		return
	_forced_end_turn_pending = false
	_post_enemy_auto_skip_pending = false
	_enemy_turn_resolving = true
	enemy_turn_started.emit()
	_emit_full_state()
	var tree := get_tree()
	if tree == null:
		_enemy_turn_resolving = false
		return
	# Let "ENEMY TURN" banner + UI settle before Jeff resolves (was 0.5s — too fast to read).
	tree.create_timer(2.35).timeout.connect(_complete_end_turn_after_enemy_banner, CONNECT_ONE_SHOT)

func _complete_end_turn_after_enemy_banner() -> void:
	if _battle_over:
		_enemy_turn_resolving = false
		return
	_cards_played_this_turn = 0
	var summary := turn_manager.end_turn(_party, _enemies, _turn, _energy)
	_turn = summary["turn"]
	_energy = summary["energy"]
	_update_enemy_intent()
	_check_game_ended()
	if _battle_over:
		_enemy_turn_resolving = false
		_emit_full_state()
		return
	# Before giving the player control: if nothing is playable at current energy, chain another enemy phase (no input required).
	if not (_can_play_any_card() or _can_draw()):
		_post_enemy_auto_skip_pending = true
		_forced_end_turn_pending = true
		_enemy_turn_resolving = false
		_emit_full_state()
		turn_auto_skipped.emit("post_enemy_no_actions")
		var tree := get_tree()
		if tree == null:
			_post_enemy_auto_skip_pending = false
			_forced_end_turn_pending = false
			return
		# Let the notice banner stay readable (~3s hold + fades) before passing turn again.
		tree.create_timer(3.2).timeout.connect(_finish_post_enemy_auto_skip, CONNECT_ONE_SHOT)
		return
	_enemy_turn_resolving = false
	_emit_full_state()
	player_turn_ready.emit(_turn)
	get_tree().create_timer(0.12).timeout.connect(_check_softlock_after_new_hand, CONNECT_ONE_SHOT)

func _finish_post_enemy_auto_skip() -> void:
	_post_enemy_auto_skip_pending = false
	_forced_end_turn_pending = false
	if _battle_over or _enemy_turn_resolving:
		return
	if _can_play_any_card() or _can_draw():
		player_turn_ready.emit(_turn)
		return
	_end_turn()

func _check_softlock_after_new_hand() -> void:
	if _battle_over or _enemy_turn_resolving:
		return
	_check_stuck_player_turn()

func _check_stuck_player_turn() -> void:
	if _battle_over or _enemy_turn_resolving or _post_enemy_auto_skip_pending:
		return
	var hand: Array[Dictionary] = deck_manager.get_hand()
	if hand.is_empty():
		if _can_draw():
			return
		_schedule_forced_end_turn("empty_hand")
		return
	if _can_play_any_card() or _can_draw():
		return
	_schedule_forced_end_turn("no_actions")

func _schedule_forced_end_turn(reason: String) -> void:
	if _forced_end_turn_pending or _battle_over or _enemy_turn_resolving:
		return
	_forced_end_turn_pending = true
	turn_auto_skipped.emit(reason)
	var tree := get_tree()
	if tree == null:
		_forced_end_turn_pending = false
		return
	tree.create_timer(3.0).timeout.connect(func() -> void:
		_forced_end_turn_pending = false
		if _battle_over or _enemy_turn_resolving:
			return
		if _can_play_any_card() or _can_draw():
			return
		_end_turn()
	, CONNECT_ONE_SHOT)

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
		# Enemy heals for (max_hp / 3) with integer truncation.
		e["intent_value"] = floori(float(max_hp) / 3.0)
	else:
		e["intent_type"] = "attack"
		e["intent_value"] = power * 3
	enemy_intent_changed.emit(e["intent_value"], e.get("intent_type", "attack") as String)

func get_current_state() -> Dictionary:
	return {
		"party": _party,
		"enemies": _enemies,
		"energy": _energy,
		"turn": _turn,
		"hand": deck_manager.get_hand(),
		"deck_size": deck_manager.get_deck_size(),
		"discard_size": deck_manager.get_discard_size(),
		"target_character_index": _target_character_index,
		"cards_played_this_turn": _cards_played_this_turn,
		"max_card_plays_per_turn": TurnManager.MAX_CARD_PLAYS_PER_TURN,
		"enemy_turn_in_progress": _enemy_turn_resolving,
		## True after Jeff's phase while we wait to auto-pass again — player can't act; UI should not show player "no playable" toasts.
		"post_enemy_chain_pending": _post_enemy_auto_skip_pending,
	}

func _emit_full_state() -> void:
	var state := get_current_state()
	energy_changed.emit(_energy)
	state_changed.emit(state)
	if not _battle_over and not _enemy_turn_resolving:
		call_deferred("_deferred_check_stuck_player_turn")

func _deferred_check_stuck_player_turn() -> void:
	if _battle_over or _enemy_turn_resolving or _post_enemy_auto_skip_pending:
		return
	_check_stuck_player_turn()

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

func _can_play_any_card() -> bool:
	var hand: Array[Dictionary] = deck_manager.get_hand()
	if hand.is_empty():
		return false
	for card in hand:
		if _is_card_playable_now(card):
			return true
	return false


## True if this card could be played with *some* legal party target (matches request_play_card rules).
func _is_card_playable_now(card_data: Dictionary) -> bool:
	if _cards_played_this_turn >= TurnManager.MAX_CARD_PLAYS_PER_TURN:
		return false
	var cost: int = card_data.get("cost", 0) as int
	if _energy < cost:
		return false
	var requires_target: bool = card_data.get("requires_target", false) as bool
	var emotion_req: Variant = card_data.get("emotion_requirement", null)
	if emotion_req != null and emotion_req is Dictionary:
		var req: Dictionary = emotion_req as Dictionary
		var em: String = req.get("emotion", "") as String
		var amount: int = req.get("amount", 0) as int
		if em != "" and amount > 0:
			for p in _party:
				if (p.get("hp", 0) as int) <= 0:
					continue
				var emotions: Dictionary = p.get("emotions", {}) as Dictionary
				if (emotions.get(em, 0) as int) >= amount:
					return true
			return false
	if requires_target:
		for p in _party:
			if (p.get("hp", 0) as int) > 0:
				return true
		return false
	return true

func _can_draw() -> bool:
	if _cards_played_this_turn >= TurnManager.MAX_CARD_PLAYS_PER_TURN:
		return false
	if deck_manager.get_deck_size() <= 0 and deck_manager.get_discard_size() <= 0:
		return false
	if _opening_free_draws_remaining > 0:
		return true
	var draw_cost: int = deck_manager.get_energy_cost_for_next_draw()
	if draw_cost >= 999:
		return false
	return _energy >= draw_cost


func _schedule_end_turn_after_max_card_plays() -> void:
	if _battle_over:
		return
	var tree := get_tree()
	if tree == null:
		return
	tree.create_timer(0.5).timeout.connect(_on_max_plays_turn_end_timer, CONNECT_ONE_SHOT)


func _on_max_plays_turn_end_timer() -> void:
	if _battle_over:
		return
	if _enemy_turn_resolving:
		return
	if _cards_played_this_turn < TurnManager.MAX_CARD_PLAYS_PER_TURN:
		return
	_end_turn()


func _check_auto_end_turn() -> void:
	if _battle_over:
		return
	if _enemy_turn_resolving:
		return
	if _can_play_any_card() or _can_draw():
		return
	get_tree().create_timer(0.6).timeout.connect(_auto_end_turn, CONNECT_ONE_SHOT)

func _auto_end_turn() -> void:
	if _battle_over:
		return
	if _enemy_turn_resolving:
		return
	if _can_play_any_card() or _can_draw():
		return
	_end_turn()
