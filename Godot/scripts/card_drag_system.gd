class_name CardDragSystem
extends Node
## Handles card drag: follow cursor, scale/glow while dragging.
## Release inside drop_zone = play card; release outside = return card to hand.

signal card_drag_ended(card_ui: Control, play_requested: bool)

const DRAG_SCALE: float = 1.12
const DRAG_START_DISTANCE_PX: float = 10.0

## While dragging, keep the card inside valid UI regions (hand + play zone)
## so it can't visually overlap party list / enemy panel.
const CLAMP_DRAG_TO_HAND_OR_PLAY: bool = true

var _registered_cards: Array[Control] = []
var _dragging_card: Control = null
var _drag_visual_started: bool = false
var _drag_start_pos: Vector2
var _drag_start_global: Vector2
var _drag_start_mouse: Vector2
var _hand_container: Control
var _root_for_drag: CanvasLayer
var _drop_zone: Control = null
var _over_drop_zone: bool = false

func _closest_point_on_rect(r: Rect2, p: Vector2) -> Vector2:
	return Vector2(
		clamp(p.x, r.position.x, r.end.x),
		clamp(p.y, r.position.y, r.end.y)
	)

func _ready() -> void:
	pass

func setup(hand_container: Control, root_for_drag: CanvasLayer, drop_zone: Control = null) -> void:
	_hand_container = hand_container
	_root_for_drag = root_for_drag
	_drop_zone = drop_zone


## Play zone modulate is applied only to PlayZoneFill so labels (TargetPrompt, PlayEffect) stay full brightness.
func _play_zone_modulate_target() -> CanvasItem:
	if _drop_zone == null or not _drop_zone.is_inside_tree():
		return null
	var fill := _drop_zone.get_node_or_null("PlayZoneFill") as CanvasItem
	return fill if fill else _drop_zone as CanvasItem

func get_dragging_card_id() -> String:
	if _dragging_card == null or not is_instance_valid(_dragging_card):
		return ""
	var cd: Variant = _dragging_card.get("card_data")
	if typeof(cd) != TYPE_DICTIONARY:
		return ""
	return (cd as Dictionary).get("id", "") as String


func register_card(card_ui: Control) -> void:
	if card_ui in _registered_cards:
		return
	_registered_cards.append(card_ui)
	if card_ui.gui_input.get_connections().size() == 0:
		card_ui.gui_input.connect(_on_card_gui_input.bind(card_ui))

func _input(event: InputEvent) -> void:
	# Detect release globally: once the card is on the drag layer, the control under
	# the cursor (e.g. drop zone) gets the release, not the card. So we listen here.
	if _dragging_card == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_end_drag(_dragging_card)
			var vp := get_viewport()
			if vp == null and _root_for_drag:
				vp = _root_for_drag.get_viewport()
			if vp:
				vp.set_input_as_handled()

func _on_card_gui_input(event: InputEvent, card_ui: Control) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			# Arm a potential drag; only start visual dragging after the mouse moves enough.
			_dragging_card = card_ui
			_drag_visual_started = false
			_drag_start_global = card_ui.get_global_rect().position
			_drag_start_pos = card_ui.position
			_drag_start_mouse = get_viewport().get_mouse_position()
		# Release is always handled in _input() so we get it over drop zone or card

func _start_drag(card_ui: Control) -> void:
	_drag_visual_started = true
	_dragging_card = card_ui
	_drag_start_global = card_ui.get_global_rect().position
	_drag_start_pos = card_ui.position
	card_ui.pivot_offset = card_ui.size / 2.0
	if _root_for_drag:
		var old_parent := card_ui.get_parent()
		old_parent.remove_child(card_ui)
		_root_for_drag.add_child(card_ui)
		var vp := _root_for_drag.get_viewport()
		if vp:
			card_ui.position = vp.get_mouse_position() - card_ui.pivot_offset
		card_ui.set_as_top_level(true)
	if card_ui.has_method("set_drag_state"):
		card_ui.set_drag_state(true)

