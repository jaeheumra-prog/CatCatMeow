class_name MoleHammer
extends Sprite2D

@export var show_duration: float = 0.12

var show_left: float = 0.0


func _ready() -> void:
	visible = false


func _process(delta: float) -> void:
	global_position = get_global_mouse_position()

	if show_left > 0.0:
		show_left -= delta
		visible = true
	else:
		visible = false


func swing() -> void:
	show_left = show_duration
	visible = true
