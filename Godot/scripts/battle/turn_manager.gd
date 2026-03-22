extends Node
class_name TurnManager
## Runs the full turn cycle: enemy AI, discard hand, draw fresh hand, refill energy.

signal turn_ended(new_turn: int, energy: int)
signal enemy_heal_action(amount: int)
signal enemy_attacked(target_idx: int, damage: int)
signal party_member_died(target_idx: int)

const BASE_ENERGY := 0
## Cards drawn at battle start and after each hand discard at end of player turn.
const HAND_SIZE := 5
## Max card plays (and paid draws) per player turn; separate from hand size so raising the cap does not change draw count.
const MAX_CARD_PLAYS_PER_TURN := 6

var enemy_ai: EnemyAI
var combat_resolver: CombatResolver
var deck_manager: DeckManager

func setup(_enemy_ai: EnemyAI, _combat_resolver: CombatResolver, _deck_manager: DeckManager) -> void:
	enemy_ai = _enemy_ai
	combat_resolver = _combat_resolver
	deck_manager = _deck_manager

func do_enemy_ai(party: Array[Dictionary], enemies: Array[Dictionary]) -> Dictionary:
	if enemy_ai.is_enemy_dead(enemies):
		return {"action": "none"}
	var alive := enemy_ai.get_alive_party_indices(party)
	if alive.is_empty():
		return {"action": "none"}
	var decision: Dictionary = enemy_ai.decide_action(party, enemies)
	var action: String = decision.get("action", "none") as String
	if action == "attack":
		var e: Dictionary = enemies[0] if enemies.size() > 0 else {}
		var power: int = e.get("power", 10) as int
		var total_damage: int = GameSettings.get_enemy_attack_damage(power)
		if GameSettings.is_enemy_spread_attack():
			if total_damage <= 0:
				pass
			else:
				var targets: Array = enemy_ai.decide_hard_attack_targets(party, total_damage)
				if targets.is_empty():
					pass
				else:
					var n: int = targets.size()
					var base_dmg: int = int(total_damage / float(n))
					var remainder: int = total_damage % n
					for i in range(n):
						var dmg: int = base_dmg + (1 if i < remainder else 0)
						if dmg > 0:
							var idx: int = targets[i] as int
							combat_resolver.enemy_attack_party(party, idx, dmg)
							enemy_attacked.emit(idx, dmg)
							if (party[idx].get("hp", 100) as int) <= 0:
								party_member_died.emit(idx)
		else:
			var target_idx: int = decision.get("target_idx", -1) as int
			if target_idx >= 0 and target_idx < party.size():
				var target_hp: int = party[target_idx].get("hp", 100) as int
				if target_hp > 0 and total_damage > 0:
					combat_resolver.enemy_attack_party(party, target_idx, total_damage)
					enemy_attacked.emit(target_idx, total_damage)
					if (party[target_idx].get("hp", 100) as int) <= 0:
						party_member_died.emit(target_idx)
	elif action == "heal":
		var heal_amount: int = decision.get("heal_amount", 0) as int
		if heal_amount > 0:
			var actual: int = combat_resolver.enemy_heal(enemies, heal_amount)
			if actual > 0:
				enemy_heal_action.emit(actual)
	return decision

func end_turn(
	party: Array[Dictionary],
	enemies: Array[Dictionary],
	current_turn: int,
	_current_energy: int
) -> Dictionary:
	var decision := do_enemy_ai(party, enemies)

	deck_manager.discard_hand_into_discard()
	deck_manager.draw_cards(HAND_SIZE)
	# Avoid 0-energy softlocks: put Gain Energy in hand whenever one still exists in deck/discard.
	deck_manager.ensure_hand_has_gain_energy_if_possible()

	var new_turn := current_turn + 1
	var new_energy := BASE_ENERGY

	turn_ended.emit(new_turn, new_energy)
	return {
		"turn": new_turn,
		"energy": new_energy,
		"enemy_action": decision,
	}
