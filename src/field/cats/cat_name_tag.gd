class_name CatNameTag
extends Node2D

## Keeps a world-space name tag at a stable screen-space size and offset.
var target: Node2D
var camera: Camera2D
var screen_offset := Vector2(0.0, -42.0)


func setup(follow_target: Node2D, active_camera: Camera2D) -> void:
	target = follow_target
	camera = active_camera
	top_level = true
	process_priority = 100
	_update_transform()


func _process(_delta: float) -> void:
	_update_transform()


func _update_transform() -> void:
	if not is_instance_valid(target):
		return

	var camera_zoom := Vector2.ONE
	if is_instance_valid(camera):
		camera_zoom = camera.zoom

	camera_zoom.x = maxf(absf(camera_zoom.x), 0.001)
	camera_zoom.y = maxf(absf(camera_zoom.y), 0.001)

	global_position = target.global_position + Vector2(
		screen_offset.x / camera_zoom.x,
		screen_offset.y / camera_zoom.y
	)
	global_rotation = 0.0
	global_scale = Vector2(
		1.0 / camera_zoom.x,
		1.0 / camera_zoom.y
	)
