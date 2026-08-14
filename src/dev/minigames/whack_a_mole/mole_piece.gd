class_name MolePiece
extends Area2D

signal hit(mole: MolePiece)
signal disappeared(mole: MolePiece)

@export var rise_speed: float = 320.0
@export var fall_speed: float = 360.0
@export var visible_time: float = 1.0

var state: StringName = &"idle"
var life: float = 0.0
var start_y: float = 0.0
var up_y: float = 0.0


func setup(start_position: Vector2, rise_distance: float = 90.0) -> void:
	global_position = start_position
	start_y = global_position.y
	up_y = start_y - rise_distance
	state = &"rising"
	life = 0.0


func _process(delta: float) -> void:
	life += delta

	match state:
		&"rising":
			global_position.y -= rise_speed * delta
			if global_position.y <= up_y:
				global_position.y = up_y
				state = &"up"
				life = 0.0
		&"up":
			if life >= visible_time:
				state = &"falling"
				life = 0.0
		&"hit":
			if life >= 0.12:
				state = &"falling"
				life = 0.0
		&"falling":
			global_position.y += fall_speed * delta
			if global_position.y >= start_y + 10.0:
				disappeared.emit(self)
				queue_free()


func register_hit() -> void:
	if state != &"rising" and state != &"up":
		return

	state = &"hit"
	life = 0.0
	hit.emit(self)
