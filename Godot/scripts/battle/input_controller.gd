extends Node
class_name InputController

signal play_card_by_index(index: int)
signal draw_card_requested()
signal end_turn_requested()
signal quit_requested()
## Emitted when 1–5 is pressed while choosing a party target for a skill (slot 0 = key 1).
signal party_target_pressed(slot_index: int)
## Return to main menu from battle (input map `battle_return_to_menu`, default M).
signal main_menu_requested()

var _block_card_slot_hotkeys: bool = false
var _party_target_mode: bool = false


func set_block_card_slot_hotkeys(blocked: bool) -> void:
	_block_card_slot_hotkeys = blocked


func set_party_target_mode(on: bool) -> void:
	_party_target_mode = on


func _input(event: InputEvent) -> void:
	if _party_target_mode and event is InputEventKey and event.pressed and not event.echo:
		var ek := event as InputEventKey
		var c := ek.physical_keycode
		if c >= KEY_1 and c <= KEY_5:
			party_target_pressed.emit(c - KEY_1)
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()
			return
	if _block_card_slot_hotkeys:
		if event.is_action_pressed("play_card_1") or event.is_action_pressed("play_card_2") or event.is_action_pressed("play_card_3"):
			return
	if event.is_action_pressed("play_card_1"):
		play_card_by_index.emit(0)
	if event.is_action_pressed("play_card_2"):
		play_card_by_index.emit(1)
	if event.is_action_pressed("play_card_3"):
		play_card_by_index.emit(2)
	if event.is_action_pressed("draw_card"):
		draw_card_requested.emit()
	if event.is_action_pressed("skip_turn"):
		end_turn_requested.emit()
	if event.is_action_pressed("battle_return_to_menu"):
		main_menu_requested.emit()
	if event.is_action_pressed("quit_game"):
		quit_requested.emit()
