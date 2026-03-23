extends Control
class_name BattleUIManager
## Thin coordinator: wires node refs, systems, and UI helper modules.

const CARD_SCENE := preload("res://scenes/card_ui.tscn")
const CARD_STYLE_BASE := preload("res://resources/card_base_stylebox.tres")
const CARD_STYLE_HOVER := preload("res://resources/card_hover_stylebox.tres")
const CARD_STYLE_DRAG := preload("res://resources/card_drag_stylebox.tres")
const GAME_OVER_SCENE_PATH := "res://scenes/game_over_scene.tscn"
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const _TargetingScript := preload("res://scripts/battle/ui/battle_ui_targeting.gd")
const _RuntimeScript := preload("res://scripts/battle/ui/battle_ui_runtime.gd")
const _NinePatch := preload("res://scripts/ui/nine_patch_frame.gd")

var _refs: BattleUINodeRefs
var _hand_manager: HandManager
var _drag_system: CardDragSystem
var _battle_manager: BattleManager
var _deck_manager: DeckManager
var _last_state: Dictionary = {}
var _targeting: RefCounted
var _runtime: RefCounted

func _ready() -> void:
	_refs = BattleUINodeRefs.new()
	_refs.find_from(self)
	BattleHintTheme.apply_play_zone_label(_refs.target_prompt)
	BattleHintTheme.apply_play_zone_richtext(_refs.angry_combo_hint)
	BattleHintTheme.apply_controls_hint(_refs.controls_label)
	BattleUIPortraits.apply_nine_patch_to_party_rows(_refs.party_list)
	_NinePatch.apply_to_button(_refs.draw_card_btn)
	_NinePatch.apply_to_button(_refs.end_turn_btn)
	_NinePatch.apply_to_panel(_refs.energy_box)
	if _refs.deck_counter_panel and _refs.deck_counter_panel is PanelContainer:
		_NinePatch.apply_to_compact_panel(_refs.deck_counter_panel as PanelContainer)
	if _refs.discard_counter_panel and _refs.discard_counter_panel is PanelContainer:
		_NinePatch.apply_to_compact_panel(_refs.discard_counter_panel as PanelContainer)
	_battle_manager = BattleManager.new()
	add_child(_battle_manager)
	_deck_manager = _battle_manager.deck_manager

	_hand_manager = HandManager.new()
	add_child(_hand_manager)
	_drag_system = CardDragSystem.new()
	add_child(_drag_system)
	if _refs.drag_layer and _refs.hand_container:
		var drop_area: Control = _refs.play_zone if _refs.play_zone else _refs.right_panel
		_drag_system.setup(_refs.hand_container, _refs.drag_layer, drop_area)
	if _refs.hand_container:
		_hand_manager.setup(_refs.hand_container, CARD_SCENE, _drag_system, CARD_STYLE_BASE, CARD_STYLE_HOVER, CARD_STYLE_DRAG)
	_hand_manager.card_played.connect(func(card_data: Dictionary) -> void: _battle_manager.request_play_card(card_data))
	_hand_manager.hand_hover_changed.connect(func(_card_id: String) -> void:
		if _runtime:
			_runtime.refresh_angry_combo_play_zone_hint()
	)
	_drag_system.card_drag_ended.connect(func(card_ui: Control, play_requested: bool) -> void:
		_targeting.on_drag_ended(card_ui, play_requested, _hand_manager, _battle_manager, _last_state)
		if _runtime:
			_runtime.refresh_angry_combo_play_zone_hint()
	)

	_targeting = _TargetingScript.new()
	_runtime = _RuntimeScript.new()
	_runtime.setup(self, _refs, _hand_manager, _battle_manager, _deck_manager, GAME_OVER_SCENE_PATH)
	_targeting.setup(
		self, _refs, _battle_manager.input_controller,
		func() -> void: _runtime.refresh_angry_combo_play_zone_hint(),
		func(party_index: int) -> void: _runtime.on_dead_member_selection_attempted(party_index)
	)
	_battle_manager.target_skill_hotkey_needs_party.connect(func(card: Dictionary) -> void:
		_last_state = _battle_manager.get_current_state()
		_targeting.begin_target_skill_from_hotkey(card, _last_state)
	)
	_battle_manager.input_controller.party_target_pressed.connect(_on_party_target_key)
	_battle_manager.input_controller.main_menu_requested.connect(func() -> void:
		var tree := get_tree()
		if tree:
			tree.change_scene_to_file(MAIN_MENU_PATH)
	)

	if _refs.end_turn_btn:
		_refs.end_turn_btn.pressed.connect(func() -> void: _battle_manager._on_end_turn_requested())
		_refs.end_turn_btn.mouse_entered.connect(func() -> void: _runtime.on_end_turn_hover(true))
		_refs.end_turn_btn.mouse_exited.connect(func() -> void: _runtime.on_end_turn_hover(false))
	if _refs.draw_card_btn:
		_refs.draw_card_btn.pressed.connect(func() -> void: _battle_manager._on_draw_requested())
		_refs.draw_card_btn.mouse_entered.connect(func() -> void: _refs.draw_card_btn.scale = Vector2(1.03, 1.03))
		_refs.draw_card_btn.mouse_exited.connect(func() -> void: _refs.draw_card_btn.scale = Vector2(1, 1))

	_battle_manager.state_changed.connect(func(state: Dictionary) -> void:
		_last_state = state
		_runtime.on_state_changed(state, _targeting.current_highlight_index())
	)
	_battle_manager.energy_changed.connect(_runtime.on_energy_changed)
	_battle_manager.enemy_intent_changed.connect(_runtime.on_enemy_intent_changed)
	_battle_manager.card_effect_for_ui.connect(func(card_data: Dictionary) -> void:
		_targeting.on_card_played(_last_state)
		_runtime.on_card_played_from_logic(card_data)
	)
	_battle_manager.battle_ended.connect(_runtime.on_battle_ended)
	_battle_manager.enemy_attacked.connect(func(idx: int, dmg: int) -> void: _runtime.on_enemy_attack(idx, dmg))
	_battle_manager.party_member_died.connect(func(idx: int) -> void: _runtime.on_party_member_died(idx))
	_battle_manager.enemy_hit.connect(func(dmg: int) -> void: _runtime.on_enemy_hit(dmg))
	_battle_manager.target_character_changed.connect(func(_i: int) -> void:
		_last_state = _runtime.refresh_initial_state()
	)
	_battle_manager.ally_buffed.connect(func(idx: int, cd: Dictionary) -> void: _runtime.on_ally_buffed(idx, cd))
	_battle_manager.player_turn_ready.connect(func(t: int) -> void: _runtime.on_player_turn_ready(t))
	_battle_manager.enemy_turn_started.connect(func() -> void: _runtime.on_enemy_turn_started())
	_battle_manager.turn_auto_skipped.connect(func(reason: String) -> void: _runtime.on_turn_auto_skipped(reason))
	_battle_manager.enemy_heal_action.connect(func(amount: int) -> void: _runtime.on_enemy_healed(amount))
	_deck_manager.hand_changed.connect(_runtime.on_hand_changed)
	_deck_manager.deck_discard_changed.connect(_runtime.on_deck_discard_changed)
	_deck_manager.deck_reshuffled.connect(func() -> void: _runtime.on_deck_reshuffled())

	if _refs.party_list:
		for i in range(_refs.party_list.get_child_count()):
			var row: Control = _refs.party_list.get_child(i) as Control
			if row:
				var idx: int = i
				row.mouse_filter = Control.MOUSE_FILTER_STOP
				row.gui_input.connect(func(event: InputEvent) -> void:
					_targeting.on_party_row_gui_input(event, idx, _battle_manager, _last_state)
				)
				row.mouse_entered.connect(func() -> void: _targeting.on_party_row_hovered(idx, true, _last_state))
				row.mouse_exited.connect(func() -> void: _targeting.on_party_row_hovered(idx, false, _last_state))

	if _refs.deck_counter_panel:
		_make_panel_receive_clicks(_refs.deck_counter_panel)
		_refs.deck_counter_panel.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				_runtime.show_deck_list_popup()
		)
	if _refs.discard_counter_panel:
		_make_panel_receive_clicks(_refs.discard_counter_panel)
		_refs.discard_counter_panel.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				_runtime.show_discard_list_popup()
		)

	_last_state = _runtime.refresh_initial_state()
	call_deferred("_deferred_refresh_hand")

func transition_to_game_over(scene_path: String) -> void:
	if scene_path.is_empty():
		scene_path = GAME_OVER_SCENE_PATH
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(scene_path)

func _deferred_refresh_hand() -> void:
	_runtime.deferred_refresh_hand()

func _process(_delta: float) -> void:
	_targeting.on_process(_last_state)


func _on_party_target_key(slot: int) -> void:
	_targeting.confirm_party_target_at_index(slot, _battle_manager, _last_state)


## Deck/discard panels contain Labels that steal clicks; ignore mouse on children so the panel gets gui_input.
func _make_panel_receive_clicks(panel: Control) -> void:
	if not panel:
		return
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	for c in panel.get_children():
		_set_mouse_ignore_recursive(c)

func _set_mouse_ignore_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in node.get_children():
		_set_mouse_ignore_recursive(c)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var ek := event as InputEventKey
		if ek.physical_keycode == KEY_ESCAPE:
			if _targeting.cancel_target_skill_if_active(_last_state):
				var vp := get_viewport()
				if vp:
					vp.set_input_as_handled()
