class_name HandManager
extends Control
## Manages the player's hand: max 4 cards, dynamic spacing, fan layout.
## When drawing: if hand < 4 add card; if hand == 4 remove oldest then add new.
## Cards are repositioned with curved fan layout (-10° to +10°).

signal card_played(card_data: Dictionary)
signal hand_updated(hand: Array)

const MAX_HAND_SIZE: int = 4
const FAN_ANGLE_DEG: float = 10.0
const CARD_SPACING_RATIO: float = 0.85

var _hand: Array[Dictionary] = []
var _card_nodes: Array[Control] = []
var _hand_container: Control
var _card_scene: PackedScene
var _style_base: StyleBox
var _style_hover: StyleBox
var _style_drag: StyleBox
var _drag_system: Node
var _current_energy: int = 0

func _ready() -> void:
	pass

func setup(container: Control, card_scene: PackedScene, drag_system: Node, style_base: StyleBox, style_hover: StyleBox, style_drag: StyleBox) -> void:
	_hand_container = container
	_card_scene = card_scene
	_drag_system = drag_system
	_style_base = style_base
	_style_hover = style_hover
	_style_drag = style_drag
	if _hand_container:
		_hand_container.resized.connect(_on_container_resized)

func set_energy(amount: int) -> void:
	_current_energy = amount

## Add a card to hand. If hand already has 4, remove leftmost then add.
func add_card(card_data: Dictionary) -> void:
	if _hand.size() >= MAX_HAND_SIZE:
		_remove_card_at_index(0)
	_hand.append(card_data)
	_add_single_card_ui(card_data, _hand.size() - 1)
	hand_updated.emit(_hand.duplicate())

func remove_card(card_data: Dictionary) -> bool:
	var idx := _hand.find(card_data)
	if idx >= 0:
		_remove_card_at_index(idx)
		return true
	return false

func _add_single_card_ui(card_data: Dictionary, index: int) -> void:
	if not _hand_container or not _card_scene:
		return
	var card_ui: Control = _card_scene.instantiate()
	_hand_container.add_child(card_ui)
	if card_ui.has_method("setup"):
		card_ui.setup(card_data, index)
	if card_ui.has_method("set_styleboxes") and _style_base:
		card_ui.set_styleboxes(_style_base, _style_hover, _style_drag)
	if card_ui.has_signal("play_requested"):
		card_ui.play_requested.connect(_on_card_play_requested)
	if _drag_system and _drag_system.has_method("register_card"):
		_drag_system.register_card(card_ui)
	_card_nodes.append(card_ui)
	_update_fan_layout()

func _remove_card_at_index(idx: int) -> void:
	if idx < 0 or idx >= _hand.size():
		return
	_hand.remove_at(idx)
	if idx < _card_nodes.size():
		var node := _card_nodes[idx]
		_card_nodes.remove_at(idx)
		node.queue_free()
	_update_fan_layout()
	hand_updated.emit(_hand.duplicate())

func get_hand() -> Array:
	return _hand.duplicate()

func get_hand_size() -> int:
	return _hand.size()

func set_hand_from_data(hand_data: Array) -> void:
	_hand.clear()
	for d in hand_data:
		_hand.append(d.duplicate())
	_rebuild_hand_ui()
	hand_updated.emit(_hand.duplicate())

func _rebuild_hand_ui() -> void:
	if not _hand_container or not _card_scene:
		return
	for n in _card_nodes:
		n.queue_free()
	_card_nodes.clear()
	for i in range(_hand.size()):
		var card_ui: Control = _card_scene.instantiate()
		_hand_container.add_child(card_ui)
		if card_ui.has_method("setup"):
			card_ui.setup(_hand[i], i)
		if card_ui.has_method("set_styleboxes") and _style_base:
			card_ui.set_styleboxes(_style_base, _style_hover, _style_drag)
		if card_ui.has_signal("play_requested"):
			card_ui.play_requested.connect(_on_card_play_requested)
		if _drag_system and _drag_system.has_method("register_card"):
			_drag_system.register_card(card_ui)
		_card_nodes.append(card_ui)
	_update_fan_layout()

func _on_container_resized() -> void:
	_update_fan_layout()

func _update_fan_layout() -> void:
	var n := _card_nodes.size()
	if n == 0:
		return
	if not _hand_container:
		return
	var total_w: float = _hand_container.size.x
	if total_w <= 0.0:
		total_w = 480.0
	var total_h: float = _hand_container.size.y
	if total_h <= 0.0:
		total_h = 200.0
	var card_w: float = 140.0
	var card_h: float = 200.0
	var spacing: float = total_w / (n + 1)
	if spacing > card_w * CARD_SPACING_RATIO:
		spacing = card_w * CARD_SPACING_RATIO
	var start_x: float = (total_w - (n - 1) * spacing - card_w) / 2.0
	# Pin cards to the bottom of the hand area (clamp if container is shorter than card)
	var card_y: float = max(0.0, total_h - card_h)
	for i in range(n):
		var c: Control = _card_nodes[i]
		var angle: float = (float(i) - (n - 1) / 2.0) / max(1, (n - 1) / 2.0) * FAN_ANGLE_DEG if n > 1 else 0.0
		var x: float = start_x + i * spacing
		c.position = Vector2(x, card_y)
		c.rotation_degrees = angle
		var ch: float = card_h if c.size.y <= 0.0 else c.size.y
		c.pivot_offset = Vector2(card_w / 2.0, ch)
		c.set_as_top_level(false)

func _on_card_play_requested(card_data: Dictionary) -> void:
	card_played.emit(card_data)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _hand_container:
		_update_fan_layout()
