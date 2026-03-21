class_name HandManager
extends Control
## Manages the player's hand with dynamic spacing and fan layout.
## No hard hand-size cap; cards scale down to fit as the hand grows.

signal card_played(card_data: Dictionary)
signal hand_updated(hand: Array)
## Emitted when the hovered card in hand changes (card id string, or "" if none).
signal hand_hover_changed(card_id: String)

const FAN_ANGLE_DEG: float = 10.0
const CARD_SPACING_RATIO: float = 0.85
const MIN_CARD_SCALE: float = 0.55
const CARD_VERTICAL_LIFT: float = 14.0

var _hand: Array[Dictionary] = []
var _card_nodes: Array[Control] = []
var _hand_container: Control
var _card_scene: PackedScene
var _style_base: StyleBox
var _style_hover: StyleBox
var _style_drag: StyleBox
var _drag_system: Node
var _current_energy: int = 0
var _angry_hint_tweens: Array[Tween] = []
var _hovered_card_id: String = ""

func _ready() -> void:
	pass

func setup(container: Control, card_scene: PackedScene, drag_system: Node, style_base: StyleBox, style_hover: StyleBox, style_drag: StyleBox) -> void:
	if _hand_container and _hand_container.resized.is_connected(_on_container_resized):
		_hand_container.resized.disconnect(_on_container_resized)
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


func get_hovered_card_id() -> String:
	return _hovered_card_id


func get_dragging_card_id() -> String:
	if _drag_system and _drag_system.has_method("get_dragging_card_id"):
		return _drag_system.get_dragging_card_id() as String
	return ""


func _on_card_hover_changed(card_data: Dictionary, hovering: bool) -> void:
	var id: String = card_data.get("id", "") as String
	if hovering:
		_hovered_card_id = id
	else:
		if _hovered_card_id == id:
			_hovered_card_id = ""
	hand_hover_changed.emit(_hovered_card_id)

func add_card(card_data: Dictionary) -> void:
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
	if card_ui.has_signal("hover_changed"):
		card_ui.hover_changed.connect(_on_card_hover_changed)
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
	_hovered_card_id = ""
	hand_hover_changed.emit("")
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
		if card_ui.has_signal("hover_changed"):
			card_ui.hover_changed.connect(_on_card_hover_changed)
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

	var base_card_w: float = 140.0
	var base_card_h: float = 200.0
	if n > 0:
		var cm: Vector2 = _card_nodes[0].get_combined_minimum_size()
		base_card_w = maxf(base_card_w, cm.x)
		base_card_h = maxf(base_card_h, cm.y)

	var needed_w: float = base_card_w + maxf(n - 1, 0) * base_card_w * CARD_SPACING_RATIO
	var card_scale: float = 1.0
	if needed_w > total_w and n > 1:
		card_scale = clampf(total_w / needed_w, MIN_CARD_SCALE, 1.0)

	var card_w: float = base_card_w * card_scale

	var spacing: float = total_w / (n + 1)
	if spacing > card_w * CARD_SPACING_RATIO:
		spacing = card_w * CARD_SPACING_RATIO
	var start_x: float = (total_w - (n - 1) * spacing - card_w) / 2.0
	var card_y: float = total_h - base_card_h - CARD_VERTICAL_LIFT

	for i in range(n):
		var c: Control = _card_nodes[i]
		c.scale = Vector2(card_scale, card_scale)
		var angle: float = (float(i) - (n - 1) / 2.0) / max(1, (n - 1) / 2.0) * FAN_ANGLE_DEG if n > 1 else 0.0
		var x: float = start_x + i * spacing
		c.position = Vector2(x, card_y)
		c.rotation_degrees = angle
		c.pivot_offset = Vector2(base_card_w / 2.0, base_card_h)
		c.set_as_top_level(false)

func _on_card_play_requested(card_data: Dictionary) -> void:
	card_played.emit(card_data)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _hand_container:
		_update_fan_layout()


## Golden pulse on Get Angry, dim Angry Punch when you need to build Angry first.
func set_angry_combo_highlight(enabled: bool, hand_data: Array) -> void:
	_kill_angry_hint_tweens()
	for i in range(_card_nodes.size()):
		var node: Control = _card_nodes[i]
		var id: String = ""
		if i < hand_data.size():
			id = hand_data[i].get("id", "") as String
		if not enabled:
			node.modulate = Color.WHITE
			continue
		if id.begins_with("get_angry"):
			node.modulate = Color(1.12, 1.25, 1.02, 1.0)
			_pulse_angry_hint_modulate(node)
		elif id.begins_with("angry_punch"):
			node.modulate = Color(0.82, 0.84, 0.92, 1.0)
		else:
			node.modulate = Color.WHITE


func _pulse_angry_hint_modulate(node: Control) -> void:
	var tw := node.create_tween()
	tw.set_loops()
	tw.tween_property(node, "modulate", Color(1.28, 1.48, 1.12, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "modulate", Color(1.12, 1.25, 1.02, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_angry_hint_tweens.append(tw)


func _kill_angry_hint_tweens() -> void:
	for t in _angry_hint_tweens:
		if t != null and is_instance_valid(t):
			t.kill()
	_angry_hint_tweens.clear()
