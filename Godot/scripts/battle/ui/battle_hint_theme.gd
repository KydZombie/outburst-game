class_name BattleHintTheme
extends RefCounted
## Single source for instructional / hint copy (play zone, bottom hotkeys, turn banners).

const FONT_COLOR := Color(1, 1, 1, 1)
const OUTLINE_COLOR := Color(0.35, 0.65, 1, 0.95)
const FONT_SIZE_PLAY_ZONE := 26
const OUTLINE_PLAY_ZONE := 6
const FONT_SIZE_CONTROLS := 18
const OUTLINE_CONTROLS := 4
const FONT_SIZE_BANNER := 42
const OUTLINE_BANNER := 6


static func apply_play_zone_label(l: Label) -> void:
	if l == null:
		return
	l.add_theme_font_size_override("font_size", FONT_SIZE_PLAY_ZONE)
	l.add_theme_color_override("font_color", FONT_COLOR)
	l.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	l.add_theme_constant_override("outline_size", OUTLINE_PLAY_ZONE)


static func apply_play_zone_richtext(rt: RichTextLabel) -> void:
	if rt == null:
		return
	rt.add_theme_font_size_override("normal_font_size", FONT_SIZE_PLAY_ZONE)
	rt.add_theme_font_size_override("bold_font_size", FONT_SIZE_PLAY_ZONE)
	rt.add_theme_color_override("default_color", FONT_COLOR)
	rt.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	rt.add_theme_constant_override("outline_size", OUTLINE_PLAY_ZONE)


static func apply_controls_hint(l: Label) -> void:
	if l == null:
		return
	l.add_theme_font_size_override("font_size", FONT_SIZE_CONTROLS)
	l.add_theme_color_override("font_color", FONT_COLOR)
	l.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	l.add_theme_constant_override("outline_size", OUTLINE_CONTROLS)


static func apply_turn_banner(l: Label) -> void:
	if l == null:
		return
	l.add_theme_font_size_override("font_size", FONT_SIZE_BANNER)
	l.add_theme_color_override("font_color", FONT_COLOR)
	l.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	l.add_theme_constant_override("outline_size", OUTLINE_BANNER)
