class_name LabFish
extends FishPiece

signal caught(fish: FishPiece)
signal missed(fish: FishPiece)

@export var bottom_limit: float = 1120.0


# =========================
# 깃털 낙하 설정
# =========================

# 아래로 떨어지는 속도
@export var fall_speed_min: float = 80.0
@export var fall_speed_max: float = 140.0

# 좌우 흔들림 거리
@export var sway_amplitude_min: float = 18.0
@export var sway_amplitude_max: float = 55.0

# 좌우 흔들림 속도
@export var sway_frequency_min: float = 0.8
@export var sway_frequency_max: float = 1.8

# 한쪽 방향으로 천천히 밀리는 정도
@export var drift_speed_min: float = -25.0
@export var drift_speed_max: float = 25.0

# 회전 흔들림 각도
@export var rotation_amplitude_min: float = 8.0
@export var rotation_amplitude_max: float = 20.0

# 회전 흔들림 속도
@export var rotation_frequency_min: float = 1.0
@export var rotation_frequency_max: float = 2.2


# =========================
# 내부 상태
# =========================

var _resolved := false

var _time := 0.0
var _start_x := 0.0

var _fall_speed := 100.0
var _sway_amplitude := 30.0
var _sway_frequency := 1.2
var _drift_speed := 0.0

var _rotation_amplitude := 12.0
var _rotation_frequency := 1.5

var _phase := 0.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()

	# 생성된 위치를 기준점으로 저장
	_start_x = position.x

	# 깃털마다 조금씩 다른 움직임
	_fall_speed = _rng.randf_range(
		fall_speed_min,
		fall_speed_max
	)

	_sway_amplitude = _rng.randf_range(
		sway_amplitude_min,
		sway_amplitude_max
	)

	_sway_frequency = _rng.randf_range(
		sway_frequency_min,
		sway_frequency_max
	)

	_drift_speed = _rng.randf_range(
		drift_speed_min,
		drift_speed_max
	)

	_rotation_amplitude = _rng.randf_range(
		rotation_amplitude_min,
		rotation_amplitude_max
	)

	_rotation_frequency = _rng.randf_range(
		rotation_frequency_min,
		rotation_frequency_max
	)

	# 모든 깃털이 동시에 똑같이 흔들리지 않도록
	_phase = _rng.randf_range(0.0, TAU)

	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if _resolved:
		return

	_time += delta


	# =========================
	# 1. 아래로 천천히 낙하
	# =========================

	position.y += _fall_speed * delta


	# =========================
	# 2. 좌우 살랑살랑
	# =========================

	var sway := sin(
		_time * TAU * _sway_frequency + _phase
	) * _sway_amplitude


	# =========================
	# 3. 바람에 조금씩 한쪽으로 밀림
	# =========================

	var drift := _drift_speed * _time


	position.x = _start_x + sway + drift


	# =========================
	# 4. 깃털 회전
	# =========================

	rotation_degrees = sin(
		_time * TAU * _rotation_frequency + _phase
	) * _rotation_amplitude


	# =========================
	# 화면 아래로 떨어짐
	# =========================

	if position.y > bottom_limit:
		_resolve()
		missed.emit(self)


func _on_area_entered(area: Area2D) -> void:
	if _resolved:
		return

	if area.name != "LabPlayer":
		return

	_resolve()
	caught.emit(self)


func _resolve() -> void:
	_resolved = true
	enabled = false

	set_process(false)

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
