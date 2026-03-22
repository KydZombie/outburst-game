extends RefCounted
class_name BattleUIRuntime
## Applies battle state to widgets, audio feedback, and screen transitions.

var _owner: Control
var _refs: BattleUINodeRefs
var _hand_manager: HandManager
var _battle_manager: BattleManager
var _deck_manager: DeckManager
var _game_over_scene_path: String
var _prompted_max_plays_pulse: bool = false
var _prev_energy: int = -1
var _turn_banner_layer: CanvasLayer = null
var _turn_banner_label: Label = null
var _turn_banner_tween: Tween
## Per-target shake offsets so concurrent shakes on different Controls never drift.
var _shake_offsets: Dictionary = {}
var _shake_tweens: Dictionary = {}
var _angry_combo_hint_tween: Tween
## Deck / discard list overlay parented to the play zone (only one at a time).
var _card_pile_overlay: Control = null

func setup(
	owner: Control,
	refs: BattleUINodeRefs,
	hand_manager: HandManager,
	battle_manager: BattleManager,
	deck_manager: DeckManager,
	game_over_scene_path: String
) -> void:
	_owner = owner
	_refs = refs
	_hand_manager = hand_manager
	_battle_manager = battle_manager
	_deck_manager = deck_manager
	_game_over_scene_path = game_over_scene_path

func deferred_refresh_hand() -> void:
	if not _hand_manager or not _refs.hand_container:
		return
	var hand: Array[Dictionary] = _deck_manager.get_hand()
	if hand.size() > 0:
		_hand_manager.set_hand_from_data(hand)
	deferred_layout_hand()

func deferred_layout_hand() -> void:
	if _hand_manager and _hand_manager.has_method("_update_fan_layout"):
		_hand_manager._update_fan_layout()

func on_state_changed(state: Dictionary, highlight_idx: int) -> void:
	var party: Array = state.get("party", [])
	var enemies: Array = state.get("enemies", [])
	BattleUIPanels.refresh_party(_refs.party_list, party, highlight_idx)
	BattleUIPanels.refresh_enemy(_refs.enemy_name, _refs.enemy_hp, _refs.enemy_health_bar, _refs.enemy_portrait, enemies)
	var enemy_busy: bool = (state.get("enemy_turn_in_progress", false) as bool) or (state.get("post_enemy_chain_pending", false) as bool)
	if _refs.end_turn_btn:
		_refs.end_turn_btn.disabled = enemy_busy
		_refs.end_turn_btn.modulate = Color(0.55, 0.55, 0.6, 1.0) if enemy_busy else Color.WHITE
	if _refs.draw_card_btn:
		_refs.draw_card_btn.disabled = enemy_busy
		_refs.draw_card_btn.modulate = Color(0.55, 0.55, 0.6, 1.0) if enemy_busy else Color.WHITE
	var turn: int = state.get("turn", 1) as int
	if _refs.turn_counter:
		_refs.turn_counter.text = "ENEMY TURN" if enemy_busy else "TURN %d" % turn
	var played: int = state.get("cards_played_this_turn", 0) as int
	var max_play: int = state.get("max_card_plays_per_turn", TurnManager.MAX_CARD_PLAYS_PER_TURN) as int
	if played >= max_play and not _prompted_max_plays_pulse:
		_prompted_max_plays_pulse = true
		_pulse_end_turn_after_max_plays()
	elif played < max_play:
		_prompted_max_plays_pulse = false
	# After layout/hand sync this frame, refresh Angry Punch combo hints (party may have changed).
	if _owner and _battle_manager:
		_owner.get_tree().create_timer(0.0).timeout.connect(func () -> void:
			if _battle_manager:
				_refresh_play_zone_hints(_battle_manager.get_current_state())
		, CONNECT_ONE_SHOT)

func on_energy_changed(energy: int) -> void:
	if _refs.energy_display:
		_refs.energy_display.text = "ENERGY: %d" % energy
	if _hand_manager:
		_hand_manager.set_energy(energy)
	if _prev_energy >= 0 and energy > _prev_energy:
		var gain: int = energy - _prev_energy
		_spawn_energy_gain_number(gain)
	_prev_energy = energy
	if energy <= 0 and _refs.end_turn_btn and not _refs.end_turn_btn.disabled:
		_check_zero_energy_guidance()
	if _battle_manager:
		_refresh_play_zone_hints(_battle_manager.get_current_state())

func on_enemy_intent_changed(intent_value: int, intent_type: String = "attack", intent_target_count: int = -1) -> void:
	if not _refs.enemy_intent:
		return
	if intent_type == "heal":
		_refs.enemy_intent.text = "Heal %d" % intent_value
	else:
		var suffix: String = ""
		if intent_target_count == 1:
			suffix = " (1)"
		elif intent_target_count >= 2:
			suffix = " (All)" if intent_target_count >= 5 else " (%d)" % intent_target_count
		_refs.enemy_intent.text = "⚔ %d%s" % [intent_value, suffix]

func on_hand_changed(hand: Array[Dictionary]) -> void:
	if _hand_manager:
		_hand_manager.set_hand_from_data(hand)
	deferred_layout_hand()
	var am: AudioManager = _get_audio_manager()
	if am:
		am.draw_card()
	if _battle_manager:
		_refresh_play_zone_hints(_battle_manager.get_current_state())

