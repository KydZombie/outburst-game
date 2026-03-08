extends CardState

const DRAG_MINIMUM_THRESHOLD := 0.05
var minimum_drag_time_elapsed := false
var has_been_over_drop_area := false

func _init() -> void:
	state = State.DRAGGING

func enter() -> void:
	var ui_layer := get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		card_ui.reparent(ui_layer)
	
	minimum_drag_time_elapsed = false
	has_been_over_drop_area = false
	var threshold_timer := get_tree().create_timer(DRAG_MINIMUM_THRESHOLD, false)
	threshold_timer.timeout.connect(func(): minimum_drag_time_elapsed = true)

func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Follow the mouse while dragging.
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset
		# Track whether this card has ever been over a drop area during this drag.
		var over_drop_area := card_ui.is_over_drop_area()
		if over_drop_area:
			has_been_over_drop_area = true
		# Only go to AIMING after the card has been over a drop area at least once
		# and then leaves it again. This avoids instantly skipping DRAGGING when
		# starting the drag from the hand.
		if has_been_over_drop_area and not over_drop_area:
			transition_requested.emit(self, CardState.State.AIMING)
			return
	if event.is_action_pressed("right_mouse"):
		transition_requested.emit(self, CardState.State.BASE)
	elif event.is_action_released("left_mouse") and minimum_drag_time_elapsed:
		get_viewport().set_input_as_handled()
		if card_ui.is_over_drop_area():
			transition_requested.emit(self, CardState.State.RELEASED)
		else:
			transition_requested.emit(self, CardState.State.BASE)
