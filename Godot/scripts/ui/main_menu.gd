extends Control
## Main menu UI: buttons, hover/press animations, scene loading, and music.

const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"
const CREDITS_SCENE_PATH := "res://scenes/credits_scene.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/settings_scene.tscn"
const MENU_MUSIC_PATH := "res://audio/music/menu_theme.mp3"
const HOVER_SCALE := 1.05
const PRESS_SCALE := 0.95
const NORMAL_SCALE := 1.0
const TWEEN_DURATION := 0.15

@onready var play_button: Button = $MenuContainer/PlayButton
@onready var continue_button: Button = $MenuContainer/ContinueButton
@onready var settings_button: Button = $MenuContainer/SettingsButton
@onready var credits_button: Button = $MenuContainer/CreditsButton
@onready var quit_button: Button = $MenuContainer/QuitButton
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _button_tweens: Dictionary = {}


func _ready() -> void:
	# Buttons are required; music and animation are optional
	_connect_buttons()
	_connect_hover_and_press(play_button)
	_connect_hover_and_press(continue_button)
	_connect_hover_and_press(settings_button)
	_connect_hover_and_press(credits_button)
	_connect_hover_and_press(quit_button)
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
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _connect_hover_and_press(btn: Button) -> void:
	btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
	btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))
	btn.button_down.connect(_on_button_down.bind(btn))
	btn.button_up.connect(_on_button_up.bind(btn))


func _on_button_mouse_entered(btn: Button) -> void:
	_stop_tween(btn)
	var t := create_tween()
	_button_tweens[btn] = t
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(btn, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), TWEEN_DURATION)
	t.parallel().tween_property(btn, "modulate", Color(1.15, 1.15, 1.18), TWEEN_DURATION)


func _on_button_mouse_exited(btn: Button) -> void:
	_stop_tween(btn)
	var t := create_tween()
	_button_tweens[btn] = t
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(btn, "scale", Vector2(NORMAL_SCALE, NORMAL_SCALE), TWEEN_DURATION)
	t.parallel().tween_property(btn, "modulate", Color.WHITE, TWEEN_DURATION)


func _on_button_down(btn: Button) -> void:
	_stop_tween(btn)
	btn.scale = Vector2(PRESS_SCALE, PRESS_SCALE)


func _on_button_up(btn: Button) -> void:
	var target_scale := HOVER_SCALE if btn.is_hovered() else NORMAL_SCALE
	var t := create_tween()
	_button_tweens[btn] = t
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(btn, "scale", Vector2(target_scale, target_scale), TWEEN_DURATION * 0.5)


func _stop_tween(btn: Button) -> void:
	if _button_tweens.get(btn):
		_button_tweens[btn].kill()
		_button_tweens.erase(btn)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)


func _on_continue_pressed() -> void:
	# TODO: load save and go to battle or last area
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE_PATH)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
