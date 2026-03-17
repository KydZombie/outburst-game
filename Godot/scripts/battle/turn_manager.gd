extends Node
class_name TurnManager
## Runs exactly one enemy action per turn via DoEnemyAi(), then discards hand and draws.

signal turn_ended(new_turn: int, energy: int)
## Emitted when the enemy heals. Amount is the actual HP restored (capped by max_hp).
signal enemy_heal_action(amount: int)

var enemy_ai: EnemyAI
var combat_resolver: CombatResolver
var deck_manager: DeckManager

func setup(_enemy_ai: EnemyAI, _combat_resolver: CombatResolver, _deck_manager: DeckManager) -> void:
	enemy_ai = _enemy_ai
	combat_resolver = _combat_resolver
	deck_manager = _deck_manager

## Performs exactly one enemy action per call: attack a living character or heal (if not at max hp).
## If enemy is dead or no party members are alive, no action is performed.
func do_enemy_ai(party: Array[Dictionary], enemies: Array[Dictionary]) -> void:
	# If enemy is dead, no actions.
	if enemy_ai.is_enemy_dead(enemies):
		return
	# If no characters are alive, enemy does not act (player loss handled by game-over check).
	var alive := enemy_ai.get_alive_party_indices(party)
	if alive.is_empty():
		return
	var decision: Dictionary = enemy_ai.decide_action(party, enemies)
	var action: String = decision.get("action", "none") as String
	if action == "attack":
		var target_idx: int = decision.get("target_idx", -1) as int
		var damage: int = decision.get("damage", 0) as int
		if target_idx >= 0 and target_idx < party.size():
			var target_hp: int = party[target_idx].get("hp", 100) as int
			if target_hp > 0 and damage > 0:
				combat_resolver.enemy_attack_party(party, target_idx, damage)
	elif action == "heal":
		var heal_amount: int = decision.get("heal_amount", 0) as int
		if heal_amount > 0:
			var actual: int = combat_resolver.enemy_heal(enemies, heal_amount)
			if actual > 0:
				enemy_heal_action.emit(actual)

func end_turn(
	party: Array[Dictionary],
	enemies: Array[Dictionary],
	current_turn: int,
	current_energy: int
) -> Dictionary:
	# Exactly one enemy action per turn (match Core DoEnemyAi). No hand discard, no draw, no energy refill.
	do_enemy_ai(party, enemies)

	var new_turn := current_turn + 1

	turn_ended.emit(new_turn, current_energy)
	return {
		"turn": new_turn,
		"energy": current_energy,
	}
