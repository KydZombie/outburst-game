extends Node
class_name InputController

signal play_card_by_index(index: int)
signal draw_card_requested()
signal end_turn_requested()
signal quit_requested()

func _input(event: InputEvent) -> void:
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
	if event.is_action_pressed("quit_game"):
		quit_requested.emit()

