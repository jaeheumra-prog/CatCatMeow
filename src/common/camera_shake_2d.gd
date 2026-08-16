## Adds a damped shake effect to a parent [Camera2D].
##
## Keep this as a separate component so field, test, and minigame cameras can share the effect
## without inheriting from a project-specific camera class.
extends Node

@export_range(0.0, 100.0, 0.1) var default_amplitude := 8.0
@export_range(0.01, 5.0, 0.01) var default_duration := 0.2
@export_range(0.1, 8.0, 0.1) var damping_easing := 1.0

var _camera: Camera2D
var _rng := RandomNumberGenerator.new()
var _base_offset := Vector2.ZERO
var _active_amplitude := 0.0
var _active_duration := 0.0
var _time_left := 0.0
var _is_shaking := false


func _ready() -> void:
	_camera = get_parent() as Camera2D
	if _camera == null:
		push_error("CameraShake2D must be a child of Camera2D.")
		set_process(false)
		return

	_rng.randomize()
	set_process(false)


## Starts a new shake or restarts the active shake with the supplied strength and duration.
## Negative arguments use the exported defaults, making the method convenient from scene code.
func start_shake(amplitude := -1.0, duration := -1.0) -> void:
	if _camera == null:
		return

	var requested_amplitude := default_amplitude if amplitude < 0.0 else amplitude
	var requested_duration := default_duration if duration < 0.0 else duration
	if requested_amplitude <= 0.0 or requested_duration <= 0.0:
		stop_shake()
		return

	# Capture the non-shake offset only once, so restarting cannot accumulate a random displacement.
	if not _is_shaking:
		_base_offset = _camera.offset

	_active_amplitude = requested_amplitude
	_active_duration = requested_duration
	_time_left = requested_duration
	_is_shaking = true
	set_process(true)


func stop_shake() -> void:
	if _camera and _is_shaking:
		_camera.offset = _base_offset
	_time_left = 0.0
	_is_shaking = false
	set_process(false)


func _process(delta: float) -> void:
	_time_left = maxf(_time_left - delta, 0.0)
	var remaining_ratio := _time_left / _active_duration
	var strength := ease(remaining_ratio, damping_easing)

	_camera.offset = _base_offset + Vector2(
		_rng.randf_range(-_active_amplitude, _active_amplitude),
		_rng.randf_range(-_active_amplitude, _active_amplitude)
	) * strength

	if is_zero_approx(_time_left):
		stop_shake()


func _exit_tree() -> void:
	# Never leave a reused camera with the last random shake offset applied.
	if _camera and _is_shaking:
		_camera.offset = _base_offset
