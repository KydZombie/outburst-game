extends Control
## In-game tutorial: topic hub + paginated detail with main-menu-style hover effects.

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const HOVER_SCALE := 1.04
const PRESS_SCALE := 0.97
const NORMAL_SCALE := 1.0
const TWEEN_DURATION := 0.12

## One-line hub tagline: uppercase, spaced in code for readability (see _apply_intro_tagline_style).
const _INTRO_TAGLINE_UPPER := "Learn The Basics Below. Use /, Next, Jump to any topic"
const _INTRO_WORD_GAP := "   "
const _INTRO_FONT_SIZE := 30
const _INTRO_GLYPH_EXTRA_SPACING := 3

const _TOPIC_ORDER: PackedStringArray = [
	"overview",
	"energy",
	"draw",
	"emotions",
	"jeff",
	"targeting",
	"controls",
]

const _TOPICS: Dictionary = {
	"overview": {
		"title": "Overview",
		"body": """OUTBURST is a turn-based card battle. Your party of five faces Jeff — reduce his HP to zero before your team is wiped out.

DIFFICULTY (choose from Settings before battle):
• Easy — your punches deal 2× damage. Jeff attacks normally.
• Medium — baseline damage for both sides.
• Hard — Jeff hits for 45, heals 25, and spreads attacks across 1–5 allies with smart targeting. Your punches deal 1.1× damage. His intent shows how many he'll hit.

If a party member's HP reaches 0, they die (all emotions reset to 0) and can no longer be targeted.

Navigate with Back / Next, or jump to any topic from the list."""
	},
	"energy": {
		"title": "Energy & Cards",
		"body": """• Start each turn with 0 energy. Gain Energy is free and adds +8 energy.
• Get Angry and Angry Punch cost 0 energy. Basic Punch costs 1. Cheer Up costs 1.
• Basic Punch deals 2 base damage. Angry Punch deals 5 base damage, requires 1 Angry on the targeted ally, and spends that Angry."""
	},
	"draw": {
		"title": "Draw & Turn Flow",
		"body": """• Press D to draw: your first 13 manual draws each battle are free. After that, drawing costs 0 if the next deck card is Free, otherwise 1 energy.
• Play up to 6 cards per turn. Press S to end your turn and start Jeff's phase.
• Jeff shows his intent, then attacks or heals. Afterward your hand is discarded, you draw 5 fresh cards, and energy resets to 0.
• If you have no legal plays and can't draw, your turn auto-passes silently."""
	},
	"emotions": {
		"title": "Emotions",
		"body": """Party only — Jeff has no emotions.

• 😡 Angry — Get Angry adds +2 Angry to an ally. Angry Punch requires 1 Angry on the punching ally.
• 😢 Sad — each Sad on the punching ally reduces their punch damage by 1. Jeff adds +1 Sad to living targets he hits.
• 😊 Happy — each punch adds bonus damage equal to current Happy stacks, then removes 1 Happy. Cheer Up clears Angry & Sad and adds +2 Happy (costs 1 energy)."""
	},
	"jeff": {
		"title": "Jeff (Enemy)",
		"body": """• Intent shows his next move: attack damage is Power × 3 (30 on Medium; 45 on Hard).
• On Hard, intent also shows how many allies he'll target — e.g. "⚔ 45 (3)" or "⚔ 45 (All)".
• At 20 HP or below, Jeff tries to heal (⅓ max HP on Medium, 25 on Hard).
• On Hard, Jeff prioritizes killable allies, then low-HP or high-threat (Angry/Happy) targets.
• Click the DECK or DISCARD panels to see what remains in those piles."""
	},
	"targeting": {
		"title": "Targeting & Hints",
		"body": """• Skills (Get Angry, Cheer Up): drag to the play zone, then click a party row or press 1–5. Esc cancels ally targeting.
• Attacks (Basic Punch, Angry Punch) hit Jeff automatically; Angry Punch still uses the targeted ally for Angry / emotion modifiers.
• The play zone may hint when you need Gain Energy at 0 energy, or when Angry Punch needs Get Angry first."""
	},
	"controls": {
		"title": "Controls",
		"body": """• Drag cards to the play zone to play them.
• D — Draw a card (if you have energy or free draws remaining).
• S — End your turn and start Jeff's phase.
• On this Tutorial screen: Esc — back to the main menu. In battle, M — return to main menu.
• Master volume: Main Menu → Settings."""
	},
}

