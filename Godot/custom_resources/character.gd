extends Stats
class_name CharacterStats

@export var starting_deck: CardPile
@export var cards_per_turn: int
@export var max_mana: int = 3

var mana: int: set = set_mana
var deck: CardPile
var discard: CardPile
var draw_pile: CardPile

func set_mana(value: int) -> void:
	mana = clampi(value, 0, max_mana)
	stats_changed.emit()

func reset_mana() -> void:
	self.mana = max_mana

func can_play_card(card: Card) -> bool:
	return mana >= card.cost

func create_instance() -> Resource:
	var instance: CharacterStats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.reset_mana()
	if instance.starting_deck:
		instance.deck = instance.starting_deck.duplicate()
	else:
		instance.deck = CardPile.new()
	instance.draw_pile = CardPile.new()
	instance.discard = CardPile.new()
	return instance
