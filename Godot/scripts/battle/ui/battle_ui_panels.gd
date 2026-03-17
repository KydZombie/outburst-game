extends RefCounted
class_name BattleUIPanels
## Updates party list and enemy panel labels/bars from game state. No portraits (use BattleUIPortraits).

static func refresh_party(party_list: Control, party: Array[Dictionary], target_character_index: int = -1) -> void:
	if not party_list:
		return
	for i in range(min(party_list.get_child_count(), party.size())):
		var row := party_list.get_child(i)
		if row is Control:
			(row as Control).modulate = Color(1.15, 1.15, 1.0) if i == target_character_index else Color.WHITE
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
		if name_lbl:
			name_lbl.text = p.get("name", "") as String
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
			bar.value = hp_f
			var ratio: float = hp_f / max_hp_f if max_hp_f > 0.0 else 0.0
			if ratio < 0.5:
				bar.modulate = Color(1.0, 0.0, 0.0, 1.0)
			else:
				bar.modulate = Color(0.3, 1.0, 0.6, 1.0)
		BattleUIPortraits.apply_party_portraits(party_list, party)

static func refresh_enemy(enemy_name: Label, enemy_hp: Label, enemy_portrait: TextureRect, enemies: Array[Dictionary]) -> void:
	if enemies.is_empty():
		return
	var e: Dictionary = enemies[0]
	if enemy_name:
		enemy_name.text = (e.get("name", "") as String).to_upper()
	if enemy_hp:
		var eh: int = e.get("hp", 0) as int
		var emh: int = e.get("max_hp", 60) as int
		enemy_hp.text = "%d / %d" % [eh, emh]
	BattleUIPortraits.apply_enemy_portrait(enemy_portrait, enemies)
