class_name RunnerPlayer
extends MiniGamePiece

@export var left_limit := 90.0
@export var right_limit := 1830.0
@export var dash_speed := 1500.0
@export var dash_duration := 0.14
@export var dash_cooldown := 0.45

var facing := 1.0
var dash_left := 0.0
var dash_cooldown_left := 0.0

@onready var gfx := $BbiyongLabGFX as GamepieceAnimation


func _ready() -> void:
	gfx.set_direction(Directions.Points.EAST)
	gfx.play("idle")


func _physics_process(delta: float) -> void:
	if not enabled:
		gfx.play("idle")
		return

	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)
	var direction := Input.get_axis("ui_left", "ui_right")
	if not is_zero_approx(direction):
		facing = signf(direction)

	if Input.is_action_just_pressed("dash"):
		_start_dash(direction)

	if dash_left > 0.0:
		dash_left = maxf(dash_left - delta, 0.0)
		position.x += facing * dash_speed * delta
		gfx.play("run")
		queue_redraw()
	else:
		position.x += direction * move_speed * delta
		gfx.play("run" if not is_zero_approx(direction) else "idle")

	position.x = clampf(position.x, left_limit, right_limit)
	gfx.set_direction(Directions.Points.WEST if facing < 0.0 else Directions.Points.EAST)


func _start_dash(direction: float) -> void:
	if dash_cooldown_left > 0.0 or dash_left > 0.0:
		return
	if not is_zero_approx(direction):
		facing = signf(direction)
	dash_left = dash_duration
	dash_cooldown_left = dash_cooldown
	queue_redraw()


func reset_runner() -> void:
	enabled = true
	facing = 1.0
	dash_left = 0.0
	dash_cooldown_left = 0.0
	gfx.set_direction(Directions.Points.EAST)
	gfx.play("idle")
	queue_redraw()


func get_dash_cooldown_text() -> String:
	return "READY" if dash_cooldown_left <= 0.0 else "%.1fs" % dash_cooldown_left


func get_collision_rect() -> Rect2:
	var shape_node := $CollisionShape2D as CollisionShape2D
	var rectangle := shape_node.shape as RectangleShape2D
	if rectangle == null:
		return Rect2(global_position, Vector2.ZERO)
	var size := rectangle.size * global_scale.abs()
	return Rect2(shape_node.global_position - size * 0.5, size)


func _draw() -> void:
	if dash_left <= 0.0:
		return
	for index in range(4):
		var y := -72.0 + float(index) * 14.0
		var start_x := -facing * (85.0 + float(index) * 12.0)
		var end_x := -facing * 20.0
		draw_line(Vector2(start_x, y), Vector2(end_x, y), Color(1, 1, 1, 0.82), 5.0, true)
