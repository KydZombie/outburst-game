class_name Enemy
extends Area2D

const ARROW_OFFSET := 5

@export var stats: Stats: set = set_enemy_stats
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var arrow: Sprite2D = $Arrow
@onready var stats_ui: StatsUI = $StatsUI

func set_enemy_stats(value: Stats) -> void:
	if value == null:
		return
	stats = value.create_instance() as Stats
	if stats == null:
		return
	if not stats.stats_changed.is_connected(update_enemy):
		stats.stats_changed.connect(update_enemy)
	call_deferred("update_enemy")

func update_stats() -> void:
	if stats_ui:
		stats_ui.update_stats(stats)

func update_enemy() -> void:
	if stats == null:
		return
	if not (stats is Stats):
		return
	if is_inside_tree() and not is_node_ready():
		await ready
	if sprite_2d and stats.art:
		sprite_2d.texture = stats.art
	if arrow and sprite_2d:
		var rect_size_x: float = sprite_2d.get_rect().size.x / 2.0 + ARROW_OFFSET
		arrow.position = Vector2.RIGHT * rect_size_x
	update_stats()

func take_damage(damage: int) -> void:
	if not stats:
		return
	if stats.health <= 0:
		return
	stats.take_damage(damage)
	if stats.health <= 0:
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	arrow.show()

func _on_area_exited(_area: Area2D) -> void:
	arrow.hide()

## Update display from Core via BattleRunner (health, etc.). Called when hand syncs from state.
func update_from_battle_runner(battle_runner: Node) -> void:
	if not battle_runner or not battle_runner.has_method("GetEnemyHealth"):
		return
	if not stats_ui:
		return
	stats_ui.health_label.text = str(battle_runner.GetEnemyHealth())
	stats_ui.health.visible = true
	stats_ui.block_label.text = "0"
	stats_ui.block.visible = false
