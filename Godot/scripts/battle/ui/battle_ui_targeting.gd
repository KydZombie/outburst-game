extends RefCounted
class_name BattleUITargeting
## Handles target-selection flow, prompt visibility, and party hover highlighting.

var _owner: Control
var _refs: BattleUINodeRefs
var _input_controller: InputController
var _target_selection_active: bool = false
var _pending_target_skill_card_data: Dictionary = {}
var _last_hovered_party_index: int = -999
var _party_hovered_index: int = -1
var _prompt_tween: Tween
var _party_pulse_tween: Tween
var _left_panel_default_style: StyleBox
var _left_panel_glow_style: StyleBoxFlat
## Called when TargetPrompt is shown/hidden so play-zone hints can stay in sync.
var _on_target_prompt_changed: Callable = Callable()

func setup(owner: Control, refs: BattleUINodeRefs, input_controller: InputController, on_target_prompt_changed: Callable = Callable()) -> void:
	_owner = owner
	_refs = refs
	_input_controller = input_controller
	_on_target_prompt_changed = on_target_prompt_changed


func is_awaiting_party_target_for_skill() -> bool:
	return not _pending_target_skill_card_data.is_empty()


func begin_target_skill_from_hotkey(card_data: Dictionary, last_state: Dictionary) -> void:
	_pending_target_skill_card_data = card_data.duplicate()
	_target_selection_active = true
	_enter_target_skill_mode()
	_show_target_prompt(card_data)
	if not last_state.is_empty():
		var party: Array = last_state.get("party", [])
		var idx: int = _get_hovered_party_index()
		BattleUIPanels.refresh_party(_refs.party_list, party, idx)
		_last_hovered_party_index = idx


func confirm_party_target_at_index(party_index: int, battle_manager: BattleManager, last_state: Dictionary) -> bool:
	if _pending_target_skill_card_data.is_empty():
		return false
	var party: Array = last_state.get("party", [])
	if party_index < 0 or party_index >= party.size():
		return false
	var p: Dictionary = party[party_index]
	if (p.get("hp", 0) as int) <= 0:
		return false
	battle_manager.set_target_character_index(party_index)
	return battle_manager.request_play_card(_pending_target_skill_card_data)


func cancel_target_skill_if_active(last_state: Dictionary) -> bool:
	if _pending_target_skill_card_data.is_empty() and not _target_selection_active:
		return false
	_abort_target_skill_flow(last_state)
	return true


func _enter_target_skill_mode() -> void:
	if _input_controller:
		_input_controller.set_block_card_slot_hotkeys(true)
		_input_controller.set_party_target_mode(true)


func _exit_target_skill_mode() -> void:
	if _input_controller:
		_input_controller.set_block_card_slot_hotkeys(false)
		_input_controller.set_party_target_mode(false)


func _abort_target_skill_flow(last_state: Dictionary) -> void:
	_pending_target_skill_card_data = {}
	_target_selection_active = false
	_exit_target_skill_mode()
	_hide_target_prompt()
	if not last_state.is_empty() and _refs.party_list:
		BattleUIPanels.refresh_party(_refs.party_list, last_state.get("party", []), -1)

func current_highlight_index() -> int:
	return _get_hovered_party_index() if _target_selection_active else -1

func on_party_row_hovered(party_index: int, entered: bool, last_state: Dictionary) -> void:
	if entered:
		_party_hovered_index = party_index
	elif _party_hovered_index == party_index:
		_party_hovered_index = -1

	if not _target_selection_active or last_state.is_empty():
		return
	var party: Array = last_state.get("party", [])
	var highlight_idx: int = _party_hovered_index if _party_hovered_index >= 0 else -1
	BattleUIPanels.refresh_party(_refs.party_list, party, highlight_idx)
	_last_hovered_party_index = highlight_idx

