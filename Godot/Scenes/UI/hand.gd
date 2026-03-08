extends HBoxContainer
class_name Hand

func _ready() -> void:
	var battle_runner: Node = get_parent().get_parent()
	for child: Node in get_children():
		var card_ui := child as CardUI
		if card_ui:
			card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	# Defer so BattleRunner._Ready() runs first and draws cards; then we sync and show icons.
	call_deferred("_sync_hand_from_state", battle_runner)

func _sync_hand_from_state(battle_runner: Node) -> void:
	if not battle_runner or not battle_runner.has_method("GetHandCount"):
		return
	var hand_count: int = battle_runner.GetHandCount()
	var card_ui_children: Array[Node] = get_children()
	for i in range(card_ui_children.size()):
		var card_ui := card_ui_children[i] as CardUI
		if not card_ui:
			continue
		if i < hand_count:
			var cid: String = battle_runner.GetHandCardId(i)
			var cname: String = battle_runner.GetHandCardName(i)
			var ccost: int = battle_runner.GetHandCardCost(i) if battle_runner.has_method("GetHandCardCost") else -1
			card_ui.set_card_data(cid, cname, ccost)
		else:
			card_ui.set_card_data("", "", -1)
	_update_energy_ui(battle_runner)
	_update_enemy_ui(battle_runner)

func _update_energy_ui(battle_runner: Node) -> void:
	if not battle_runner or not battle_runner.has_method("GetEnergy"):
		return
	var energy_ui: Node = get_tree().get_first_node_in_group("energy_ui")
	if energy_ui and energy_ui.has_method("update_energy"):
		energy_ui.update_energy(battle_runner.GetEnergy())

func _update_enemy_ui(battle_runner: Node) -> void:
	if not battle_runner or not battle_runner.has_method("GetEnemyHealth"):
		return
	var enemy_node: Node = get_tree().get_first_node_in_group("battle_enemy")
	if enemy_node and enemy_node.has_method("update_from_battle_runner"):
		enemy_node.update_from_battle_runner(battle_runner)

## Call after a card is played to refresh all slots from Core state.
func refresh_from_state() -> void:
	var battle_runner: Node = get_parent().get_parent()
	_sync_hand_from_state(battle_runner)

func _on_card_ui_reparent_requested(child: CardUI) -> void:
	child.reparent(self)