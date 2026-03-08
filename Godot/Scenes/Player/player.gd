class_name Player
extends Node2D

@export var stats: CharacterStats: set = set_character_stats
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var stats_ui: StatsUI = $StatsUI


func set_character_stats(value: CharacterStats) -> void:
	if value == null:
		return
	stats = value.create_instance() as CharacterStats
	if stats == null:
		return
	if not stats.stats_changed.is_connected(update_player):
		stats.stats_changed.connect(update_player)
	# Run after node is ready so sprite_2d and stats_ui are set
	call_deferred("update_player")

func update_player() -> void:
	if stats == null:
		return
	if not (stats is CharacterStats):
		return
	if sprite_2d and stats.art:
		sprite_2d.texture = stats.art
	if stats_ui:
		stats_ui.update_stats(stats)

func take_damage(damage: int) -> void:
	if not stats:
		return
	if stats.health <= 0:
		return
	stats.take_damage(damage)
	if stats.health <= 0:
		queue_free()