func on_deck_discard_changed(deck_size: int, discard_size: int) -> void:
	if _refs.deck_counter:
		_refs.deck_counter.text = str(deck_size)
	if _refs.discard_counter:
		_refs.discard_counter.text = str(discard_size)


func refresh_angry_combo_play_zone_hint() -> void:
	if _battle_manager == null:
		return
	_refresh_play_zone_hints(_battle_manager.get_current_state())


## Play zone (same control as ally prompt area): Gain Energy when starved, else Angry Punch combo when hovering that card.
func _refresh_play_zone_hints(state: Dictionary) -> void:
	if _hand_manager == null:
		return
	var enemy_busy: bool = (state.get("enemy_turn_in_progress", false) as bool) or (state.get("post_enemy_chain_pending", false) as bool)
	if enemy_busy:
		_hand_manager.set_angry_combo_highlight(false, [])
		_hide_angry_combo_play_zone_hint()
		return
	var party: Array = state.get("party", [])
	var hand: Array = state.get("hand", [])
	var energy: int = state.get("energy", 0) as int
	var need_angry_hint: bool = _hand_has_id_prefix(hand, "angry_punch") and not _party_has_angry(party)
	if need_angry_hint:
		_hand_manager.set_angry_combo_highlight(true, hand)
	else:
		_hand_manager.set_angry_combo_highlight(false, hand)
	if _refs.target_prompt and _refs.target_prompt.visible:
		_hide_angry_combo_play_zone_hint()
		return
	if energy <= 0 and _hand_has_gain_energy_in_hand(hand):
		_show_play_zone_hint_message("PLAY THE GAIN ENERGY CARD TO GET ENERGY")
		return
	if need_angry_hint and _should_show_angry_combo_play_zone_hint():
		var has_get_angry: bool = _hand_has_id_prefix(hand, "get_angry")
		var msg: String = "PLAY GET ANGRY ON AN ALLY BEFORE ANGRY PUNCH" if has_get_angry else "DRAW A GET ANGRY AND PLAY IT BEFORE ANGRY PUNCH"
		_show_play_zone_hint_message(msg)
		return
	_hide_angry_combo_play_zone_hint()


func _is_interacting_with_angry_punch() -> bool:
	var hid: String = ""
	var did: String = ""
	if _hand_manager:
		if _hand_manager.has_method("get_hovered_card_id"):
			hid = _hand_manager.get_hovered_card_id()
		if _hand_manager.has_method("get_dragging_card_id"):
			did = _hand_manager.get_dragging_card_id()
	return hid.begins_with("angry_punch") or did.begins_with("angry_punch")


func _should_show_angry_combo_play_zone_hint() -> bool:
	return _is_interacting_with_angry_punch()


func _hide_angry_combo_play_zone_hint() -> void:
	if _angry_combo_hint_tween and _angry_combo_hint_tween.is_valid():
		_angry_combo_hint_tween.kill()
	_angry_combo_hint_tween = null
	if _refs.angry_combo_hint:
		_refs.angry_combo_hint.visible = false
		_refs.angry_combo_hint.modulate = Color.WHITE


func _hand_has_gain_energy_in_hand(hand: Array) -> bool:
	for c in hand:
		if (c.get("id", "") as String).begins_with("gain_energy"):
			return true
	return false


func _show_play_zone_hint_message(msg: String) -> void:
	if not _refs.angry_combo_hint:
		return
	if _refs.target_prompt and _refs.target_prompt.visible:
		_hide_angry_combo_play_zone_hint()
		return
	BattleHintTheme.apply_play_zone_richtext(_refs.angry_combo_hint)
	var was_visible: bool = _refs.angry_combo_hint.visible
	var text_changed: bool = _refs.angry_combo_hint.text != msg
	_refs.angry_combo_hint.text = msg
	_refs.angry_combo_hint.visible = true
	if text_changed or not was_visible:
		_start_angry_combo_hint_glow()


## Shows "NIKO IS DEAD" in play zone briefly (bold, red, same font size). Auto-hides after duration.
func show_dead_play_zone_briefly(msg: String, duration: float = 2.5) -> void:
	if not _refs.angry_combo_hint or not _owner:
		return
	_hide_angry_combo_play_zone_hint()
	BattleHintTheme.apply_death_play_zone_richtext(_refs.angry_combo_hint)
	_refs.angry_combo_hint.bbcode_enabled = true
	_refs.angry_combo_hint.text = "[b]%s[/b]" % msg
	_refs.angry_combo_hint.visible = true
	_refs.angry_combo_hint.modulate = Color.WHITE
	if _angry_combo_hint_tween and _angry_combo_hint_tween.is_valid():
		_angry_combo_hint_tween.kill()
	_angry_combo_hint_tween = null
	var tree: SceneTree = _owner.get_tree()
	if tree:
		tree.create_timer(duration).timeout.connect(func() -> void:
			if _refs.angry_combo_hint and is_instance_valid(_refs.angry_combo_hint):
				_refs.angry_combo_hint.visible = false
			_angry_combo_hint_tween = null
			if _battle_manager:
				_refresh_play_zone_hints(_battle_manager.get_current_state())
		, CONNECT_ONE_SHOT)


