extends CardState

func _init() -> void:
	state = State.CLICKED

func enter() -> void:
	card_ui.modulate = Color.WHITE
	if card_ui.state_label:
		card_ui.state_label.text = "CLICKED"
	card_ui.drop_point_detector.monitoring = true

func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		transition_requested.emit(self, CardState.State.DRAGGING)
