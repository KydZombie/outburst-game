extends RefCounted
class_name BattleUIPlayEffect
## Shows a card-type icon in the play zone with a punchy scale + fade animation.

static func show_effect(play_effect_label: Label, card_data: Dictionary) -> void:
	if not play_effect_label:
		return
	var ctype: String = card_data.get("type", "") as String
	var icon := "•"
	var color := Color(1, 1, 1, 1)
	match ctype:
		"ATTACK":
			icon = "⚔"
			color = Color(1, 0.35, 0.3, 1)
		"SKILL":
			icon = "🛡"
			color = Color(0.4, 0.75, 1, 1)
		"POWER":
			icon = "✦"
			color = Color(1, 0.85, 0.2, 1)
		_:
			icon = "•"
	play_effect_label.text = icon
	play_effect_label.visible = true
	play_effect_label.modulate = Color(1, 1, 1, 1)
	play_effect_label.add_theme_color_override("font_color", color)
	play_effect_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	play_effect_label.add_theme_constant_override("outline_size", 5)
	play_effect_label.scale = Vector2(0.28, 0.28)
	play_effect_label.pivot_offset = play_effect_label.size * 0.5
	var t := play_effect_label.create_tween()
	t.tween_property(play_effect_label, "scale", Vector2(2.85, 2.85), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(play_effect_label, "scale", Vector2(2.15, 2.15), 0.11).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(play_effect_label, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	t.finished.connect(func() -> void:
		if play_effect_label:
			play_effect_label.visible = false
			play_effect_label.scale = Vector2.ONE
	)