func _end_drag(card_ui: Control) -> void:
	if _dragging_card != card_ui:
		return
	# Play only if released inside the drop zone (e.g. enemy panel); otherwise return to hand.
	var mouse_pos: Vector2 = _root_for_drag.get_viewport().get_mouse_position() if _root_for_drag else Vector2.ZERO
	var play: bool = false
	# If we never started the visual drag, treat it as a click (no play-through).
	if _drag_visual_started and _drop_zone and _drop_zone.is_inside_tree():
		play = _drop_zone.get_global_rect().has_point(mouse_pos)
	if _root_for_drag and card_ui.get_parent() == _root_for_drag:
		_root_for_drag.remove_child(card_ui)
		_hand_container.add_child(card_ui)
		card_ui.set_as_top_level(false)
	if _drag_visual_started and card_ui.has_method("set_drag_state"):
		card_ui.set_drag_state(false)
	_dragging_card = null
	_drag_visual_started = false
	card_drag_ended.emit(card_ui, play)

	# Reset drop zone highlight when drag ends (fill only — not whole subtree)
	if _drop_zone and _drop_zone.is_inside_tree() and _drop_zone.name == "PlayZone":
		_drop_zone.modulate = Color.WHITE
		var tgt := _play_zone_modulate_target()
		if tgt:
			tgt.modulate = Color(1, 1, 1, 0.18)

func _process(_delta: float) -> void:
	if _dragging_card and _root_for_drag:
		# Start the actual visual drag only after moving far enough.
		if not _drag_visual_started:
			var mouse_start_pos := _root_for_drag.get_viewport().get_mouse_position()
			if mouse_start_pos.distance_to(_drag_start_mouse) < DRAG_START_DISTANCE_PX:
				return
			_start_drag(_dragging_card)

		var mouse_pos := _root_for_drag.get_viewport().get_mouse_position()
		var desired := mouse_pos - _dragging_card.pivot_offset

		if CLAMP_DRAG_TO_HAND_OR_PLAY:
			# Only allow the dragged card center to be over HandContainer or PlayZone.
			# (We clamp the visual position; play detection still depends on the real mouse position.)
			var hand_rect: Rect2 = _hand_container.get_global_rect() if _hand_container else Rect2()
			var play_rect: Rect2 = _drop_zone.get_global_rect() if _drop_zone else Rect2()

			var inside_hand: bool = _hand_container and hand_rect.has_point(mouse_pos)
			var inside_play: bool = _drop_zone and play_rect.has_point(mouse_pos)
			if not (inside_hand or inside_play):
				# If outside both, snap the card back toward the nearest allowed rectangle edge.
				var hp: Vector2 = _closest_point_on_rect(hand_rect, mouse_pos)
				var pp: Vector2 = _closest_point_on_rect(play_rect, mouse_pos)
				# If one rect is missing/zero, fall back to the other.
				if _hand_container and (not _drop_zone or play_rect.size == Vector2.ZERO):
					desired = hp - _dragging_card.pivot_offset
				elif _drop_zone and (not _hand_container or hand_rect.size == Vector2.ZERO):
					desired = pp - _dragging_card.pivot_offset
				else:
					var dh: float = hp.distance_squared_to(mouse_pos)
					var dp: float = pp.distance_squared_to(mouse_pos)
					desired = (hp if dh <= dp else pp) - _dragging_card.pivot_offset

		# Highlight the play zone when hovered (tint fill only)
		if _drop_zone and _drop_zone.is_inside_tree() and _drop_zone.name == "PlayZone":
			var inside := _drop_zone.get_global_rect().has_point(mouse_pos)
			if inside != _over_drop_zone:
				_over_drop_zone = inside
				_drop_zone.modulate = Color.WHITE
				var ci := _play_zone_modulate_target()
				if ci:
					if inside:
						ci.modulate = Color(1, 1, 1, 0.55)
					else:
						ci.modulate = Color(1, 1, 1, 0.18)

		_dragging_card.position = desired
