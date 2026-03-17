extends Control
## Loader: switches to the main menu on next frame so the tree isn't busy during _ready().

func _ready() -> void:
	call_deferred("_goto_main_menu")

func _goto_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
