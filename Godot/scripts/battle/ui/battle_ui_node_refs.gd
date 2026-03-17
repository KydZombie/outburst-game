extends RefCounted
class_name BattleUINodeRefs
## Holds all node paths and resolves them from a root node. Single place to fix path changes.

const ROOT_MAIN := "Background/Margin/VBox/Main"
const ROOT_BOTTOM := "Background/Margin/VBox"

var party_list: Control
var deck_counter: Label
var discard_counter: Label
var hand_container: Control
var play_zone: Control
var right_panel: Control
var enemy_portrait: TextureRect
var enemy_name: Label
var enemy_hp: Label
var enemy_intent: Label
var play_effect: Label
var energy_display: Label
var end_turn_btn: Button
var drag_layer: CanvasLayer

func find_from(root: Node) -> void:
	party_list = root.get_node_or_null("%s/LeftPanel/PartyList" % ROOT_MAIN)
	deck_counter = root.get_node_or_null("%s/CenterArea/DeckDiscardRow/DeckCounter/VBox/Count" % ROOT_MAIN)
	if not deck_counter:
		deck_counter = root.get_node_or_null("%s/CenterArea/DeckDiscardRow/DeckCounter/Count" % ROOT_MAIN)
	if not deck_counter:
		deck_counter = root.get_node_or_null("%s/CenterArea/DeckDiscardRow/DeckCounter" % ROOT_MAIN)
	discard_counter = root.get_node_or_null("%s/CenterArea/DeckDiscardRow/DiscardCounter/VBox/Count" % ROOT_MAIN)
	if not discard_counter:
		discard_counter = root.get_node_or_null("%s/CenterArea/DeckDiscardRow/DiscardCounter/Count" % ROOT_MAIN)
	if not discard_counter:
		discard_counter = root.get_node_or_null("%s/CenterArea/DeckDiscardRow/DiscardCounter" % ROOT_MAIN)
	hand_container = root.get_node_or_null("%s/HandContainer" % ROOT_BOTTOM)
	play_zone = root.get_node_or_null("%s/CenterArea/PlayZone" % ROOT_MAIN)
	right_panel = root.get_node_or_null("%s/RightPanel" % ROOT_MAIN)
	enemy_portrait = root.get_node_or_null("%s/RightPanel/EnemyPanel/EnemyPortrait" % ROOT_MAIN) as TextureRect
	enemy_name = root.get_node_or_null("%s/RightPanel/EnemyPanel/EnemyName" % ROOT_MAIN)
	enemy_hp = root.get_node_or_null("%s/RightPanel/EnemyPanel/EnemyHP" % ROOT_MAIN)
	enemy_intent = root.get_node_or_null("%s/RightPanel/EnemyPanel/IntentLabel" % ROOT_MAIN)
	play_effect = root.get_node_or_null("%s/RightPanel/EnemyPanel/PlayEffect" % ROOT_MAIN) as Label
	energy_display = root.get_node_or_null("%s/BottomBar/HBox/EnergyBox/EnergyLabel" % ROOT_BOTTOM)
	if not energy_display:
		energy_display = root.get_node_or_null("%s/BottomBar/HBox/EnergyLabel" % ROOT_BOTTOM)
	end_turn_btn = root.get_node_or_null("%s/BottomBar/HBox/EndTurnButton" % ROOT_BOTTOM)
	drag_layer = root.get_node_or_null("DragLayer")
