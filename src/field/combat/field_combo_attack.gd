class_name FieldComboAttack
extends Node2D

## Three-step real-time field combo adapted from GDQuest's Godot 3 sword combo.
signal attack_started(combo_step: int)
signal attack_queued(next_combo_step: int)
signal hit_window_opened(combo_step: int, damage: int)
signal attack_hit(combo_step: int, hit_box: FieldHitBox, applied_damage: int)
signal combo_finished(last_combo_step: int)

const ATTACKS := [
	{
		"damage": 1,
		"duration": 0.34,
		"hit_start": 0.07,
		"hit_end": 0.18,
		"queue_start": 0.10,
	},
	{
		"damage": 1,
		"duration": 0.34,
		"hit_start": 0.07,
		"hit_end": 0.18,
		"queue_start": 0.10,
	},
	{
		"damage": 3,
		"duration": 0.48,
		"hit_start": 0.10,
		"hit_end": 0.28,
		"queue_start": 0.14,
	},
]

@export var input_action: StringName = &"attack"
@export var attack_enabled := true

var _gamepiece: Gamepiece
var _player_controller: PlayerController
var _combo_step := -1
var _elapsed := 0.0
var _next_attack_queued := false
var _hit_window_active := false
var _restore_player_control := false

@onready var damage_source := $FieldDamageSource as FieldDamageSource


func _ready() -> void:
	_gamepiece = get_parent() as Gamepiece
	if _gamepiece == null:
		push_error("FieldComboAttack must be a direct child of a Gamepiece.")
		set_process_unhandled_input(false)
		return

	_player_controller = _gamepiece.get_node_or_null("PlayerController") as PlayerController
	damage_source.source_actor = _gamepiece
	damage_source.hit_confirmed.connect(_on_hit_confirmed)
	damage_source.set_active(false)
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if attack_enabled and event.is_action_pressed(input_action) and not event.is_echo():
		request_attack()
		get_viewport().set_input_as_handled()


func request_attack() -> bool:
	if not attack_enabled or _gamepiece == null:
		return false

	if _combo_step < 0:
		if _gamepiece.is_moving():
			return false
		_start_attack(0)
		return true

	if _combo_step >= ATTACKS.size() - 1:
		return false

	var attack: Dictionary = ATTACKS[_combo_step]
	if _elapsed < float(attack.queue_start) or _next_attack_queued:
		return false

	_next_attack_queued = true
	attack_queued.emit(_combo_step + 1)
	return true


func cancel_combo() -> void:
	if _combo_step < 0:
		return
	_finish_combo()


func get_combo_step() -> int:
	return _combo_step


func is_attacking() -> bool:
	return _combo_step >= 0


func _process(delta: float) -> void:
	if _combo_step < 0:
		return

	_elapsed += delta
	var attack: Dictionary = ATTACKS[_combo_step]
	var hit_start := float(attack.hit_start)
	var hit_end := float(attack.hit_end)

	if not _hit_window_active and _elapsed >= hit_start and _elapsed < hit_end:
		_open_hit_window()
	elif _hit_window_active and _elapsed >= hit_end:
		_close_hit_window()

	queue_redraw()
	if _elapsed < float(attack.duration):
		return

	if _next_attack_queued and _combo_step < ATTACKS.size() - 1:
		_start_attack(_combo_step + 1)
	else:
		_finish_combo()


func _start_attack(step: int) -> void:
	_close_hit_window()
	_combo_step = clampi(step, 0, ATTACKS.size() - 1)
	_elapsed = 0.0
	_next_attack_queued = false
	_hit_window_active = false

	var facing := Vector2(Directions.MAPPINGS.get(_gamepiece.direction, Vector2i.DOWN))
	rotation = facing.angle()

	if _player_controller != null and _combo_step == 0:
		_restore_player_control = _player_controller.is_active
		_player_controller.is_active = false

	set_process(true)
	queue_redraw()
	attack_started.emit(_combo_step)


func _open_hit_window() -> void:
	var attack: Dictionary = ATTACKS[_combo_step]
	_hit_window_active = true
	damage_source.damage = int(attack.damage)
	damage_source.set_active(true)
	hit_window_opened.emit(_combo_step, damage_source.damage)


func _close_hit_window() -> void:
	if damage_source != null:
		damage_source.set_active(false)
	_hit_window_active = false


func _finish_combo() -> void:
	var last_step := _combo_step
	_close_hit_window()
	_combo_step = -1
	_elapsed = 0.0
	_next_attack_queued = false
	set_process(false)
	queue_redraw()

	if _player_controller != null and _restore_player_control:
		_player_controller.is_active = true
	_restore_player_control = false
	combo_finished.emit(last_step)


func _on_hit_confirmed(hit_box: FieldHitBox, applied_damage: int) -> void:
	attack_hit.emit(_combo_step, hit_box, applied_damage)


func _draw() -> void:
	if _combo_step < 0:
		return

	var attack: Dictionary = ATTACKS[_combo_step]
	var progress := clampf(_elapsed / float(attack.duration), 0.0, 1.0)
	var colors := [Color("8be9fd"), Color("bd93f9"), Color("ffb86c")]
	var color: Color = colors[_combo_step]
	color.a = 1.0 - progress * 0.55

	var start_angle := -0.85
	var end_angle := lerpf(start_angle, 0.85, minf(progress * 2.2, 1.0))
	if _combo_step == 1:
		start_angle = 0.85
		end_angle = lerpf(start_angle, -0.85, minf(progress * 2.2, 1.0))

	draw_arc(Vector2.ZERO, 18.0 + _combo_step * 2.0, start_angle, end_angle, 18, color, 3.0)
