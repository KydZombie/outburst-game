extends Button

## Scene path to load when pressed (e.g. res://Scenes/MainMenu/New_game.tscn). Leave empty if quit_on_press is true.
@export var reference_path: String = ""
## If true, this button grabs focus when the menu loads.
@export var start_focused: bool = false
## If true, pressing this button quits the game instead of changing scene.
@export var quit_on_press: bool = false

func _ready() -> void:
	if start_focused:
		call_deferred("grab_focus")
	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	grab_focus()

func _on_pressed() -> void:
	if quit_on_press:
		get_tree().quit()
		return
	if not reference_path.is_empty():
		get_tree().change_scene_to_file(reference_path)