func _start_angry_combo_hint_glow() -> void:
	if not _refs.angry_combo_hint or not _owner:
		return
	if _angry_combo_hint_tween and _angry_combo_hint_tween.is_valid():
		_angry_combo_hint_tween.kill()
	_angry_combo_hint_tween = _owner.create_tween().set_loops()
	_angry_combo_hint_tween.tween_property(_refs.angry_combo_hint, "modulate", Color(1.22, 1.25, 1.0, 1.0), 0.55)
	_angry_combo_hint_tween.tween_property(_refs.angry_combo_hint, "modulate", Color.WHITE, 0.55)


func _hand_has_id_prefix(hand: Array, prefix: String) -> bool:
	for c in hand:
		if (c.get("id", "") as String).begins_with(prefix):
			return true
	return false


func _party_has_angry(party: Array) -> bool:
	for p in party:
		if (p.get("hp", 0) as int) <= 0:
			continue
		var em: Dictionary = p.get("emotions", {}) as Dictionary
		if (em.get("Angry", 0) as int) >= 1:
			return true
	return false


func refresh_initial_state() -> Dictionary:
	var state: Dictionary = _battle_manager.get_current_state()
	on_state_changed(state, -1)
	on_energy_changed(state.get("energy", 0))
	var enemies: Array = state.get("enemies", [])
	if enemies.size() > 0:
		var e0: Dictionary = enemies[0]
		on_enemy_intent_changed(e0.get("intent_value", 30) as int, e0.get("intent_type", "attack") as String, e0.get("intent_target_count", -1) as int)
	on_deck_discard_changed(state.get("deck_size", 0), state.get("discard_size", 0))
	var hand: Array = state.get("hand", [])
	if _hand_manager and hand.size() > 0:
		_hand_manager.set_hand_from_data(hand)
	deferred_layout_hand()
	_refresh_play_zone_hints(state)
	return state

func on_card_played_from_logic(card_data: Dictionary) -> void:
	var cid: String = card_data.get("id", "") as String
	# Punches: play slash SFX with Jeff hit VFX (not here — avoids lead vs deferred VFX).
	if not (cid.begins_with("basic_punch") or cid.begins_with("angry_punch")):
		var am: AudioManager = _get_audio_manager()
		if am:
			am.play_card()
	BattleUIPlayEffect.show_effect(_refs.play_effect, card_data)

func on_battle_ended(result: String) -> void:
	BattleResult.set_result(result == "win")
	if _owner == null or not is_instance_valid(_owner):
		return
	# On loss, delay so the death banner (e.g. "NIKO IS DEAD") can display before game over.
	var delay: float = 0.0
	if result == "loss":
		delay = 3.5
	if delay > 0:
		var tree: SceneTree = _owner.get_tree()
		if tree:
			tree.create_timer(delay).timeout.connect(func() -> void:
				if _owner and is_instance_valid(_owner):
					_owner.transition_to_game_over(_game_over_scene_path)
			, CONNECT_ONE_SHOT)
	else:
		_owner.call_deferred("transition_to_game_over", _game_over_scene_path)

func _pulse_end_turn_after_max_plays() -> void:
	if not _refs.end_turn_btn:
		return
	var pulse: Tween = _owner.create_tween()
	pulse.tween_property(_refs.end_turn_btn, "modulate", Color(1.35, 1.35, 1.0, 1.0), 0.12)
	pulse.tween_property(_refs.end_turn_btn, "modulate", Color.WHITE, 0.28)
	var bump: Tween = _owner.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bump.tween_property(_refs.end_turn_btn, "scale", Vector2(1.08, 1.08), 0.14)
	bump.tween_property(_refs.end_turn_btn, "scale", Vector2(1, 1), 0.18)

func on_end_turn_hover(entered: bool) -> void:
	if not _refs.end_turn_btn:
		return
	_refs.end_turn_btn.modulate = Color(1.15, 1.15, 1.15) if entered else Color.WHITE
	var t: Tween = _owner.create_tween()
	if entered:
		t.tween_property(_refs.end_turn_btn, "scale", Vector2(1.05, 1.05), 0.1)
	else:
		t.tween_property(_refs.end_turn_btn, "scale", Vector2(1, 1), 0.1)

func on_enemy_hit(damage: int) -> void:
	# Run next frame so party/enemy refresh from state_changed finishes first (avoids killing the hit read).
	var tree := _owner.get_tree()
	if tree == null:
		return
	var dmg_copy: int = damage
	tree.create_timer(0.0).timeout.connect(func() -> void:
		_play_enemy_hit_vfx(dmg_copy)
	, CONNECT_ONE_SHOT)


