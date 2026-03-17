extends Control
class_name BattleUIManager
## Orchestrates battle UI only: wires BattleManager to node refs and delegates to UI helpers.
## Game logic stays in BattleManager; portraits/panels/effects live in scripts/battle/ui/.

const CARD_SCENE := preload("res://scenes/card_ui.tscn")
const CARD_STYLE_BASE := preload("res://resources/card_base_stylebox.tres")
const CARD_STYLE_HOVER := preload("res://resources/card_hover_stylebox.tres")
const CARD_STYLE_DRAG := preload("res://resources/card_drag_stylebox.tres")
const GAME_OVER_SCENE_PATH := "res://scenes/game_over_scene.tscn"

var _refs: BattleUINodeRefs
var _hand_manager: HandManager
var _drag_system: CardDragSystem
var _battle_manager: BattleManager
var _deck_manager: DeckManager

func _get_audio_manager() -> AudioManager:
	return get_tree().get_root().get_node_or_null("BattleScene/AudioManager") as AudioManager

func _ready() -> void:
	_refs = BattleUINodeRefs.new()
	_refs.find_from(self)
	_create_battle_systems()
	_setup_hand_and_drag()
	_connect_battle_signals()
	call_deferred("_deferred_refresh_hand")
	if _refs.end_turn_btn:
		_refs.end_turn_btn.pressed.connect(func() -> void: _battle_manager._end_turn())
		_refs.end_turn_btn.mouse_entered.connect(_on_end_turn_hover.bind(true))
		_refs.end_turn_btn.mouse_exited.connect(_on_end_turn_hover.bind(false))

func _create_battle_systems() -> void:
	_battle_manager = BattleManager.new()
	add_child(_battle_manager)
	_deck_manager = _battle_manager.deck_manager

func _setup_hand_and_drag() -> void:
	if not _refs.hand_container:
		return
	_hand_manager = HandManager.new()
	add_child(_hand_manager)
	_drag_system = CardDragSystem.new()
	add_child(_drag_system)
	if _refs.drag_layer:
		var drop_area := _refs.play_zone if _refs.play_zone else _refs.right_panel
		_drag_system.setup(_refs.hand_container, _refs.drag_layer, drop_area)
	_hand_manager.setup(_refs.hand_container, CARD_SCENE, _drag_system, CARD_STYLE_BASE, CARD_STYLE_HOVER, CARD_STYLE_DRAG)
	_hand_manager.card_played.connect(func(card_data: Dictionary) -> void: _battle_manager.request_play_card(card_data))
	_drag_system.card_drag_ended.connect(_on_drag_ended)

func _on_drag_ended(card_ui: Control, play_requested: bool) -> void:
	if play_requested and card_ui.get("card_data"):
		_battle_manager.request_play_card(card_ui.card_data)
	elif _hand_manager and _hand_manager.has_method("_update_fan_layout"):
		_hand_manager._update_fan_layout()

func _connect_battle_signals() -> void:
	_battle_manager.state_changed.connect(_on_state_changed)
	_battle_manager.energy_changed.connect(_on_energy_changed)
	_battle_manager.enemy_intent_changed.connect(_on_enemy_intent_changed)
	_battle_manager.card_effect_for_ui.connect(_on_card_played_from_logic)
	_battle_manager.battle_ended.connect(_on_battle_ended)
	_battle_manager.target_character_changed.connect(func(_i: int) -> void: _refresh_initial_state())
	_deck_manager.hand_changed.connect(_on_hand_changed)
	_deck_manager.deck_discard_changed.connect(_on_deck_discard_changed)
	_setup_party_row_clicks()
	_refresh_initial_state()

func _setup_party_row_clicks() -> void:
	if not _refs.party_list:
		return
	for i in range(_refs.party_list.get_child_count()):
		var row: Control = _refs.party_list.get_child(i) as Control
		if row:
			row.mouse_filter = Control.MOUSE_FILTER_STOP
			row.gui_input.connect(_on_party_row_gui_input.bind(i))

