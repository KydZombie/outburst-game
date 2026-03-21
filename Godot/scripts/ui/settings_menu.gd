extends Control
## Audio / settings: master volume. Persists via GameSettings autoload.

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"

@onready var back_button: Button = $MarginContainer/VBox/BackButton
@onready var master_slider: HSlider = $MarginContainer/VBox/VolumeRow/MasterSlider


func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if master_slider:
		master_slider.min_value = 0.0
		master_slider.max_value = 1.0
		master_slider.step = 0.05
		master_slider.value = GameSettings.master_volume
		master_slider.value_changed.connect(_on_master_volume_changed)


func _on_master_volume_changed(v: float) -> void:
	GameSettings.set_master_volume_linear(v)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