func on_party_row_gui_input(event: InputEvent, party_index: int, battle_manager: BattleManager, last_state: Dictionary) -> void:
	if not (event is InputEventMouseButton):
		return
	var ev: InputEventMouseButton = event as InputEventMouseButton
	if not (ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	if not _target_selection_active:
		return
	if not _pending_target_skill_card_data.is_empty():
		confirm_party_target_at_index(party_index, battle_manager, last_state)
	else:
		battle_manager.set_target_character_index(party_index)

func on_drag_ended(
	card_ui: Control,
	play_requested: bool,
	hand_manager: HandManager,
	battle_manager: BattleManager,
	last_state: Dictionary
) -> void:
	var cd: Variant = card_ui.get("card_data")
	if not (cd is Dictionary):
		if hand_manager and hand_manager.has_method("_update_fan_layout"):
			hand_manager._update_fan_layout()
		return
	var card_data: Dictionary = cd as Dictionary
	if _is_target_skill(card_data):
		_pending_target_skill_card_data = card_data.duplicate()
		_target_selection_active = true
		_enter_target_skill_mode()
		_show_target_prompt(card_data)
		if not last_state.is_empty():
			var party: Array = last_state.get("party", [])
			var idx: int = _get_hovered_party_index()
			BattleUIPanels.refresh_party(_refs.party_list, party, idx)
			_last_hovered_party_index = idx
		return
	if play_requested:
		battle_manager.request_play_card(card_data)
	elif hand_manager and hand_manager.has_method("_update_fan_layout"):
		hand_manager._update_fan_layout()

func on_process(last_state: Dictionary) -> void:
	if not _pending_target_skill_card_data.is_empty():
		if not _target_selection_active:
			_target_selection_active = true
		if not last_state.is_empty():
			var party_idx: int = _get_hovered_party_index()
			if party_idx != _last_hovered_party_index:
				BattleUIPanels.refresh_party(_refs.party_list, last_state.get("party", []), party_idx)
				_last_hovered_party_index = party_idx
		return

	var vp_proc := _owner.get_viewport()
	if vp_proc == null:
		return
	var hovered_control: Control = vp_proc.gui_get_hovered_control()
	var hovered_card_data: Dictionary = _get_hovered_card_data()
	if hovered_card_data.is_empty():
		if _target_selection_active and _refs.party_list:
			var party_idx: int = _get_hovered_party_index()
			if party_idx != _last_hovered_party_index and not last_state.is_empty():
				BattleUIPanels.refresh_party(_refs.party_list, last_state.get("party", []), party_idx)
				_last_hovered_party_index = party_idx
		var is_over_party_list := _refs.party_list and hovered_control and _refs.party_list.is_ancestor_of(hovered_control)
		if _target_selection_active and not is_over_party_list:
			_abort_target_skill_flow(last_state)
			_last_hovered_party_index = -999
		return

	var new_active: bool = _compute_target_selection_active(hovered_card_data)
	if new_active == _target_selection_active:
		return
	_target_selection_active = new_active
	if _target_selection_active:
		_show_target_prompt(hovered_card_data)
	else:
		_hide_target_prompt()
	if not last_state.is_empty():
		var idx: int = _get_hovered_party_index() if _target_selection_active else -1
		BattleUIPanels.refresh_party(_refs.party_list, last_state.get("party", []), idx)
		_last_hovered_party_index = idx

func on_card_played(last_state: Dictionary) -> void:
	_target_selection_active = false
	_pending_target_skill_card_data = {}
	_exit_target_skill_mode()
	_hide_target_prompt()
	if not last_state.is_empty():
		BattleUIPanels.refresh_party(_refs.party_list, last_state.get("party", []), -1)

func _get_hovered_party_index() -> int:
	if _party_hovered_index >= 0:
		return _party_hovered_index
	if not (_refs and _refs.party_list):
		return -1
	var vp_party := _owner.get_viewport()
	if vp_party == null:
		return -1
	var hovered: Control = vp_party.gui_get_hovered_control()
	if not hovered:
		return -1
	for i in range(_refs.party_list.get_child_count()):
		var row := _refs.party_list.get_child(i)
		if row and (row as Node).is_ancestor_of(hovered):
			return i
	return -1

func _get_hovered_card_data() -> Dictionary:
	var vp_card := _owner.get_viewport()
	if vp_card == null:
		return {}
	var hovered: Control = vp_card.gui_get_hovered_control()
	if hovered == null:
		return {}
	var cur: Node = hovered
	while cur:
		var d: Variant = cur.get("card_data")
		if d is Dictionary:
			return d
		cur = cur.get_parent()
	return {}

func _compute_target_selection_active(cd: Dictionary) -> bool:
	var requires_target: bool = cd.get("requires_target", false) as bool
	if not requires_target:
		return false
	return (cd.get("type", "") as String) == "SKILL"

func _is_target_skill(card_data: Dictionary) -> bool:
	var needs_target: bool = card_data.get("requires_target", false) as bool
	return needs_target and (card_data.get("type", "") as String) == "SKILL"

func _ensure_left_panel_styles() -> void:
	if _left_panel_glow_style or not _refs.left_panel:
		return
	_left_panel_default_style = _refs.left_panel.get("theme_override_styles/panel") as StyleBox
	var sb: StyleBoxFlat
	if _left_panel_default_style and _left_panel_default_style is StyleBoxFlat:
		sb = (_left_panel_default_style as StyleBoxFlat).duplicate() as StyleBoxFlat
	else:
		sb = StyleBoxFlat.new()
		sb.content_margin_left = 16.0
		sb.content_margin_top = 12.0
		sb.content_margin_right = 16.0
		sb.content_margin_bottom = 12.0
		sb.bg_color = Color(0.071, 0.094, 0.176, 1)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.corner_radius_top_left = 12
		sb.corner_radius_top_right = 12
		sb.corner_radius_bottom_right = 12
		sb.corner_radius_bottom_left = 12
		sb.shadow_color = Color(0, 0, 0, 0.3)
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 2)
	sb.border_color = Color(1, 1, 1, 0.85)
	sb.shadow_color = Color(1, 1, 1, 0.42)
	sb.expand_margin_left = 4.0
	sb.expand_margin_top = 4.0
	sb.expand_margin_right = 4.0
	sb.expand_margin_bottom = 4.0
	_left_panel_glow_style = sb

