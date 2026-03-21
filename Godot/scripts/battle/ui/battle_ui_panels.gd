extends RefCounted
class_name BattleUIPanels
## Updates party list and enemy panel labels/bars from game state. No portraits (use BattleUIPortraits).

const EMOTION_ORDER := ["Angry", "Sad", "Happy"]
const EMOTION_ICONS := {"Angry": "😡", "Sad": "😢", "Happy": "😊"}
const _EMOJI_VALUE_SP := "\u00A0"
const _GROUP_SP := "\u00A0\u00A0"

## Layout-affecting properties (content_margin, border_width, shadow_size) MUST match
## `StyleBoxFlat_party_row` in battle_scene.tscn so swapping styles causes no size change.
## Visual glow uses expand_margin + shadow (cosmetic-only, doesn't affect layout).
const TARGET_GLOW_BG := Color(0.11, 0.14, 0.26, 1)
const PARTY_ROW_CONTENT_MARGIN := Vector4(10.0, 6.0, 10.0, 6.0)
const TARGET_GLOW_CORNER_RADIUS := 20

static var _default_party_row_styleboxes: Dictionary = {}
static var _party_target_glow_stylebox: StyleBoxFlat

static func _ensure_party_target_glow_stylebox_from(default_sb: StyleBox) -> void:
	if _party_target_glow_stylebox:
		return
	var sb: StyleBoxFlat
	if default_sb and default_sb is StyleBoxFlat:
		sb = (default_sb as StyleBoxFlat).duplicate() as StyleBoxFlat
	else:
		sb = StyleBoxFlat.new()
		sb.content_margin_left = PARTY_ROW_CONTENT_MARGIN.x
		sb.content_margin_top = PARTY_ROW_CONTENT_MARGIN.y
		sb.content_margin_right = PARTY_ROW_CONTENT_MARGIN.z
		sb.content_margin_bottom = PARTY_ROW_CONTENT_MARGIN.w
		sb.corner_radius_top_left = TARGET_GLOW_CORNER_RADIUS
		sb.corner_radius_top_right = TARGET_GLOW_CORNER_RADIUS
		sb.corner_radius_bottom_right = TARGET_GLOW_CORNER_RADIUS
		sb.corner_radius_bottom_left = TARGET_GLOW_CORNER_RADIUS
	sb.bg_color = TARGET_GLOW_BG
	## Only cosmetic changes after this point — expand_margin is purely visual and
	## does NOT affect minimum size, so there is no layout shift when swapping styles.
	sb.expand_margin_left = 2.0
	sb.expand_margin_top = 2.0
	sb.expand_margin_right = 2.0
	sb.expand_margin_bottom = 2.0
	_party_target_glow_stylebox = sb

static func _format_emotions(emotions: Dictionary) -> String:
	var parts: Array[String] = []
	for key in EMOTION_ORDER:
		var val: int = emotions.get(key, 0) as int
		var icon: String = EMOTION_ICONS.get(key, "•")
		var chunk: String = "%s%s%d" % [icon, _EMOJI_VALUE_SP, val]
		if key == "Angry":
			parts.append("[color=#ff3b3b]%s[/color]" % chunk)
		else:
			parts.append(chunk)
	return _GROUP_SP.join(PackedStringArray(parts)) if parts.size() > 0 else "—"

