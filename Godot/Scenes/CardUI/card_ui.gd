extends Control
class_name CardUI

@warning_ignore("unused_signal")
signal reparent_requested(which_card_ui: CardUI)


@export var card: Card
@onready var panel: Panel = $Panel
@onready var cost: Label = $Cost
@onready var state_label: Label = get_node_or_null("State") as Label
@onready var icon_texture: TextureRect = $Icon
@onready var card_name_label: Label = _get_card_name_label()

func _get_card_name_label() -> Label:
	var n: Node = get_node_or_null("CardName")
	return n as Label
@onready var drop_point_detector: Area2D = $DropPointDetecor
@onready var card_state_machine: CardStateMachine = $CardStateMachine

## Nodes (e.g. drop areas) the card is currently over. Updated when is_over_drop_area() is called.
var targets: Array[Area2D] = []

## Core card id (Guid as string). Set when hand is synced from state.
var card_id: String = ""
## Display name from Core Card.Data.Identifier. Set when hand is synced.
var card_name: String = ""

var parent:Control 
var tween: Tween 

func _ready() -> void:
	if state_label:
		state_label.visible = false  # Never show "BASE", "CLICKED", etc. on the card
	card_state_machine.init(self)

func _input(event: InputEvent) -> void:
	card_state_machine.on_input(event)

func animate_to_position(new_position: Vector2, duration: float) -> void:
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", new_position, duration)

func _on_gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)

func _on_mouse_entered() -> void:
	card_state_machine.on_mouse_entered()

func _on_mouse_exited() -> void:
	card_state_machine.on_mouse_exited()

## Called when syncing hand from Core state. Sets card_id, card_name, cost, icon, and optional card name label.
## p_cost: energy cost from Core (use -1 to fall back to Godot resource or 0).
func set_card_data(p_id: String, p_name: String, p_cost: int = -1) -> void:
	card_id = p_id
	card_name = p_name
	if card_name_label:
		card_name_label.text = p_name
	_update_card_visuals(p_name, p_cost)

const DEFAULT_CARD_ICON_PATH: String = "res://Outburst Assets/art/tile_0104.png"

## Loads Card resource by identifier and sets cost label + icon. Uses core_cost when >= 0, else .tres or 0.
func _update_card_visuals(card_name_identifier: String, core_cost: int = -1) -> void:
	var card_res: Card = _load_card_resource(card_name_identifier)
	if cost:
		if core_cost >= 0:
			cost.text = str(core_cost)
		elif card_res:
			cost.text = str(card_res.cost)
		else:
			cost.text = "0"
	if card_res:
		if icon_texture:
			if card_res.icon:
				icon_texture.texture = card_res.icon
			else:
				icon_texture.texture = _load_default_icon()
			icon_texture.visible = true
	else:
		if icon_texture:
			if card_name_identifier.is_empty():
				icon_texture.texture = null
				icon_texture.visible = false
			else:
				icon_texture.texture = _load_default_icon()
				icon_texture.visible = true

func _load_default_icon() -> Texture2D:
	var tex: Texture2D = load(DEFAULT_CARD_ICON_PATH) as Texture2D
	return tex

func _load_card_resource(identifier: String) -> Card:
	if identifier.is_empty():
		return null
	var path: String = "res://characters/Warrior/Cards/%s.tres" % identifier
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path) as Resource
	return res as Card

## Returns true if the card's drop detector is overlapping any area in group "card_drop_area".
## Also updates targets to the list of overlapping drop-area nodes (so RELEASED state can use them).
func is_over_drop_area() -> bool:
	targets.clear()
	for area: Area2D in drop_point_detector.get_overlapping_areas():
		if area.is_in_group("card_drop_area"):
			targets.append(area)
	return not targets.is_empty()

func _on_drop_point_detecor_area_entered(_area: Area2D) -> void:
	pass

func _on_drop_point_detecor_area_exited(_area: Area2D) -> void:
	pass
