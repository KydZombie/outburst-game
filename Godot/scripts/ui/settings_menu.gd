extends Control
## Audio / settings: master volume, difficulty. Persists via GameSettings autoload.

const _NinePatch := preload("res://scripts/ui/nine_patch_frame.gd")

const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"

@onready var back_button: Button = $MarginContainer/VBox/BackButton
@onready var difficulty_option: OptionButton = $MarginContainer/VBox/DifficultyRow/DifficultyOption
@onready var master_slider: HSlider = $MarginContainer/VBox/VolumeRow/MasterSlider


func _ready() -> void:
	_NinePatch.apply_to_button(back_button)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if difficulty_option:
		difficulty_option.clear()
		difficulty_option.add_item("Easy", 0)
		difficulty_option.add_item("Medium", 1)
		difficulty_option.add_item("Hard", 2)
		match GameSettings.difficulty:
			"easy":
				difficulty_option.selected = 0
			"hard":
				difficulty_option.selected = 2
			_:
				difficulty_option.selected = 1
		difficulty_option.item_selected.connect(_on_difficulty_selected)
	if master_slider:
		master_slider.min_value = 0.0
		master_slider.max_value = 1.0
		master_slider.step = 0.05
		master_slider.value = GameSettings.master_volume
		master_slider.value_changed.connect(_on_master_volume_changed)


func _on_difficulty_selected(index: int) -> void:
	var d: String = ["easy", "medium", "hard"][index]
	GameSettings.set_difficulty(d)


func _on_master_volume_changed(v: float) -> void:
	GameSettings.set_master_volume_linear(v)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
