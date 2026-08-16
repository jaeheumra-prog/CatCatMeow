class_name FieldComboAttack
extends Node2D

## Three-step real-time field combo adapted from GDQuest's Godot 3 sword combo.
const GROUP: StringName = &"_FIELD_COMBO_ATTACK_GROUP"

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
## 켜면 원본처럼 공격 중 이동을 잠급니다. 기본값은 이동 공격 허용입니다.
@export var lock_movement_during_attack := false

@export_group("Sword Visual")
## Inspector에서 원하는 검 PNG를 지정합니다. 비워 두면 임시 공격 궤적을 표시합니다.
@export var sword_texture: Texture2D
## 손잡이를 기준으로 검 이미지가 놓일 위치입니다.
@export var sword_texture_offset := Vector2(18.0, 0.0)
@export var sword_texture_scale := Vector2(0.04, 0.04)
## 원본 이미지가 오른쪽을 향하지 않을 때 방향을 보정합니다.
@export_range(-180.0, 180.0, 1.0) var sword_texture_rotation_degrees := 0.0

@export_group("Attack Trail")
## 검 이미지가 있어도 휘두른 궤적을 함께 표시합니다.
@export var show_attack_trail := true

var _gamepiece: Gamepiece
var _player_controller: PlayerController
var _combo_step := -1
var _elapsed := 0.0
var _next_attack_queued := false
var _hit_window_active := false
var _restore_player_control := false

@onready var damage_source := $FieldDamageSource as FieldDamageSource
@onready var sword_pivot := $SwordPivot as Node2D
@onready var sword_sprite := $SwordPivot/SwordSprite as Sprite2D


func _ready() -> void:
	add_to_group(GROUP)
	_gamepiece = get_parent() as Gamepiece
	if _gamepiece == null:
		push_error("FieldComboAttack must be a direct child of a Gamepiece.")
		set_process_unhandled_input(false)
		return

	_player_controller = _gamepiece.get_node_or_null("PlayerController") as PlayerController
	damage_source.source_actor = _gamepiece
	damage_source.hit_confirmed.connect(_on_hit_confirmed)
	damage_source.set_active(false)
	# SwordSprite에 직접 이미지를 넣은 경우에도 루트 export 값으로 받아들입니다.
	if sword_texture == null and sword_sprite.texture != null:
		sword_texture = sword_sprite.texture
	_apply_sword_texture()
	_reset_sword_visual()
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if attack_enabled and event.is_action_pressed(input_action) and not event.is_echo():
		if request_attack():
			get_viewport().set_input_as_handled()


func request_attack() -> bool:
	if not attack_enabled or _gamepiece == null:
		return false

	if _combo_step < 0:
		if lock_movement_during_attack and _gamepiece.is_moving():
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

	_sync_to_gamepiece_visual()
	_elapsed += delta
	var attack: Dictionary = ATTACKS[_combo_step]
	var hit_start := float(attack.hit_start)
	var hit_end := float(attack.hit_end)

	if not _hit_window_active and _elapsed >= hit_start and _elapsed < hit_end:
		_open_hit_window()
	elif _hit_window_active and _elapsed >= hit_end:
		_close_hit_window()

	queue_redraw()
	_update_sword_motion()
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

	_sync_to_gamepiece_visual()

	if lock_movement_during_attack and _player_controller != null and _combo_step == 0:
		_restore_player_control = _player_controller.is_active
		_player_controller.is_active = false

	set_process(true)
	_update_sword_motion()
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
	_reset_sword_visual()
	queue_redraw()

	if _player_controller != null and _restore_player_control:
		_player_controller.is_active = true
	_restore_player_control = false
	combo_finished.emit(last_step)


func _on_hit_confirmed(hit_box: FieldHitBox, applied_damage: int) -> void:
	attack_hit.emit(_combo_step, hit_box, applied_damage)


func _sync_to_gamepiece_visual() -> void:
	# Gamepiece의 루트는 셀 도착 전까지 움직이지 않으므로 실제 PathFollow2D를 따라갑니다.
	if _gamepiece == null:
		return
	if _gamepiece.follower != null:
		position = _gamepiece.follower.position
	var facing := Vector2(Directions.MAPPINGS.get(_gamepiece.direction, Vector2i.DOWN))
	rotation = facing.angle()


## 런타임에서도 검 이미지를 교체할 수 있습니다.
func set_sword_texture(texture: Texture2D) -> void:
	sword_texture = texture
	if is_node_ready():
		_apply_sword_texture()


func _apply_sword_texture() -> void:
	sword_sprite.texture = sword_texture
	sword_sprite.position = sword_texture_offset
	sword_sprite.scale = sword_texture_scale
	sword_sprite.rotation_degrees = sword_texture_rotation_degrees


func _reset_sword_visual() -> void:
	sword_pivot.visible = false
	sword_pivot.rotation = 0.0
	sword_pivot.scale = Vector2.ONE


func _update_sword_motion() -> void:
	if _combo_step < 0:
		_reset_sword_visual()
		return

	sword_pivot.visible = sword_texture != null
	var swing_degrees := 0.0
	var stretch := 1.0

	# 원본 Sword.tscn의 attack_fast / attack_medium 키프레임을 코드로 옮긴 값입니다.
	if _combo_step < 2:
		if _elapsed <= 0.15:
			swing_degrees = lerpf(-80.0, 85.0, clampf(_elapsed / 0.15, 0.0, 1.0))
		elif _elapsed <= 0.20:
			swing_degrees = lerpf(85.0, 75.0, (_elapsed - 0.15) / 0.05)
		else:
			swing_degrees = 75.0
		stretch = _sword_stretch(_elapsed, 0.05, 0.15)
	else:
		if _elapsed <= 0.05:
			swing_degrees = 95.0
		elif _elapsed <= 0.25:
			swing_degrees = lerpf(95.0, -95.0, (_elapsed - 0.05) / 0.20)
		elif _elapsed <= 0.35:
			swing_degrees = lerpf(-95.0, -90.0, (_elapsed - 0.25) / 0.10)
		else:
			swing_degrees = -90.0
		stretch = _sword_stretch(_elapsed, 0.10, 0.20)

	sword_pivot.rotation_degrees = swing_degrees
	sword_pivot.scale = Vector2(1.0, stretch)


func _sword_stretch(time: float, peak_time: float, end_time: float) -> float:
	if time <= peak_time:
		return lerpf(1.0, 1.3, clampf(time / peak_time, 0.0, 1.0))
	if time <= end_time:
		return lerpf(1.3, 1.0, (time - peak_time) / (end_time - peak_time))
	return 1.0


func _draw() -> void:
	if _combo_step < 0 or not show_attack_trail:
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