@onready var _title: Label = $MarginContainer/VBox/TitleLabel
@onready var _hub: VBoxContainer = $MarginContainer/VBox/HubView
@onready var _detail: VBoxContainer = $MarginContainer/VBox/DetailView
@onready var _section_title: Label = $MarginContainer/VBox/DetailView/SectionTitle
@onready var _page_indicator: Label = $MarginContainer/VBox/DetailView/PageIndicator
@onready var _detail_scroll: ScrollContainer = $MarginContainer/VBox/DetailView/DetailScroll
@onready var _detail_label: Label = $MarginContainer/VBox/DetailView/DetailScroll/DetailLabel
@onready var _btn_prev: Button = $MarginContainer/VBox/DetailView/DetailNav/BtnPrev
@onready var _btn_next: Button = $MarginContainer/VBox/DetailView/DetailNav/BtnNext
@onready var _btn_topics: Button = $MarginContainer/VBox/DetailView/DetailNav/BtnTopics
@onready var _btn_menu_detail: Button = $MarginContainer/VBox/DetailView/DetailNav/BtnMenu
@onready var _btn_menu_hub: Button = $MarginContainer/VBox/HubView/BackToMenuHub

var _topic_index: int = 0
var _button_tweens: Dictionary = {}


func _ready() -> void:
	if _detail_scroll:
		_detail_scroll.resized.connect(_fit_detail_label_width)
	if _btn_menu_hub:
		_btn_menu_hub.pressed.connect(_go_main_menu)
		_connect_hover_and_press(_btn_menu_hub)
	if _btn_menu_detail:
		_btn_menu_detail.pressed.connect(_go_main_menu)
		_connect_hover_and_press(_btn_menu_detail)
	if _btn_topics:
		_btn_topics.pressed.connect(_show_hub)
		_connect_hover_and_press(_btn_topics)
	if _btn_prev:
		_btn_prev.pressed.connect(_on_prev_pressed)
		_connect_hover_and_press(_btn_prev)
	if _btn_next:
		_btn_next.pressed.connect(_on_next_pressed)
		_connect_hover_and_press(_btn_next)
	
	_connect_topic_button("BtnOverview", "overview")
	_connect_topic_button("BtnEnergyCards", "energy")
	_connect_topic_button("BtnDrawTurn", "draw")
	_connect_topic_button("BtnEmotions", "emotions")
	_connect_topic_button("BtnJeff", "jeff")
	_connect_topic_button("BtnTargeting", "targeting")
	_connect_topic_button("BtnControls", "controls")
	
	_apply_intro_tagline_style()
	_show_hub()
	call_deferred("_fit_detail_label_width")


func _apply_intro_tagline_style() -> void:
	var intro: Label = _hub.get_node_or_null("IntroLabel") as Label if _hub else null
	if intro == null:
		return
	intro.text = _INTRO_WORD_GAP.join(_INTRO_TAGLINE_UPPER.split(" ", false))
	intro.autowrap_mode = TextServer.AUTOWRAP_OFF
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_font_size_override("font_size", _INTRO_FONT_SIZE)
	var base_font: Font = intro.get_theme_font("font")
	if base_font == null:
		base_font = ThemeDB.fallback_font
	if base_font:
		var fv := FontVariation.new()
		fv.base_font = base_font
		fv.spacing_glyph = _INTRO_GLYPH_EXTRA_SPACING
		intro.add_theme_font_override("font", fv)


