extends PanelContainer
## Single playable card (this scene only — hand/battle instantiate `card_ui.tscn`).
## Tutorial / how-to-play UI is a separate scene: `res://scenes/settings_scene.tscn` (opened from main menu).
## Do not add tutorial or full-screen menu nodes under CardUI; keep this scene small for the hand layout.
## Cost, title, icon, description, background glow.
## States: base, hover (scale 1.08, raise, glow), drag (scale, glow).
## NOTE: “Play card” is handled by `CardDragSystem` -> `BattleUIManager`
## (CardUI only displays/animates the card).

@export var card_data: Dictionary = {}
@export var hotkey_index: int = -1

@onready var index_label: Label = $VBox/Index
@onready var name_label: Label = $VBox/Name
@onready var desc_label: Label = $VBox/Desc
@onready var cost_label: Label = $VBox/CostBox/Cost
@onready var icon_label: Label = $VBox/IconArea/IconLabel
@onready var target_badge: Label = $VBox/TargetBadge

signal hover_changed(card_data: Dictionary, hovering: bool)

const HOVER_SCALE: float = 1.08
const HOVER_RAISE: float = -24.0
const ANIM_SPEED: float = 12.0

var _style_base: StyleBox
var _style_hover: StyleBox
var _style_drag: StyleBox
var _is_hovered: bool = false
var _is_dragging: bool = false
var _base_position: Vector2
var _target_scale: float = 1.0
var _target_offset_y: float = 0.0

func _ready() -> void:
	_update_display()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_base_position = position
	if icon_label:
		_update_icon()
	connect("mouse_entered", _on_mouse_entered)

func _get_audio_manager() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var root: Window = tree.get_root()
	if root == null:
		return null
	return root.get_node_or_null("BattleScene/AudioManager")

func setup(data: Dictionary, index: int) -> void:
	card_data = data
	hotkey_index = index
	_update_display()
	_update_icon()

func set_styleboxes(base_sb: StyleBox, hover_sb: StyleBox, drag_sb: StyleBox) -> void:
	_style_base = base_sb
	_style_hover = hover_sb
	_style_drag = drag_sb
	_apply_style()

func set_drag_state(dragging: bool) -> void:
	_is_dragging = dragging
	_apply_style()
	if dragging:
		_target_scale = 1.12
		_target_offset_y = 0.0
	else:
		_target_scale = 1.0
		_target_offset_y = 0.0

func _apply_style() -> void:
	if _is_dragging and _style_drag:
		add_theme_stylebox_override("panel", _style_drag)
	elif _is_hovered and _style_hover:
		add_theme_stylebox_override("panel", _style_hover)
	elif _style_base:
		add_theme_stylebox_override("panel", _style_base)

func _on_mouse_entered() -> void:
	var am := _get_audio_manager()
	if am and am.has_method("hover_card"):
		am.hover_card()

func _update_display() -> void:
	if not is_node_ready():
		return
	if card_data.is_empty():
		return
	if index_label:
		index_label.text = "[%d]" % (hotkey_index + 1) if hotkey_index >= 0 else ""
	if name_label:
		var title_val: String = card_data.get("title", "") as String
		name_label.text = title_val.to_upper()
	if desc_label:
		var desc_val: String = card_data.get("description", "") as String
		desc_label.text = desc_val
	if cost_label:
		var cost_val: int = card_data.get("cost", 0) as int
		cost_label.text = "Free" if cost_val == 0 else str(cost_val)

func _update_icon() -> void:
	if not icon_label:
		return
	var ctype: String = card_data.get("type", "ATTACK") as String
	match ctype:
		"ATTACK":
			icon_label.text = "⚔"
		"SKILL":
			icon_label.text = "🛡"
		"POWER":
			icon_label.text = "✦"
		_:
			icon_label.text = "•"
	if target_badge:
		var needs_target: bool = card_data.get("requires_target", false) as bool
		var ctype_str: String = card_data.get("type", "") as String
		target_badge.visible = needs_target and ctype_str != "ATTACK"

func _gui_input(event: InputEvent) -> void:
	if card_data.is_empty():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			# Hotkey-style click: could emit play here if desired
			pass

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_is_hovered = true
		_apply_style()
		_target_scale = HOVER_SCALE
		_target_offset_y = HOVER_RAISE
		if not card_data.is_empty():
			hover_changed.emit(card_data, true)
	if what == NOTIFICATION_MOUSE_EXIT:
		_is_hovered = false
		_apply_style()
		_target_scale = 1.0
		_target_offset_y = 0.0
		if not card_data.is_empty():
			hover_changed.emit(card_data, false)

func _process(delta: float) -> void:
	if _is_dragging:
		return
	var target_s: float = _target_scale
	scale = scale.lerp(Vector2(target_s, target_s), delta * ANIM_SPEED)
	position.y = lerpf(position.y, _base_position.y + _target_offset_y, delta * ANIM_SPEED)
