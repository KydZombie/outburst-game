extends Node
## Autoload: persist master volume and apply to the Master audio bus.

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "audio"

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

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.load(CONFIG_PATH) # merge with any existing keys
	cf.set_value(SECTION, "master_volume", master_volume)
	cf.save(CONFIG_PATH)

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
