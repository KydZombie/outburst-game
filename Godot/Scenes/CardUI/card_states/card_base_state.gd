extends CardState

func _init() -> void:
	state = State.BASE

func enter() -> void:
	if not card_ui.is_node_ready():
		await card_ui.ready
	card_ui.drop_point_detector.monitoring = false
	# Return to hand when entering BASE (e.g. released outside drop area)
	var hand := card_ui.get_tree().get_first_node_in_group("hand")
	if hand and card_ui.get_parent() != hand:
		card_ui.reparent(hand)
	card_ui.reparent_requested.emit(card_ui)
	
	card_ui.pivot_offset = Vector2.ZERO

func exit() -> void:
	pass

func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		card_ui.pivot_offset = card_ui.get_global_mouse_position() - card_ui.global_position
		transition_requested.emit(self, CardState.State.CLICKED)
