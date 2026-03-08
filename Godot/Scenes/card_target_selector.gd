extends Node2D

const ARC_POINTS := 8

@onready var area_2d: Area2D = $Area2D
@onready var card_arc: Line2D = $CanvasLayer/CardArc

var current_card: CardUI
var targeting: bool = false

func _ready() -> void:
	var events = get_node_or_null("/root/Events")
	if not events:
		push_warning("CardTargetSelector: Events autoload not found; card aiming will not work.")
		return
	events.card_aim_started.connect(_on_card_aim_started)
	events.card_aim_ended.connect(_on_card_aim_ended)
	# area_entered / area_exited are already connected in card_target_selector.tscn — do not connect again here

func _process(_delta: float) -> void:
	if not targeting:
		card_arc.points = []
		return
	if current_card == null:
		targeting = false
		return
	# Use global position so the selector overlaps targets in world space.
	area_2d.global_position = get_global_mouse_position()
	card_arc.points = _get_arc_points()

func _on_card_aim_started(card_ui: CardUI) -> void:
	current_card = card_ui
	targeting = true
	area_2d.monitoring = true
	area_2d.monitorable = true

func _on_card_aim_ended(_card_ui: CardUI) -> void:
	targeting = false
	current_card = null
	card_arc.points = []
	area_2d.position = Vector2.ZERO
	area_2d.monitoring = false
	area_2d.monitorable = false

func _get_arc_points() -> PackedVector2Array:
	var points: PackedVector2Array = []
	var start: Vector2 = card_arc.to_local(current_card.global_position)
	start.x += current_card.size.x / 2.0
	var target: Vector2 = card_arc.to_local(get_global_mouse_position())
	var distance: Vector2 = target - start
	for i in range(ARC_POINTS):
		var t: float = (1.0 / ARC_POINTS) * i
		var x: float = start.x + (distance.x / ARC_POINTS) * i
		var y: float = start.y + ease_out_cubic(t) * distance.y
		points.append(Vector2(x, y))
	points.append(target)
	return points

func ease_out_cubic(number: float) -> float:
	return 1.0 - pow(1.0 - number, 3.0)

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not current_card or not targeting:
		return
	if not current_card.targets.has(area):
		current_card.targets.append(area)

func _on_area_2d_area_exited(area: Area2D) -> void:
	if not current_card or not targeting:
		return
	current_card.targets.erase(area)