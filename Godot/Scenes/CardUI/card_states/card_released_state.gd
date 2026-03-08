extends CardState

var played: bool = false

func _init() -> void:
	state = State.RELEASED

func enter() -> void:
	played = false
	if card_ui.targets.is_empty():
		transition_requested.emit(self, CardState.State.BASE)
		return
	played = true
	var battle_runner: Node = card_ui.get_tree().current_scene
	if battle_runner and battle_runner.has_method("SetTargetCharacterIndex"):
		battle_runner.SetTargetCharacterIndex(0)
	if battle_runner and battle_runner.has_method("PlayCardFromHandByCardId"):
		battle_runner.PlayCardFromHandByCardId(card_ui.card_id)
	var hand: Node = card_ui.get_tree().get_first_node_in_group("hand")
	if hand and hand.has_method("refresh_from_state"):
		hand.refresh_from_state()
	transition_requested.emit(self, CardState.State.BASE)

func on_input(_event: InputEvent) -> void:
	if played:
		return