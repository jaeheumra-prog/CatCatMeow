extends GamepieceAnimation

@onready var _sprite: AnimatedSprite2D = $Anchor/Sprite


func play(value: String) -> void:
	if value == current_sequence_id:
		return
	current_sequence_id = value

	if not is_inside_tree():
		await ready
	_sync_animation(false)


func set_direction(value: Directions.Points) -> void:
	if value == direction:
		return
	direction = value

	if not is_inside_tree():
		await ready
	_sync_animation(true)


func _sync_animation(keep_frame: bool) -> void:
	var suffix: String = DIRECTION_SUFFIXES.get(direction, "_s")
	var animation_name := StringName(current_sequence_id + suffix)
	if not _sprite.sprite_frames.has_animation(animation_name):
		return

	var old_frame := _sprite.frame
	var old_progress := _sprite.frame_progress
	_sprite.play(animation_name)
	if keep_frame:
		_sprite.set_frame_and_progress(
			mini(old_frame, _sprite.sprite_frames.get_frame_count(animation_name) - 1),
			old_progress
		)
