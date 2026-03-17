class_name CardDragSystem
extends Node
## Handles card drag: follow cursor, scale/glow while dragging.
## Release inside drop_zone = play card; release outside = return card to hand.

signal card_drag_ended(card_ui: Control, play_requested: bool)

const DRAG_SCALE: float = 1.12

var _registered_cards: Array[Control] = []
var _dragging_card: Control = null
var _drag_start_pos: Vector2
var _drag_start_global: Vector2
var _hand_container: Control
var _root_for_drag: CanvasLayer
var _drop_zone: Control = null
var _over_drop_zone: bool = false

func _ready() -> void:
	pass

func setup(hand_container: Control, root_for_drag: CanvasLayer, drop_zone: Control = null) -> void:
	_hand_container = hand_container
	_root_for_drag = root_for_drag
	_drop_zone = drop_zone

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
			get_viewport().set_input_as_handled()

func _on_card_gui_input(event: InputEvent, card_ui: Control) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_start_drag(card_ui)
		# Release is always handled in _input() so we get it over drop zone or card

func _start_drag(card_ui: Control) -> void:
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
	if _drop_zone and _drop_zone.is_inside_tree():
		play = _drop_zone.get_global_rect().has_point(mouse_pos)
	if _root_for_drag and card_ui.get_parent() == _root_for_drag:
		_root_for_drag.remove_child(card_ui)
		_hand_container.add_child(card_ui)
		card_ui.set_as_top_level(false)
	if card_ui.has_method("set_drag_state"):
		card_ui.set_drag_state(false)
	_dragging_card = null
	card_drag_ended.emit(card_ui, play)

	# Reset drop zone highlight when drag ends
	if _drop_zone and _drop_zone.is_inside_tree() and _drop_zone.name == "PlayZone":
		var ci := _drop_zone as CanvasItem
		ci.modulate = Color(1, 1, 1, 0.18)

func _process(_delta: float) -> void:
	if _dragging_card and _root_for_drag:
		var mouse := _root_for_drag.get_viewport().get_mouse_position()
		var desired := mouse - _dragging_card.pivot_offset

		# Highlight the play zone when hovered
		if _drop_zone and _drop_zone.is_inside_tree() and _drop_zone.name == "PlayZone":
			var inside := _drop_zone.get_global_rect().has_point(mouse)
			if inside != _over_drop_zone:
				_over_drop_zone = inside
				var ci := _drop_zone as CanvasItem
				if inside:
					ci.modulate = Color(1, 1, 1, 0.55)
				else:
					ci.modulate = Color(1, 1, 1, 0.18)

		_dragging_card.position = desired