func _play_enemy_hit_vfx(damage: int) -> void:
	if _owner == null or not is_instance_valid(_owner):
		return
	# Jeff portrait + HP block — same as enemy charge-up; whole RightPanel was too subtle behind theme.
	var panel: Control = _refs.enemy_panel if _refs.enemy_panel and is_instance_valid(_refs.enemy_panel) else _refs.right_panel
	if panel == null:
		return
	var am_hit: AudioManager = _get_audio_manager()
	if am_hit:
		am_hit.play_card()

	var flash := _owner.create_tween()
	flash.tween_property(panel, "modulate", Color(2.0, 1.8, 1.8, 1.0), 0.04)
	flash.tween_property(panel, "modulate", Color(1.6, 0.3, 0.2, 1.0), 0.06)
	flash.tween_property(panel, "modulate", Color.WHITE, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	_screen_shake(panel, 7.0, 0.28)

	if panel.size.x > 2.0 and panel.size.y > 2.0:
		panel.pivot_offset = panel.size * 0.5
	elif panel.pivot_offset == Vector2.ZERO:
		panel.pivot_offset = Vector2(110, 100)
	var punch := _owner.create_tween()
	punch.tween_property(panel, "scale", Vector2(1.08, 0.92), 0.05).set_trans(Tween.TRANS_CUBIC)
	punch.tween_property(panel, "scale", Vector2(0.96, 1.04), 0.06).set_trans(Tween.TRANS_CUBIC)
	punch.tween_property(panel, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	if damage > 0:
		_spawn_damage_number(panel, damage, Color(1, 0.92, 0.25, 1), 32, true)
	else:
		_spawn_damage_number(panel, 0, Color(0.75, 0.78, 0.95, 1), 26, true)

func on_enemy_attack(target_idx: int, damage: int) -> void:
	if not _refs.party_list:
		return
	if target_idx < 0 or target_idx >= _refs.party_list.get_child_count():
		return
	var row: Control = _refs.party_list.get_child(target_idx) as Control
	if not row:
		return
	_enemy_attack_stage1(row, damage)

func _enemy_attack_stage1(row: Control, damage: int) -> void:
	# Prefer EnemyPanel (Jeff portrait + HP) so the charge reads clearly; fall back to RightPanel.
	var ep: Control = _refs.enemy_panel if _refs.enemy_panel and is_instance_valid(_refs.enemy_panel) else _refs.right_panel
	if not ep:
		_enemy_attack_stage2(row, damage)
		return
	# Scale from center; fallback pivot if layout not ready yet.
	if ep.size.x > 2.0 and ep.size.y > 2.0:
		ep.pivot_offset = ep.size * 0.5
	else:
		ep.pivot_offset = Vector2(120, 140)
	var charge := _owner.create_tween()
	charge.tween_property(ep, "scale", Vector2(1.15, 1.15), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	charge.parallel().tween_property(ep, "modulate", Color(1.6, 0.4, 0.3, 1.0), 0.28)
	charge.tween_property(ep, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	charge.parallel().tween_property(ep, "modulate", Color.WHITE, 0.22)
	charge.tween_interval(0.55)
	# Do not use .bind() here — RefCounted callables + tween_callback can skip Stage 2 (same class of bug as screen shake).
	charge.tween_callback(func() -> void: _enemy_attack_stage2(row, damage))

func _enemy_attack_stage2(row: Control, damage: int) -> void:
	var am_atk: AudioManager = _get_audio_manager()
	if am_atk:
		am_atk.play_enemy_attack_hit()
	var flash := _owner.create_tween()
	flash.tween_property(row, "modulate", Color(2.0, 1.8, 1.8, 1.0), 0.07)
	flash.tween_property(row, "modulate", Color(1.8, 0.2, 0.15, 1.0), 0.1)
	flash.tween_property(row, "modulate", Color.WHITE, 0.42).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	_screen_shake(row, 4.5, 0.32)
	_spawn_damage_number(row, damage, Color(1, 0.3, 0.25, 1), 24, false)

	var state: Dictionary = _battle_manager.get_current_state()
	var party: Array = state.get("party", [])
	var idx: int = row.get_index()
	if idx >= 0 and idx < party.size():
		var p: Dictionary = party[idx]
		var hp_after: int = p.get("hp", 0) as int
		var sad: int = (p.get("emotions", {}) as Dictionary).get("Sad", 0) as int
		# CombatResolver adds Sad only when the target survives (hp > 0) after the hit.
		if hp_after > 0 and sad > 0 and damage > 0:
			_spawn_buff_number(row, "+😢", Color(0.4, 0.6, 1.0, 1.0), 18)

func _spawn_damage_number(parent: Control, damage: int, color: Color, font_size: int, center_x: bool) -> void:
	var dmg_label := Label.new()
	dmg_label.text = "-%d" % damage if damage > 0 else "0"
	dmg_label.add_theme_color_override("font_color", color)
	dmg_label.add_theme_font_size_override("font_size", font_size)
	dmg_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	dmg_label.add_theme_constant_override("outline_size", 3)
	dmg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dmg_label.z_index = 10
	parent.add_child(dmg_label)

	var x_pos: float = parent.size.x * 0.5 - 20 if center_x else parent.size.x * 0.5 - 16
	var y_pos: float = parent.size.y * 0.35 if center_x else -4.0
	dmg_label.position = Vector2(x_pos, y_pos)
	dmg_label.scale = Vector2(0.5, 0.5)
	dmg_label.pivot_offset = Vector2(20, float(font_size) * 0.5)

	var t := _owner.create_tween()
	t.tween_property(dmg_label, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(dmg_label, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_CUBIC)

	var float_tween := _owner.create_tween()
	float_tween.tween_interval(0.15)
	float_tween.set_parallel(true)
	float_tween.tween_property(dmg_label, "position:y", y_pos - 40, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	float_tween.tween_property(dmg_label, "modulate:a", 0.0, 0.55).set_delay(0.2).set_ease(Tween.EASE_IN)
	float_tween.chain().tween_callback(dmg_label.queue_free)

func _screen_shake(target: Control, intensity: float, duration: float) -> void:
	var tid: int = target.get_instance_id()
	if _shake_tweens.has(tid) and _shake_tweens[tid] is Tween:
		var old_tw: Tween = _shake_tweens[tid] as Tween
		if old_tw.is_running():
			old_tw.kill()
		_finish_shake_for(target)
	_shake_offsets[tid] = Vector2.ZERO
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var phase0 := rng.randf() * TAU
	var shake := _owner.create_tween()
	_shake_tweens[tid] = shake
	# tween_method only passes the interpolated float; avoid .bind() on RefCounted methods (Godot may not merge args).
	var shake_target: Control = target
	var shake_phase0: float = phase0
	var shake_intensity: float = intensity
	shake.tween_method(
		func(phase: float) -> void:
			_apply_shake_offset(shake_target, shake_phase0, shake_intensity, phase),
		0.0,
		1.0,
		duration
	).set_trans(Tween.TRANS_SINE)
	shake.tween_callback(_finish_shake_for.bind(target))

func _apply_shake_offset(ctrl: Control, phase0: float, intensity: float, phase: float) -> void:
	if ctrl == null or not is_instance_valid(ctrl):
		return
	var shake_tid: int = ctrl.get_instance_id()
	var prev: Vector2 = _shake_offsets.get(shake_tid, Vector2.ZERO) as Vector2
	var decay: float = 1.0 - phase
	var s: float = intensity * decay
	var new_off := Vector2(
		sin(phase * 24.0 + phase0) * s,
		cos(phase * 21.0 + phase0 * 0.73) * s
	)
	ctrl.position -= prev
	_shake_offsets[shake_tid] = new_off
	ctrl.position += new_off

func _finish_shake_for(ctrl: Control) -> void:
	if ctrl == null or not is_instance_valid(ctrl):
		return
	var tid: int = ctrl.get_instance_id()
	var prev: Vector2 = _shake_offsets.get(tid, Vector2.ZERO) as Vector2
	ctrl.position -= prev
	_shake_offsets.erase(tid)
	_shake_tweens.erase(tid)
	var parent: Node = ctrl.get_parent()
	if parent and parent is Container:
		(parent as Container).queue_sort()

func _spawn_energy_gain_number(gain: int) -> void:
	if not _refs.energy_display:
		return
	var energy_box: Control = _refs.energy_display.get_parent() as Control
	if not energy_box:
		energy_box = _refs.energy_display
	var lbl := Label.new()
	lbl.text = "+%d" % gain
	lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.z_index = 12
	energy_box.add_child(lbl)

	lbl.position = Vector2(energy_box.size.x * 0.5 - 14, -6.0)
	lbl.scale = Vector2(0.4, 0.4)
	lbl.pivot_offset = Vector2(14, 11)

	var pop := _owner.create_tween()
	pop.tween_property(lbl, "scale", Vector2(1.4, 1.4), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(lbl, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_CUBIC)

	var drift := _owner.create_tween()
	drift.tween_interval(0.12)
	drift.set_parallel(true)
	drift.tween_property(lbl, "position:y", -38.0, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	drift.tween_property(lbl, "modulate:a", 0.0, 0.45).set_delay(0.3).set_ease(Tween.EASE_IN)
	drift.chain().tween_callback(lbl.queue_free)

func _pulse_end_turn_button_hint() -> void:
	if not _refs.end_turn_btn or _refs.end_turn_btn.disabled:
		return
	var p := _owner.create_tween()
	p.tween_property(_refs.end_turn_btn, "modulate", Color(1.35, 1.35, 1.05, 1.0), 0.12)
	p.tween_property(_refs.end_turn_btn, "modulate", Color.WHITE, 0.25)


func _check_zero_energy_guidance() -> void:
	# Gain Energy nudge lives in the play zone (AngryComboHint); no duplicate yellow turn banner.
	var hand: Array[Dictionary] = _deck_manager.get_hand()
	for c in hand:
		if (c.get("id", "") as String).begins_with("gain_energy"):
			return
	_pulse_end_turn_button_hint()

func on_ally_buffed(target_idx: int, card_data: Dictionary) -> void:
	if not _refs.party_list:
		return
	if target_idx < 0 or target_idx >= _refs.party_list.get_child_count():
		return
	var row: Control = _refs.party_list.get_child(target_idx) as Control
	if not row:
		return

	var flash := _owner.create_tween()
	flash.tween_property(row, "modulate", Color(2.0, 1.9, 1.2, 1.0), 0.05)
	flash.tween_property(row, "modulate", Color(1.0, 0.9, 0.3, 1.0), 0.08)
	flash.tween_property(row, "modulate", Color.WHITE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	var card_id: String = card_data.get("id", "") as String
	var buff_text: String = "✦"
	if card_id.begins_with("cheer_up"):
		buff_text = "+😊"
	elif card_id.begins_with("get_angry"):
		buff_text = "+😡"
	_spawn_buff_number(row, buff_text, Color(1.0, 0.85, 0.2, 1.0), 22)

func _spawn_buff_number(parent: Control, text: String, color: Color, font_size: int) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.z_index = 10
	parent.add_child(lbl)

	var x_pos: float = parent.size.x * 0.5 - 16
	var y_pos: float = -4.0
	lbl.position = Vector2(x_pos, y_pos)
	lbl.scale = Vector2(0.5, 0.5)
	lbl.pivot_offset = Vector2(16, float(font_size) * 0.5)

	var pop := _owner.create_tween()
	pop.tween_property(lbl, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(lbl, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_CUBIC)

	var drift := _owner.create_tween()
	drift.tween_interval(0.15)
	drift.set_parallel(true)
	drift.tween_property(lbl, "position:y", y_pos - 35, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	drift.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.25).set_ease(Tween.EASE_IN)
	drift.chain().tween_callback(lbl.queue_free)

func _stop_turn_banner() -> void:
	if _turn_banner_tween and _turn_banner_tween.is_valid():
		_turn_banner_tween.kill()
	_turn_banner_tween = null
	if _turn_banner_label and is_instance_valid(_turn_banner_label):
		_turn_banner_label.modulate = Color(1, 1, 1, 0)
	if _turn_banner_layer and is_instance_valid(_turn_banner_layer):
		_turn_banner_layer.visible = false


func show_turn_banner(text: String, duration: float = 1.0) -> void:
	_ensure_turn_banner()
	if not _turn_banner_label:
		return
	_stop_turn_banner()
	_turn_banner_label.text = text
	_turn_banner_layer.visible = true
	_turn_banner_label.modulate = Color(1, 1, 1, 0)
	_turn_banner_tween = _owner.create_tween()
	var t: Tween = _turn_banner_tween
	t.tween_property(_turn_banner_label, "modulate:a", 1.0, 0.18)
	t.tween_interval(duration)
	t.tween_property(_turn_banner_label, "modulate:a", 0.0, 0.35)
	t.tween_callback(func() -> void:
		_turn_banner_tween = null
		if _turn_banner_layer:
			_turn_banner_layer.visible = false
	)

func _ensure_turn_banner() -> void:
	if _turn_banner_layer and is_instance_valid(_turn_banner_layer):
		return
	_turn_banner_layer = CanvasLayer.new()
	_turn_banner_layer.layer = 120
	_owner.add_child(_turn_banner_layer)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_banner_layer.add_child(center)
	_turn_banner_label = Label.new()
	_turn_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	BattleHintTheme.apply_turn_banner(_turn_banner_label)
	center.add_child(_turn_banner_label)

func on_player_turn_ready(turn: int) -> void:
	show_turn_banner("YOUR TURN — ROUND %d" % turn, 1.0)

func on_enemy_turn_started() -> void:
	# Hold long enough to read; lines up ~with battle_manager delay before Jeff acts.
	show_turn_banner("ENEMY TURN — JEFF ATTACKS", 2.1)

func on_turn_auto_skipped(reason: String) -> void:
	if reason == "post_enemy_no_actions":
		return
	# Long hold so the player can read the message before the turn auto-passes.
	match reason:
		"empty_hand":
			show_turn_banner("Empty hand — passing turn", 2.6)
		"no_actions":
			# Never use a center banner here: it flashes before ENEMY TURN / Jeff chain and reads like a bug.
			# Battle still auto-passes on the battle_manager timer; nudge End Turn only when it's usable.
			_pulse_end_turn_button_hint()
		_:
			show_turn_banner("No playable cards — turn skipped", 2.6)

func on_deck_reshuffled() -> void:
	show_turn_banner("DECK RESHUFFLED!", 0.6)

func on_dead_member_selection_attempted(party_index: int) -> void:
	var state: Dictionary = _battle_manager.get_current_state() if _battle_manager else {}
	var party: Array = state.get("party", [])
	var name_str: String = "A party member"
	if party_index >= 0 and party_index < party.size():
		var p: Dictionary = party[party_index]
		name_str = p.get("name", "A party member") as String
	show_dead_play_zone_briefly("%s IS DEAD" % name_str.to_upper(), 2.5)

func on_party_member_died(member_idx: int) -> void:
	var state: Dictionary = _battle_manager.get_current_state() if _battle_manager else {}
	var party: Array = state.get("party", [])
	var name_str: String = "A party member"
	if member_idx >= 0 and member_idx < party.size():
		var p: Dictionary = party[member_idx]
		name_str = p.get("name", "A party member") as String
	show_death_banner("%s IS DEAD" % name_str.to_upper(), 2.8)
	show_dead_play_zone_briefly("%s IS DEAD" % name_str.to_upper(), 2.5)

func show_death_banner(text: String, duration: float = 2.8) -> void:
	_ensure_turn_banner()
	if not _turn_banner_label:
		return
	_stop_turn_banner()
	BattleHintTheme.apply_death_banner(_turn_banner_label)
	_turn_banner_label.text = text
	_turn_banner_layer.visible = true
	_turn_banner_label.modulate = Color(1, 1, 1, 0)
	_turn_banner_tween = _owner.create_tween()
	var t: Tween = _turn_banner_tween
	t.tween_property(_turn_banner_label, "modulate:a", 1.0, 0.2)
	t.tween_interval(duration)
	t.tween_property(_turn_banner_label, "modulate:a", 0.0, 0.4)
	t.tween_callback(func() -> void:
		_turn_banner_tween = null
		if _turn_banner_layer:
			_turn_banner_layer.visible = false
		BattleHintTheme.apply_turn_banner(_turn_banner_label)
	)

func on_enemy_healed(amount: int) -> void:
	if amount <= 0 or not _refs.right_panel:
		return
	var panel: Control = _refs.right_panel as Control
	var flash := _owner.create_tween()
	flash.tween_property(panel, "modulate", Color(1.2, 2.0, 1.3, 1.0), 0.06)
	flash.tween_property(panel, "modulate", Color(0.35, 0.95, 0.45, 1.0), 0.1)
	flash.tween_property(panel, "modulate", Color.WHITE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_spawn_heal_number_on_enemy(panel, amount)

func _spawn_heal_number_on_enemy(panel: Control, amount: int) -> void:
	var lbl := Label.new()
	lbl.text = "+%d" % amount
	lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55, 1.0))
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.z_index = 10
	panel.add_child(lbl)
	var y_pos: float = panel.size.y * 0.25
	lbl.position = Vector2(panel.size.x * 0.5 - 24, y_pos)
	lbl.scale = Vector2(0.5, 0.5)
	var t := _owner.create_tween()
	t.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "scale", Vector2.ONE, 0.1)
	var drift := _owner.create_tween()
	drift.tween_interval(0.12)
	drift.set_parallel(true)
	drift.tween_property(lbl, "position:y", y_pos - 36, 0.65).set_ease(Tween.EASE_OUT)
	drift.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.25).set_ease(Tween.EASE_IN)
	drift.chain().tween_callback(lbl.queue_free)

func show_deck_list_popup() -> void:
	_show_card_pile_popup("DECK", _deck_manager.get_deck_preview_entries(), _deck_manager.get_deck_size())

func show_discard_list_popup() -> void:
	_show_card_pile_popup("DISCARD", _deck_manager.get_discard_preview_entries(), _deck_manager.get_discard_size())


func _show_card_pile_popup(window_title: String, entries: Array[Dictionary], total: int) -> void:
	if _card_pile_overlay != null and is_instance_valid(_card_pile_overlay):
		_card_pile_overlay.queue_free()
		_card_pile_overlay = null

	var host: Control = (_refs.play_zone as Control) if _refs.play_zone else _owner
	if host == null:
		host = _owner

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.z_index = 25
	host.add_child(root)
	_card_pile_overlay = root
	root.tree_exited.connect(func() -> void:
		if _card_pile_overlay == root:
			_card_pile_overlay = null
	)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.05, 0.1, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				root.queue_free()
	)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.08, 0.14, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.45, 0.6, 0.92, 0.55)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.content_margin_left = 20
	panel_style.content_margin_top = 16
	panel_style.content_margin_right = 20
	panel_style.content_margin_bottom = 16
	panel_style.shadow_color = Color(0, 0, 0, 0.45)
	panel_style.shadow_size = 10
	panel_style.shadow_offset = Vector2(0, 4)

	var shell := PanelContainer.new()
	shell.mouse_filter = Control.MOUSE_FILTER_STOP
	shell.add_theme_stylebox_override("panel", panel_style)
	var max_w: float = maxf(320.0, host.size.x - 28.0)
	var max_h: float = maxf(260.0, host.size.y - 28.0)
	shell.custom_minimum_size = Vector2(minf(700.0, max_w), minf(440.0, max_h))
	center.add_child(shell)

	var root_margin := MarginContainer.new()
	root_margin.add_theme_constant_override("margin_left", 20)
	root_margin.add_theme_constant_override("margin_top", 12)
	root_margin.add_theme_constant_override("margin_right", 20)
	root_margin.add_theme_constant_override("margin_bottom", 16)
	shell.add_child(root_margin)

	var outer := VBoxContainer.new()
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 12)
	root_margin.add_child(outer)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	outer.add_child(title_row)

	var ttl := Label.new()
	ttl.text = window_title
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ttl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ttl.add_theme_font_size_override("font_size", 24)
	ttl.add_theme_color_override("font_color", Color(0.96, 0.94, 0.9, 1))
	ttl.add_theme_color_override("font_outline_color", Color(0.2, 0.35, 0.65, 0.9))
	ttl.add_theme_constant_override("outline_size", 3)
	title_row.add_child(ttl)

	var close_x := Button.new()
	close_x.text = "✕"
	close_x.focus_mode = Control.FOCUS_NONE
	close_x.custom_minimum_size = Vector2(40, 36)
	close_x.add_theme_font_size_override("font_size", 18)
	close_x.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95, 1))
	close_x.flat = true
	close_x.pressed.connect(func() -> void:
		if is_instance_valid(root):
			root.queue_free()
	)
	title_row.add_child(close_x)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 420
	split.add_theme_constant_override("separation", 20)
	outer.add_child(split)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(scroll)

	var list_col := VBoxContainer.new()
	list_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_col.add_theme_constant_override("separation", 8)
	scroll.add_child(list_col)

	if entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "— Empty —"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		empty_lbl.add_theme_font_size_override("font_size", 22)
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.82, 0.95))
		list_col.add_child(empty_lbl)
	else:
		for e in entries:
			var row := Label.new()
			var n: int = int(e.get("count", 1))
			var t: String = str(e.get("title", "?"))
			row.text = "%d× %s" % [n, t] if n != 1 else "1× %s" % t
			row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_theme_font_size_override("font_size", 22)
			row.add_theme_color_override("font_color", Color(0.92, 0.9, 0.86, 1))
			row.add_theme_color_override("font_outline_color", Color(0.12, 0.18, 0.32, 0.85))
			row.add_theme_constant_override("outline_size", 3)
			list_col.add_child(row)

	var summary_panel := PanelContainer.new()
	summary_panel.custom_minimum_size = Vector2(220, 0)
	var sum_style := StyleBoxFlat.new()
	sum_style.bg_color = Color(0.1, 0.13, 0.22, 0.92)
	sum_style.border_width_left = 1
	sum_style.border_width_top = 1
	sum_style.border_width_right = 1
	sum_style.border_width_bottom = 1
	sum_style.border_color = Color(0.35, 0.48, 0.75, 0.45)
	sum_style.corner_radius_top_left = 10
	sum_style.corner_radius_top_right = 10
	sum_style.corner_radius_bottom_right = 10
	sum_style.corner_radius_bottom_left = 10
	sum_style.content_margin_left = 16
	sum_style.content_margin_top = 14
	sum_style.content_margin_right = 16
	sum_style.content_margin_bottom = 14
	summary_panel.add_theme_stylebox_override("panel", sum_style)
	split.add_child(summary_panel)

	var summary_v := VBoxContainer.new()
	summary_v.add_theme_constant_override("separation", 10)
	summary_panel.add_child(summary_v)

	var total_lbl := Label.new()
	total_lbl.text = "Total cards"
	total_lbl.add_theme_font_size_override("font_size", 16)
	total_lbl.add_theme_color_override("font_color", Color(0.7, 0.74, 0.88, 0.9))
	summary_v.add_child(total_lbl)

	var total_val := Label.new()
	total_val.text = str(total)
	total_val.add_theme_font_size_override("font_size", 36)
	total_val.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55, 1))
	total_val.add_theme_color_override("font_outline_color", Color(0.2, 0.25, 0.45, 0.9))
	total_val.add_theme_constant_override("outline_size", 4)
	summary_v.add_child(total_val)

	var sep := HSeparator.new()
	summary_v.add_child(sep)

	var by_type_lbl := Label.new()
	by_type_lbl.text = "By card type"
	by_type_lbl.add_theme_font_size_override("font_size", 16)
	by_type_lbl.add_theme_color_override("font_color", Color(0.7, 0.74, 0.88, 0.9))
	summary_v.add_child(by_type_lbl)

	var type_counts: Dictionary = {}
	for e in entries:
		var ty: String = str(e.get("type", "CARD"))
		var c: int = int(e.get("count", 0))
		type_counts[ty] = int(type_counts.get(ty, 0)) + c
	var type_order: Array[String] = ["ATTACK", "SKILL", "POWER", "CARD"]
	for ty in type_order:
		if not type_counts.has(ty):
			continue
		var line := Label.new()
		line.text = "%s: %d" % [_friendly_card_type(ty), int(type_counts[ty])]
		line.add_theme_font_size_override("font_size", 18)
		line.add_theme_color_override("font_color", Color(0.88, 0.9, 0.96, 1))
		summary_v.add_child(line)
	for ty in type_counts.keys():
		if type_order.has(ty):
			continue
		var line2 := Label.new()
		line2.text = "%s: %d" % [ty, int(type_counts[ty])]
		line2.add_theme_font_size_override("font_size", 18)
		line2.add_theme_color_override("font_color", Color(0.88, 0.9, 0.96, 1))
		summary_v.add_child(line2)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	outer.add_child(btn_row)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(200, 48)
	close_btn.add_theme_font_size_override("font_size", 20)
	var bn := StyleBoxFlat.new()
	bn.bg_color = Color(0.08, 0.1, 0.18, 0.88)
	bn.border_width_left = 2
	bn.border_width_top = 2
	bn.border_width_right = 2
	bn.border_width_bottom = 2
	bn.border_color = Color(1, 1, 1, 0.35)
	bn.corner_radius_top_left = 10
	bn.corner_radius_top_right = 10
	bn.corner_radius_bottom_right = 10
	bn.corner_radius_bottom_left = 10
	bn.content_margin_left = 20
	bn.content_margin_top = 10
	bn.content_margin_right = 20
	bn.content_margin_bottom = 10
	var bh := StyleBoxFlat.new()
	bh.bg_color = Color(0.12, 0.15, 0.26, 0.95)
	bh.border_width_left = 2
	bh.border_width_top = 2
	bh.border_width_right = 2
	bh.border_width_bottom = 2
	bh.border_color = Color(1, 1, 1, 0.75)
	bh.corner_radius_top_left = 10
	bh.corner_radius_top_right = 10
	bh.corner_radius_bottom_right = 10
	bh.corner_radius_bottom_left = 10
	bh.shadow_color = Color(1, 1, 1, 0.15)
	bh.shadow_size = 6
	bh.content_margin_left = 20
	bh.content_margin_top = 10
	bh.content_margin_right = 20
	bh.content_margin_bottom = 10
	var bp := bn.duplicate() as StyleBoxFlat
	bp.bg_color = Color(0.16, 0.2, 0.34, 0.95)
	bp.border_color = Color(1, 1, 1, 0.9)
	close_btn.add_theme_stylebox_override("normal", bn)
	close_btn.add_theme_stylebox_override("hover", bh)
	close_btn.add_theme_stylebox_override("pressed", bp)
	close_btn.add_theme_stylebox_override("focus", bh)
	close_btn.pressed.connect(func() -> void:
		if is_instance_valid(root):
			root.queue_free()
	)
	btn_row.add_child(close_btn)


func _friendly_card_type(ctype: String) -> String:
	match ctype:
		"ATTACK":
			return "Attacks"
		"SKILL":
			return "Skills"
		"POWER":
			return "Powers"
		_:
			return ctype

func _get_audio_manager() -> AudioManager:
	if _owner == null or not is_instance_valid(_owner):
		return null
	var tree := _owner.get_tree()
	if tree == null:
		return null
	var root: Window = tree.get_root()
	if root == null:
		return null
	return root.get_node_or_null("BattleScene/AudioManager") as AudioManager
