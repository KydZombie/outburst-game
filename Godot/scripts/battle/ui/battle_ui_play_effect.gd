extends RefCounted
class_name BattleUIPlayEffect
## Shows the card-type icon next to the enemy and tweens it out.

static func show_effect(play_effect_label: Label, card_data: Dictionary) -> void:
	if not play_effect_label:
		return
	var ctype: String = card_data.get("type", "") as String
	var icon := "•"
	match ctype:
		"ATTACK":
			icon = "⚔"
		"SKILL":
			icon = "🛡"
		"POWER":
			icon = "✦"
		_:
			icon = "•"
	play_effect_label.text = icon
	play_effect_label.visible = true
	play_effect_label.modulate = Color(1, 1, 1, 1)
	play_effect_label.scale = Vector2.ONE
	var t := play_effect_label.create_tween()
	t.tween_property(play_effect_label, "scale", Vector2(1.6, 1.6), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(play_effect_label, "modulate:a", 0.0, 0.25).from(1.0)
	t.finished.connect(func() -> void:
		if play_effect_label:
			play_effect_label.visible = false
	)
