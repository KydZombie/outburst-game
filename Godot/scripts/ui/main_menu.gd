extends Control
## Main menu UI: buttons, hover/press animations, scene loading, and music.

const _NinePatch := preload("res://scripts/ui/nine_patch_frame.gd")

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const CREDITS_SCENE_PATH := "res://scenes/credits_scene.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/settings_scene.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/settings_menu_scene.tscn"
const MENU_MUSIC_PATH := "res://audio/music/menu_theme.mp3"
const HOVER_SCALE := 1.04
const PRESS_SCALE := 0.97
const NORMAL_SCALE := 1.0
const TWEEN_DURATION := 0.12

@onready var play_button: Button = $VBox/MenuContainer/PlayButton
@onready var tutorial_button: Button = $VBox/MenuContainer/TutorialButton
@onready var settings_button: Button = $VBox/MenuContainer/SettingsButton
@onready var credits_button: Button = $VBox/MenuContainer/CreditsButton
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _button_tweens: Dictionary = {}


func _ready() -> void:
	_connect_buttons()
	for btn: Button in [play_button, tutorial_button, settings_button, credits_button]:
		_NinePatch.apply_to_button(btn)
		_connect_hover_and_press(btn)
		btn.pivot_offset = btn.size / 2.0
	if music_player:
		if ResourceLoader.exists(MENU_MUSIC_PATH):
			music_player.stream = load(MENU_MUSIC_PATH) as AudioStream
		if music_player.stream:
			if music_player.stream is AudioStreamMP3:
				music_player.stream.loop = true
			music_player.play()
	if animation_player and animation_player.has_animation("title_pulse"):
		animation_player.play("title_pulse")


func _connect_buttons() -> void:
	play_button.pressed.connect(_on_play_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)


func _connect_hover_and_press(btn: Button) -> void:
	btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
	btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))
	btn.button_down.connect(_on_button_down.bind(btn))
	btn.button_up.connect(_on_button_up.bind(btn))


func _on_button_mouse_entered(btn: Button) -> void:
	_stop_tween(btn)
	var t := create_tween()
	_button_tweens[btn] = t
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(btn, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), TWEEN_DURATION)
	t.parallel().tween_property(btn, "modulate", Color(1.12, 1.12, 1.16), TWEEN_DURATION)


func _on_button_mouse_exited(btn: Button) -> void:
	_stop_tween(btn)
	var t := create_tween()
	_button_tweens[btn] = t
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(btn, "scale", Vector2(NORMAL_SCALE, NORMAL_SCALE), TWEEN_DURATION)
	t.parallel().tween_property(btn, "modulate", Color.WHITE, TWEEN_DURATION)


func _on_button_down(btn: Button) -> void:
	_stop_tween(btn)
	btn.scale = Vector2(PRESS_SCALE, PRESS_SCALE)
	btn.modulate = Color(1.2, 1.2, 1.25)


func _on_button_up(btn: Button) -> void:
	var target_scale := HOVER_SCALE if btn.is_hovered() else NORMAL_SCALE
	var target_color := Color(1.12, 1.12, 1.16) if btn.is_hovered() else Color.WHITE
	var t := create_tween()
	_button_tweens[btn] = t
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(btn, "scale", Vector2(target_scale, target_scale), TWEEN_DURATION * 0.5)
	t.parallel().tween_property(btn, "modulate", target_color, TWEEN_DURATION * 0.5)


func _stop_tween(btn: Button) -> void:
	if _button_tweens.get(btn):
		_button_tweens[btn].kill()
		_button_tweens.erase(btn)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE_PATH)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE_PATH)