func _connect_topic_button(node_name: String, topic_id: String) -> void:
	if _hub == null:
		return
	var b: Button = _hub.get_node_or_null("TopicGrid/%s" % node_name) as Button
	if b:
		b.pressed.connect(func() -> void: _show_detail_by_id(topic_id))
		_connect_hover_and_press(b)


func _connect_hover_and_press(btn: Button) -> void:
	btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
	btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))
	btn.button_down.connect(_on_button_down.bind(btn))
	btn.button_up.connect(_on_button_up.bind(btn))
	btn.pivot_offset = btn.size / 2.0


func _on_button_mouse_entered(btn: Button) -> void:
	if btn.disabled:
		return
	var tween := _get_button_tween(btn)
	tween.tween_property(btn, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), TWEEN_DURATION)


func _on_button_mouse_exited(btn: Button) -> void:
	var tween := _get_button_tween(btn)
	tween.tween_property(btn, "scale", Vector2(NORMAL_SCALE, NORMAL_SCALE), TWEEN_DURATION)


func _on_button_down(btn: Button) -> void:
	if btn.disabled:
		return
	var tween := _get_button_tween(btn)
	tween.tween_property(btn, "scale", Vector2(PRESS_SCALE, PRESS_SCALE), TWEEN_DURATION)


func _on_button_up(btn: Button) -> void:
	var tween := _get_button_tween(btn)
	tween.tween_property(btn, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), TWEEN_DURATION)


func _get_button_tween(btn: Button) -> Tween:
	if _button_tweens.has(btn):
		var old: Tween = _button_tweens[btn]
		if old and old.is_valid():
			old.kill()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	_button_tweens[btn] = tween
	return tween


func _show_hub() -> void:
	if _title:
		_title.text = "Tutorial"
	if _hub:
		_hub.visible = true
	if _detail:
		_detail.visible = false
	_fit_intro_width()


func _show_detail_by_id(topic_id: String) -> void:
	var idx: int = _TOPIC_ORDER.find(topic_id)
	if idx < 0:
		idx = 0
	_topic_index = idx
	_apply_detail_page()


func _apply_detail_page() -> void:
	if _hub == null or _detail == null or _section_title == null or _detail_label == null or _page_indicator == null:
		return
	var topic_id: String = _TOPIC_ORDER[_topic_index]
	var data: Dictionary = _TOPICS[topic_id] as Dictionary
	if _title:
		_title.text = "Tutorial"
	_hub.visible = false
	_detail.visible = true
	_section_title.text = data.get("title", "") as String
	_detail_label.text = data.get("body", "") as String
	_page_indicator.text = "%d / %d" % [_topic_index + 1, _TOPIC_ORDER.size()]
	_btn_prev.disabled = false
	_btn_next.disabled = false
	_fit_detail_label_width()
	call_deferred("_reset_detail_scroll")


func _reset_detail_scroll() -> void:
	if _detail_scroll:
		_detail_scroll.scroll_vertical = 0


func _on_prev_pressed() -> void:
	if _topic_index <= 0:
		_show_hub()
	else:
		_topic_index -= 1
		_apply_detail_page()


func _on_next_pressed() -> void:
	if _topic_index >= _TOPIC_ORDER.size() - 1:
		_show_hub()
	else:
		_topic_index += 1
		_apply_detail_page()


func _fit_detail_label_width() -> void:
	if _detail_scroll == null or _detail_label == null:
		return
	var w: float = _detail_scroll.size.x
	if w < 32.0:
		return
	_detail_label.custom_minimum_size.x = w


func _fit_intro_width() -> void:
	## Intro tagline is a single centered line; width follows content (no wrap / no column clamp).
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit_intro_width()
		_fit_detail_label_width()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("return_to_main_menu"):
		get_viewport().set_input_as_handled()
		_go_main_menu()


func _go_main_menu() -> void:
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(MAIN_MENU_PATH)
