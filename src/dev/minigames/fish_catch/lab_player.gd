extends MiniGamePiece

# =========================
# 기본 이동
# =========================

@export var left_limit: float = 160.0
@export var right_limit: float = 1760.0


# =========================
# 대시
# =========================

# 대시 속도
@export var dash_speed: float = 1500.0

# 대시 지속 시간
@export var dash_duration: float = 0.15

# 다음 대시까지 기다리는 시간
@export var dash_cooldown: float = 0.45


@onready var _gfx: GamepieceAnimation = $BbiyongLabGFX


var _is_dashing: bool = false

var _dash_direction: float = 1.0
var _last_direction: float = 1.0

var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0


func _ready() -> void:
	_gfx.set_direction(Directions.Points.SOUTH)
	_gfx.play("idle")


func _physics_process(delta: float) -> void:
	if not enabled:
		_gfx.play("idle")
		return


	# =========================
	# 대시 쿨다운
	# =========================

	if _dash_cooldown_left > 0.0:
		_dash_cooldown_left -= delta


	# =========================
	# 현재 대시 중
	# =========================

	if _is_dashing:
		_update_dash(delta)
		return


	# =========================
	# 일반 좌우 입력
	# =========================

	var direction := Input.get_axis(
		"ui_left",
		"ui_right"
	)


	# 마지막으로 움직인 방향 저장
	if not is_zero_approx(direction):
		_last_direction = sign(direction)


	# =========================
	# Shift 대시
	# =========================

	if Input.is_action_just_pressed("dash") \
			and _dash_cooldown_left <= 0.0:

		_start_dash(direction)
		return


	# =========================
	# 일반 이동
	# =========================

	if is_zero_approx(direction):
		_gfx.play("idle")
		return


	position.x += direction * move_speed * delta

	position.x = clamp(
		position.x,
		left_limit,
		right_limit
	)


	_update_facing(direction)

	_gfx.play("run")


# =========================
# 대시 시작
# =========================

func _start_dash(input_direction: float) -> void:

	_is_dashing = true

	_dash_time_left = dash_duration
	_dash_cooldown_left = dash_cooldown


	# 방향키를 누른 상태에서 Shift
	if not is_zero_approx(input_direction):

		_dash_direction = sign(input_direction)

		_last_direction = _dash_direction


	# 방향키 없이 Shift
	else:

		_dash_direction = _last_direction


	_update_facing(_dash_direction)

	_gfx.play("run")


# =========================
# 대시 이동
# =========================

func _update_dash(delta: float) -> void:

	position.x += (
		_dash_direction
		* dash_speed
		* delta
	)


	# 화면 밖으로 못 나가게 제한
	position.x = clamp(
		position.x,
		left_limit,
		right_limit
	)


	_dash_time_left -= delta


	if _dash_time_left <= 0.0:
		_is_dashing = false


# =========================
# 바라보는 방향
# =========================

func _update_facing(direction: float) -> void:

	if direction < 0.0:

		_gfx.set_direction(
			Directions.Points.WEST
		)

	else:

		_gfx.set_direction(
			Directions.Points.EAST
		)