static func refresh_party(party_list: Control, party: Array[Dictionary], target_character_index: int = -1) -> void:
	if not party_list:
		return
	for i in range(min(party_list.get_child_count(), party.size())):
		var row := party_list.get_child(i)
		if row is PanelContainer:
			var pc := row as PanelContainer
			var row_id: int = pc.get_instance_id()
			if not _default_party_row_styleboxes.has(row_id):
				var base_sb_any: Variant = pc.get("theme_override_styles/panel")
				_default_party_row_styleboxes[row_id] = base_sb_any if base_sb_any is StyleBox else null

			if i == target_character_index:
				_ensure_party_target_glow_stylebox_from(_default_party_row_styleboxes.get(row_id))
				pc.set("theme_override_styles/panel", _party_target_glow_stylebox)
				pc.modulate = Color(1.15, 1.15, 1.2, 1.0)
				pc.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			else:
				pc.set("theme_override_styles/panel", _default_party_row_styleboxes.get(row_id))
				pc.modulate = Color.WHITE
				pc.mouse_default_cursor_shape = Control.CURSOR_ARROW
		elif row is Control:
			(row as Control).modulate = Color(1.15, 1.15, 1.2) if i == target_character_index else Color.WHITE
		var p: Dictionary = party[i]
		var name_lbl := row.get_node_or_null("HBox/VBox/Name") as Label
		if not name_lbl:
			name_lbl = row.get_node_or_null("VBox/Name") as Label
		var hp_lbl := row.get_node_or_null("HBox/VBox/HP") as Label
		if not hp_lbl:
			hp_lbl = row.get_node_or_null("VBox/HP") as Label
		var bar := row.get_node_or_null("HBox/VBox/HealthBar") as ProgressBar
		if not bar:
			bar = row.get_node_or_null("VBox/HealthBar") as ProgressBar
		var emotions_lbl := row.get_node_or_null("HBox/VBox/Emotions") as Control
		if not emotions_lbl:
			emotions_lbl = row.get_node_or_null("VBox/Emotions") as Control
		if name_lbl:
			name_lbl.text = p.get("name", "") as String
		if emotions_lbl:
			var emotions: Dictionary = p.get("emotions", {}) as Dictionary
			var formatted: String = _format_emotions(emotions)
			if emotions_lbl is RichTextLabel:
				var rtl := emotions_lbl as RichTextLabel
				rtl.bbcode_text = formatted
				rtl.tooltip_text = "😡 Angry   😢 Sad   😊 Happy"
			else:
				(emotions_lbl as Label).text = formatted
				(emotions_lbl as Label).tooltip_text = "😡 Angry   😢 Sad   😊 Happy"
		if hp_lbl:
			var hp_val: int = p.get("hp", 0) as int
			var max_hp_val: int = p.get("max_hp", 100) as int
			hp_lbl.text = "%d/%d" % [hp_val, max_hp_val]
			var ratio: float = (float(hp_val) / float(max_hp_val)) if max_hp_val > 0 else 0.0
			if ratio <= 0.0:
				hp_lbl.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
			elif ratio < 0.5:
				hp_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35, 1.0))
			elif ratio < 1.0:
				hp_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 0.75, 1.0))
			else:
				hp_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 0.75, 1.0))
		if bar:
			var max_hp_f: float = p.get("max_hp", 100) as float
			var hp_f: float = p.get("hp", 0) as float
			bar.max_value = max_hp_f
			if absf(bar.value - hp_f) > 0.5:
				var tw := bar.create_tween()
				tw.tween_property(bar, "value", hp_f, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			else:
				bar.value = hp_f
			var ratio: float = hp_f / max_hp_f if max_hp_f > 0.0 else 0.0
			if ratio < 0.5:
				bar.modulate = Color(1.0, 0.0, 0.0, 1.0)
			else:
				bar.modulate = Color(0.3, 1.0, 0.6, 1.0)
	BattleUIPortraits.apply_party_portraits(party_list, party)

static func refresh_enemy(
	enemy_name: Label,
	enemy_hp: Label,
	enemy_health_bar: ProgressBar,
	enemy_portrait: TextureRect,
	enemies: Array[Dictionary]
) -> void:
	if enemies.is_empty():
		return
	var e: Dictionary = enemies[0]
	if enemy_name:
		enemy_name.text = (e.get("name", "") as String).to_upper()
	var eh: int = e.get("hp", 0) as int
	var emh: int = e.get("max_hp", 60) as int
	if enemy_hp:
		enemy_hp.text = "%d / %d" % [eh, emh]
	if enemy_health_bar:
		enemy_health_bar.max_value = float(emh)
		if absf(enemy_health_bar.value - float(eh)) > 0.5:
			var tw := enemy_health_bar.create_tween()
			tw.tween_property(enemy_health_bar, "value", float(eh), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			enemy_health_bar.value = float(eh)
		var ratio: float = float(eh) / float(emh) if emh > 0 else 0.0
		## Enemy health color (#FF3B3B-ish); darker when low (mirror party bar feedback).
		if ratio < 0.25:
			enemy_health_bar.modulate = Color(0.65, 0.12, 0.12, 1.0)
		elif ratio < 0.5:
			enemy_health_bar.modulate = Color(0.9, 0.25, 0.25, 1.0)
		else:
			enemy_health_bar.modulate = Color(1.0, 0.35, 0.35, 1.0)
	BattleUIPortraits.apply_enemy_portrait(enemy_portrait, enemies)
