extends Node2D

@export var rock_scene: PackedScene
@export var start_scroll_speed := 360.0
@export var maximum_scroll_speed := 820.0
@export var start_spawn_interval := 0.92
@export var minimum_spawn_interval := 0.36

var distance_m := 0.0
var scroll_speed := 0.0
var spawn_timer := 0.0
var spawn_interval := 0.0
var game_over := false
var _road_offset := 0.0

@onready var obstacle_container := $ObstacleContainer as Node2D
@onready var lab_player := $LabPlayer as RunnerPlayer
@onready var camera := $Camera2D as Camera2D
@onready var distance_label := %DistanceLabel as Label
@onready var dash_label := %DashLabel as Label
@onready var game_over_label := %GameOverLabel as Label


func _ready() -> void:
	# 전역 FieldCamera의 위치/확대값이 미니게임에 이어지지 않게 분리한다.
	camera.make_current()
	reset_game()


func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("restart_game"):
			reset_game()
		return

	distance_m += scroll_speed * delta / 100.0
	scroll_speed = minf(start_scroll_speed + distance_m * 2.0, maximum_scroll_speed)
	spawn_interval = maxf(start_spawn_interval - distance_m * 0.004, minimum_spawn_interval)
	_road_offset = fmod(_road_offset + scroll_speed * delta, 180.0)
	queue_redraw()

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_rock()
		spawn_timer = spawn_interval * randf_range(0.82, 1.14)

	_update_obstacle_scroll_speed()
	_check_collisions()
	_update_ui()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color("111522"), true)
	draw_rect(Rect2(120, 0, 1680, 1080), Color("34313b"), true)
	draw_rect(Rect2(145, 0, 1630, 1080), Color("252832"), true)
	for lane_x in [552.0, 960.0, 1368.0]:
		for index in range(-1, 7):
			var y := float(index) * 180.0 + _road_offset
			draw_rect(Rect2(lane_x - 6.0, y, 12.0, 92.0), Color(1, 1, 1, 0.42), true)
	draw_rect(Rect2(120, 0, 25, 1080), Color("e5b454"), true)
	draw_rect(Rect2(1775, 0, 25, 1080), Color("e5b454"), true)


func _spawn_rock() -> void:
	if rock_scene == null:
		push_error("RunnerMiniGame: rock_scene이 설정되지 않았습니다.")
		return
	var rock := rock_scene.instantiate() as RunnerObstaclePiece
	if rock == null:
		push_error("RunnerMiniGame: RockObstacle 인스턴스 생성 실패")
		return
	var scale_factor := randf_range(0.78, 1.22)
	rock.scale = Vector2.ONE * scale_factor
	var approximate_half_width := 58.0 * scale_factor
	rock.position = Vector2(
		randf_range(160.0 + approximate_half_width, 1760.0 - approximate_half_width),
		-90.0
	)
	rock.speed_multiplier = randf_range(0.9, 1.16)
	rock.scroll_speed = scroll_speed
	rock.exited_screen.connect(_on_rock_exited)
	obstacle_container.add_child(rock)


func _update_obstacle_scroll_speed() -> void:
	for child in obstacle_container.get_children():
		if child is RunnerObstaclePiece:
			child.scroll_speed = scroll_speed


func _check_collisions() -> void:
	var player_rect := lab_player.get_collision_rect()
	for child in obstacle_container.get_children():
		if child is RunnerObstaclePiece and player_rect.intersects(child.get_collision_rect()):
			_trigger_game_over()
			return


func _trigger_game_over() -> void:
	game_over = true
	lab_player.enabled = false
	for child in obstacle_container.get_children():
		child.set_process(false)
	game_over_label.text = "OUCH!\n%.1f m\nEnter로 재시작" % distance_m
	game_over_label.show()


func _update_ui() -> void:
	distance_label.text = "DISTANCE  %.1f m" % distance_m
	dash_label.text = "DASH  " + lab_player.get_dash_cooldown_text()


func reset_game() -> void:
	distance_m = 0.0
	scroll_speed = start_scroll_speed
	spawn_timer = 0.45
	spawn_interval = start_spawn_interval
	game_over = false
	_road_offset = 0.0
	for child in obstacle_container.get_children():
		child.queue_free()
	lab_player.position = Vector2(960.0, 1015.0)
	lab_player.reset_runner()
	game_over_label.hide()
	_update_ui()
	queue_redraw()


func _on_rock_exited(_rock: RunnerObstaclePiece) -> void:
	pass
