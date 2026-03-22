extends Node
## Autoload: persist master volume, difficulty, and apply to the Master audio bus.

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "audio"
const SECTION_DIFFICULTY := "gameplay"

## "easy" | "medium" | "hard"
var difficulty: String = "medium"

var master_volume: float = 1.0

func _ready() -> void:
	load_settings()
	apply_audio()

func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(CONFIG_PATH) != OK:
		return
	master_volume = float(cf.get_value(SECTION, "master_volume", 1.0))
	master_volume = clampf(master_volume, 0.0, 1.0)
	var d: String = cf.get_value(SECTION_DIFFICULTY, "difficulty", "medium") as String
	if d in ["easy", "medium", "hard"]:
		difficulty = d

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.load(CONFIG_PATH) # merge with any existing keys
	cf.set_value(SECTION, "master_volume", master_volume)
	cf.set_value(SECTION_DIFFICULTY, "difficulty", difficulty)
	cf.save(CONFIG_PATH)

func set_difficulty(d: String) -> void:
	if d in ["easy", "medium", "hard"]:
		difficulty = d
		save_settings()

## Medium: power*3 (30). Hard: 45.
func get_enemy_attack_damage(enemy_power: int) -> int:
	if difficulty == "hard":
		return 45
	return enemy_power * 3

## Medium: max_hp/3. Hard: 25.
func get_enemy_heal_amount(enemy_max_hp: int) -> int:
	if difficulty == "hard":
		return 25
	return int(enemy_max_hp / 3.0)

## Hard: player deals 1.1× damage. Easy/Medium: 2× or 1×.
func get_player_damage_multiplier() -> float:
	match difficulty:
		"easy":
			return 2.0
		"hard":
			return 1.1
		_:
			return 1.0

func is_enemy_spread_attack() -> bool:
	return difficulty == "hard"

func set_master_volume_linear(linear: float) -> void:
	master_volume = clampf(linear, 0.0, 1.0)
	apply_audio()
	save_settings()

func apply_audio() -> void:
	var db: float = linear_to_db(master_volume) if master_volume > 0.001 else -80.0
	var idx: int = AudioServer.get_bus_index("Master")
	if idx < 0:
		idx = 0
	AudioServer.set_bus_volume_db(idx, db)
