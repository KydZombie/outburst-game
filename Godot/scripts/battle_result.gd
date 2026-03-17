extends Node
## Autoload singleton. Holds the last battle result so the game-over scene can display win/loss.
## Set right before changing to the game-over scene.

var result: String = ""

func set_result(win: bool) -> void:
	result = "win" if win else "loss"

func is_win() -> bool:
	return result == "win"

func clear() -> void:
	result = ""
