extends RefCounted
class_name BattleUINodeRefs
## Holds all node paths and resolves them from a root node. Single place to fix path changes.

const ROOT_MAIN := "Background/Margin/VBox/Main"
const ROOT_BOTTOM := "Background/Margin/VBox"

var left_panel: PanelContainer
var party_list: Control
var deck_counter: Label
var discard_counter: Label
var hand_container: Control
var play_zone: Control
var right_panel: Control
## Jeff's portrait/HP block — use for Stage 1 charge-up (clearer than scaling whole RightPanel).
var enemy_panel: Control
var enemy_portrait: TextureRect
var enemy_name: Label
var enemy_hp: Label
var enemy_health_bar: ProgressBar
var enemy_intent: Label
var play_effect: Label
var draw_card_btn: Button
var energy_display: Label
var energy_box: PanelContainer
var end_turn_btn: Button
var target_prompt: Label
## Play-zone BBCode hint when Angry Punch needs Get Angry first (separate from TargetPrompt).
var angry_combo_hint: RichTextLabel
var turn_counter: Label
## Bottom-bar hotkey reminder (D-Draw, S-Skip); same hint style as play-zone copy.
var controls_label: Label
var drag_layer: CanvasLayer
## Click to open deck / discard list popups.
var deck_counter_panel: Control
var discard_counter_panel: Control

func find_from(root: Node) -> void:
	left_panel = root.get_node_or_null("%s/LeftPanel" % ROOT_MAIN) as PanelContainer
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
	enemy_panel = root.get_node_or_null("%s/RightPanel/EnemyPanel" % ROOT_MAIN) as Control
	enemy_portrait = root.get_node_or_null("%s/RightPanel/EnemyPanel/EnemyPortrait" % ROOT_MAIN) as TextureRect
	enemy_name = root.get_node_or_null("%s/RightPanel/EnemyPanel/EnemyName" % ROOT_MAIN)
	enemy_hp = root.get_node_or_null("%s/RightPanel/EnemyPanel/EnemyHP" % ROOT_MAIN)
	enemy_health_bar = root.get_node_or_null("%s/RightPanel/EnemyPanel/EnemyHealthBar" % ROOT_MAIN) as ProgressBar
	enemy_intent = root.get_node_or_null("%s/RightPanel/EnemyPanel/IntentLabel" % ROOT_MAIN)
	play_effect = root.get_node_or_null("%s/CenterArea/PlayZone/PlayEffect" % ROOT_MAIN) as Label
	draw_card_btn = root.get_node_or_null("%s/DrawCardRow/DrawCardButton" % ROOT_BOTTOM)
	energy_display = root.get_node_or_null("%s/BottomBar/HBox/EnergyBox/EnergyLabel" % ROOT_BOTTOM)
	if not energy_display:
		energy_display = root.get_node_or_null("%s/BottomBar/HBox/EnergyLabel" % ROOT_BOTTOM)
	energy_box = root.get_node_or_null("%s/BottomBar/HBox/EnergyBox" % ROOT_BOTTOM) as PanelContainer
	end_turn_btn = root.get_node_or_null("%s/BottomBar/HBox/EndTurnButton" % ROOT_BOTTOM)
	target_prompt = root.get_node_or_null("%s/CenterArea/PlayZone/TargetPrompt" % ROOT_MAIN) as Label
	angry_combo_hint = root.get_node_or_null("%s/CenterArea/PlayZone/AngryComboHint" % ROOT_MAIN) as RichTextLabel
	turn_counter = root.get_node_or_null("%s/BottomBar/HBox/TurnCounter" % ROOT_BOTTOM) as Label
	controls_label = root.get_node_or_null("%s/BottomBar/HBox/ControlsLabel" % ROOT_BOTTOM) as Label
	drag_layer = root.get_node_or_null("DragLayer")
	deck_counter_panel = root.get_node_or_null("%s/CenterArea/DeckDiscardRow/DeckCounter" % ROOT_MAIN) as Control
	discard_counter_panel = root.get_node_or_null("%s/CenterArea/DeckDiscardRow/DiscardCounter" % ROOT_MAIN) as Control
