class_name LabFish
extends FishPiece

signal caught(fish: FishPiece)
signal missed(fish: FishPiece)

@export var bottom_limit: float = 1120.0

var _resolved := false
var _debug_time := 0.0


func _ready() -> void:
	print("LAB FISH READY")
	print("process enabled = ", is_processing())
	print("position = ", position)
	print("global position = ", global_position)

	area_entered.connect(_on_area_entered)

	queue_redraw()


func _draw() -> void:
	# 무조건 보여야 하는 초대형 빨간 상자
	draw_rect(
		Rect2(-50, -30, 100, 60),
		Color.RED,
		true
	)


func _process(delta: float) -> void:
	if _resolved:
		return

	position.y += fall_speed * delta

	_debug_time += delta
	if _debug_time >= 1.0:
		_debug_time = 0.0
		print(
			"FISH MOVING | y=",
			position.y,
			" | global=",
			global_position,
			" | visible=",
			is_visible_in_tree()
		)

	if position.y > bottom_limit:
		_resolve()
		missed.emit(self)


func _on_area_entered(area: Area2D) -> void:
	if _resolved:
		return

	if area.name != "LabPlayer":
		return

	_resolve()
	caught.emit(self)


func _resolve() -> void:
	_resolved = true
	enabled = false
	set_process(false)

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
