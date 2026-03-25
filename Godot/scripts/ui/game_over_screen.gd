extends Control
## Game-over screen: shows YOU WIN or LOSS based on BattleResult, with Back to Menu and Retry.

const _NinePatch := preload("res://scripts/ui/nine_patch_frame.gd")

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/battle_scene.tscn"

@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var back_button: Button = $CenterContainer/VBox/ButtonRow/BackToMenuButton
@onready var retry_button: Button = $CenterContainer/VBox/ButtonRow/RetryButton
@onready var win_sfx: AudioStreamPlayer = $SFX_Win
@onready var loss_sfx: AudioStreamPlayer = $SFX_Loss

func _ready() -> void:
	_NinePatch.apply_to_button(back_button)
	_NinePatch.apply_to_button(retry_button)
	if BattleResult.is_win():
		title_label.text = "CONGRATS — YOU WIN!"
		title_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		if win_sfx:
			win_sfx.play()
	else:
		title_label.text = "DEFEAT"
		title_label.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
		if loss_sfx:
			loss_sfx.play()
	if back_button:
		back_button.text = "Main menu"
		back_button.pressed.connect(_on_back_to_menu)
	if retry_button:
		retry_button.pressed.connect(_on_retry)
	BattleResult.clear()

func _on_back_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _on_retry() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
