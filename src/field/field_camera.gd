## Specialized camera that is constrained to the [Gameboard]'s boundaries.
##
## The camera's limits are set dynamically according to the viewport's dimensions. Normally, the
## camera is limited to the [member Gameboard.boundaries].
## [br][br]In some cases the gameboard is smaller than the viewport, in which case it will be
## snapped to the gameboard centre along the constrained axis/axes.
class_name FieldCamera
extends Camera2D

const CAMERA_SHAKE_SCRIPT := preload("res://src/common/camera_shake_2d.gd")

var _camera_shake

@export var gameboard_properties: GameboardProperties:
	set(value):
		_on_viewport_resized()


@export var gamepiece: Gamepiece:
	set(value):
		if gamepiece:
			gamepiece.animation_transform.remote_path = ""
		
		gamepiece = value
		if gamepiece:
			gamepiece.animation_transform.remote_path \
				= gamepiece.animation_transform.get_path_to(self)


func _ready() -> void:
	# The field camera owns the reusable effect so callers can simply use Camera.shake().
	_camera_shake = CAMERA_SHAKE_SCRIPT.new()
	_camera_shake.name = "CameraShake"
	add_child(_camera_shake)

	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


## Shakes the active field camera without changing its tracking position or map limits.
func shake(amplitude := 8.0, duration := 0.2) -> void:
	if _camera_shake:
		_camera_shake.start_shake(amplitude, duration)


func reset_position() -> void:
	if gamepiece:
		position = gamepiece.position * scale
		
	reset_smoothing()


func _on_viewport_resized() -> void:
	if not gameboard_properties:
		return
	
	# Calculate tentative camera boundaries based on the gameboard.
	var boundary_left: = gameboard_properties.extents.position.x * gameboard_properties.cell_size.x
	var boundary_top: = gameboard_properties.extents.position.y * gameboard_properties.cell_size.y
	var boundary_right: = gameboard_properties.extents.end.x * gameboard_properties.cell_size.x
	var boundary_bottom: = gameboard_properties.extents.end.y * gameboard_properties.cell_size.y

	# We'll also want the current viewport boundary sizes.
	var vp_size: = get_viewport_rect().size / global_scale
	var boundary_width: = boundary_right - boundary_left
	var boundary_height: = boundary_bottom - boundary_top

	# If the boundary size is less than the viewport size, the camera limits will be smaller than
	# the camera dimensions (which does all kinds of crazy things in-game).
	# Therefore, if this is the case we'll want to centre the camera on the gameboard and set the
	# limits to be that of the viewport, locking the camera to one or both axes.
	# Start by checking the x-axis.
	# Note that the camera limits must be in global coordinates to function correctly, so account
	# using the global scale.
	if boundary_width < vp_size.x:
		# Set the camera position to the centre of the gameboard.
		position.x = (gameboard_properties.extents.position.x \
			+ gameboard_properties.extents.size.x/2.0) * gameboard_properties.cell_size.x

		# And add/subtract half the viewport dimension to come up with the limits. This will fix the
		# camera with the gameboard centred.
		limit_left = (position.x - vp_size.x/2.0)*global_scale.x as int
		limit_right = (position.x + vp_size.x/2.0)*global_scale.x as int

	# If, however, the viewport is smaller than the gameplay area, the camera can be free to move
	# as needed.
	else:
		limit_left = boundary_left*global_scale.x as int
		limit_right = boundary_right*global_scale.x as int

	# Perform the same checks as above for the y-axis.
	if boundary_height < vp_size.y:
		position.y = (gameboard_properties.extents.position.y +\
			gameboard_properties.extents.size.y/2.0) * gameboard_properties.cell_size.y
		limit_top = (position.y - vp_size.y/2.0)*global_scale.y as int
		limit_bottom = (position.y + vp_size.y/2.0)*global_scale.y as int
	else:
		limit_top = boundary_top*global_scale.y as int
		limit_bottom = boundary_bottom*global_scale.y as int
