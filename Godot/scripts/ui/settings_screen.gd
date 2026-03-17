extends Control
## Settings / How to Play page. Back to Menu returns to main menu.

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"

@onready var back_button: Button = $MarginContainer/VBox/BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