func _on_party_row_gui_input(event: InputEvent, party_index: int) -> void:
	if event is InputEventMouseButton:
		var ev: InputEventMouseButton = event as InputEventMouseButton
		if ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_battle_manager.set_target_character_index(party_index)

func _deferred_refresh_hand() -> void:
	if not _hand_manager or not _refs.hand_container:
		return
	var hand: Array[Dictionary] = _deck_manager.get_hand()
	if hand.size() > 0:
		_hand_manager.set_hand_from_data(hand)
	call_deferred("_deferred_layout_hand")

func _deferred_layout_hand() -> void:
	if _hand_manager and _hand_manager.has_method("_update_fan_layout"):
		_hand_manager._update_fan_layout()

func _on_end_turn_hover(entered: bool) -> void:
	if not _refs.end_turn_btn:
		return
	_refs.end_turn_btn.modulate = Color(1.15, 1.15, 1.15) if entered else Color.WHITE
	var t := create_tween()
	if entered:
		t.tween_property(_refs.end_turn_btn, "scale", Vector2(1.05, 1.05), 0.1)
	else:
		t.tween_property(_refs.end_turn_btn, "scale", Vector2(1, 1), 0.1)

func _on_state_changed(state: Dictionary) -> void:
	var party: Array = state.get("party", [])
	var enemies: Array = state.get("enemies", [])
	var target_idx: int = state.get("target_character_index", 0) as int
	BattleUIPanels.refresh_party(_refs.party_list, party, target_idx)
	BattleUIPanels.refresh_enemy(_refs.enemy_name, _refs.enemy_hp, _refs.enemy_portrait, enemies)

func _on_energy_changed(energy: int, max_energy: int) -> void:
	if _refs.energy_display:
		_refs.energy_display.text = "Energy: %d / %d" % [energy, max_energy]
	if _hand_manager:
		_hand_manager.set_energy(energy)

func _on_enemy_intent_changed(intent_value: int, intent_type: String = "attack") -> void:
	if _refs.enemy_intent:
		if intent_type == "heal":
			_refs.enemy_intent.text = "Heal %d" % intent_value
		else:
			_refs.enemy_intent.text = "⚔ %d" % intent_value

func _on_hand_changed(hand: Array[Dictionary]) -> void:
	if _hand_manager:
		_hand_manager.set_hand_from_data(hand)
	call_deferred("_deferred_layout_hand")
	var am := _get_audio_manager()
	if am:
		am.draw_card()

func _on_deck_discard_changed(deck_size: int, discard_size: int) -> void:
	if _refs.deck_counter:
		_refs.deck_counter.text = str(deck_size)
	if _refs.discard_counter:
		_refs.discard_counter.text = str(discard_size)

func _refresh_initial_state() -> void:
	var state: Dictionary = _battle_manager.get_current_state()
	_on_state_changed(state)
	_on_energy_changed(state.get("energy", 0), state.get("max_energy", 4))
	var enemies: Array = state.get("enemies", [])
	if enemies.size() > 0:
		var e0: Dictionary = enemies[0]
		_on_enemy_intent_changed(e0.get("intent_value", 12) as int, e0.get("intent_type", "attack") as String)
	_on_deck_discard_changed(state.get("deck_size", 0), state.get("discard_size", 0))
	var hand: Array = state.get("hand", [])
	if _hand_manager and hand.size() > 0:
		_hand_manager.set_hand_from_data(hand)
	call_deferred("_deferred_layout_hand")

func _on_card_played_from_logic(card_data: Dictionary) -> void:
	var am := _get_audio_manager()
	if am:
		am.play_card()
	BattleUIPlayEffect.show_effect(_refs.play_effect, card_data)

func _on_battle_ended(result: String) -> void:
	BattleResult.set_result(result == "win")
	get_tree().change_scene_to_file(GAME_OVER_SCENE_PATH)

func _input(_event: InputEvent) -> void:
	pass
