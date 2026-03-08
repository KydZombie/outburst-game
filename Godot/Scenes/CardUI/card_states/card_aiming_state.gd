extends CardState

const MOUSE_Y_SNAPBACK_THRESHOLD := 138

func _init() -> void:
	state = State.AIMING

func enter() -> void:
	card_ui.modulate = Color.WHITE
	if card_ui.state_label:
		card_ui.state_label.text = "AIMING"
	card_ui.targets.clear()
	# Position the card above the hand (bottom center of viewport).
	var viewport_rect: Rect2 = card_ui.get_viewport().get_visible_rect()
	var target_pos: Vector2 = viewport_rect.size / 2.0
	target_pos.y = viewport_rect.size.y - card_ui.size.y * 1.5
	card_ui.global_position = target_pos
	# Detector follows mouse so release-over-drop-area is detected correctly.
	card_ui.drop_point_detector.monitoring = true
	card_ui.drop_point_detector.global_position = card_ui.get_global_mouse_position()
	var events = card_ui.get_node_or_null("/root/Events")
	if events:
		events.card_aim_started.emit(card_ui)

func exit() -> void:
	var events = card_ui.get_node_or_null("/root/Events")
	if events:
		events.card_aim_ended.emit(card_ui)

func on_input(event: InputEvent) -> void:
	var mouse_motion: bool = event is InputEventMouseMotion
	if mouse_motion:
		# So "release over drop area" is detected using mouse position.
		card_ui.drop_point_detector.global_position = card_ui.get_global_mouse_position()
	var mouse_at_bottom: bool = card_ui.get_global_mouse_position().y > MOUSE_Y_SNAPBACK_THRESHOLD
	# Return to hand: right-click or move mouse back down.
	if (mouse_motion and mouse_at_bottom) or event.is_action_pressed("right_mouse"):
		transition_requested.emit(self, CardState.State.BASE)
	elif event.is_action_released("left_mouse"):
		get_viewport().set_input_as_handled()
		# Only play if released over a drop area; otherwise return to hand.
		if card_ui.is_over_drop_area():
			transition_requested.emit(self, CardState.State.RELEASED)
		else:
			transition_requested.emit(self, CardState.State.BASE)