func _card_target_description(card_data: Dictionary) -> String:
	var card_id: String = card_data.get("id", "") as String
	var main: String
	if card_id.begins_with("cheer_up"):
		main = "SELECT AN ALLY TO CLEAR ANGRY & SAD, ADD +2 HAPPY"
	elif card_id.begins_with("get_angry"):
		main = "SELECT AN ALLY TO ADD +2 ANGRY"
	else:
		var desc: String = card_data.get("description", "") as String
		if desc != "":
			main = "SELECT AN ALLY — %s" % desc.to_upper()
		else:
			main = "SELECT AN ALLY"
	var title: String = card_data.get("title", "") as String
	if title != "":
		return "%s\n[%s]" % [main, title.to_upper()]
	return main

func _show_target_prompt(card_data: Dictionary = {}) -> void:
	if _refs.target_prompt:
		_refs.target_prompt.text = _card_target_description(card_data)
		var tip_title: String = card_data.get("title", "") as String
		var tip_desc: String = card_data.get("description", "") as String
		if tip_title != "" and tip_desc != "":
			_refs.target_prompt.tooltip_text = "%s\n%s" % [tip_title, tip_desc]
		elif tip_desc != "":
			_refs.target_prompt.tooltip_text = tip_desc
		else:
			_refs.target_prompt.tooltip_text = tip_title
		if _refs.target_prompt is Label:
			(_refs.target_prompt as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_refs.target_prompt.visible = true
		_refs.target_prompt.modulate = Color(1, 1, 1, 1)
		if _prompt_tween and _prompt_tween.is_valid():
			_prompt_tween.kill()
		_prompt_tween = null
	if _on_target_prompt_changed.is_valid():
		_on_target_prompt_changed.call()
	_ensure_left_panel_styles()
	if _refs.left_panel and _left_panel_glow_style:
		_refs.left_panel.set("theme_override_styles/panel", _left_panel_glow_style)
	_start_party_pulse()

func _hide_target_prompt() -> void:
	if _refs.target_prompt:
		_refs.target_prompt.visible = false
		_refs.target_prompt.tooltip_text = ""
	if _prompt_tween and _prompt_tween.is_valid():
		_prompt_tween.kill()
		_prompt_tween = null
	if _refs.left_panel:
		_refs.left_panel.set("theme_override_styles/panel", _left_panel_default_style)
	_stop_party_pulse()
	if _on_target_prompt_changed.is_valid():
		_on_target_prompt_changed.call()

func _start_party_pulse() -> void:
	if not _refs.party_list:
		return
	if _party_pulse_tween and _party_pulse_tween.is_valid():
		_party_pulse_tween.kill()
	_party_pulse_tween = _owner.create_tween().set_loops()
	var bright := Color(1.18, 1.18, 1.22, 1.0)
	var dim := Color(0.96, 0.96, 0.98, 1.0)
	_party_pulse_tween.tween_property(_refs.party_list, "modulate", bright, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_party_pulse_tween.tween_property(_refs.party_list, "modulate", dim, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_party_pulse() -> void:
	if _party_pulse_tween and _party_pulse_tween.is_valid():
		_party_pulse_tween.kill()
		_party_pulse_tween = null
	if _refs.party_list:
		_refs.party_list.modulate = Color.WHITE
