extends Node2D
@onready var _camera: Camera2D = $Camera2D
@export var fish_scene: PackedScene
@export var spawn_interval: float = 0.85
@export var spawn_x_min: float = 100.0
@export var spawn_x_max: float = 1820.0

@onready var lab_player: MiniGamePiece = $LabPlayer
@onready var fish_container: Node2D = $FishContainer

@onready var score_label: Label = $UI/ScoreLabel
@onready var life_label: Label = $UI/LifeLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var hint_label: Label = $UI/HintLabel

var score: int = 0
var lives: int = 3

var spawn_time: float = 0.0
var game_over: bool = false

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_camera.make_current()
	
	_rng.randomize()

	game_over_label.hide()

	update_ui()


func _process(delta: float) -> void:
	if game_over:
		return

	spawn_time += delta

	if spawn_time >= spawn_interval:
		spawn_time = 0.0
		spawn_fish()


func _unhandled_input(event: InputEvent) -> void:
	if not game_over:
		return

	# 대냥시대 interact = Space
	if event.is_action_pressed("interact"):
		restart_game()
		get_viewport().set_input_as_handled()


func spawn_fish() -> void:
	print("SPAWN FISH")
	if fish_scene == null:
		push_error("Fish Catch: fish_scene이 설정되어 있지 않습니다.")
		return
		
	var fish_instance := fish_scene.instantiate()
	
	if fish_instance == null:
		push_error("Fish Catch: instantiate 실패")
		return


	# var fish_Instance := fish_scene.instantiate() # Unused duplicate instance; kept for reference.

	if fish_instance is not LabFish:
		push_error("Fish Catch: fish_scene의 루트가 LabFish가 아닙니다.")
		fish_instance.queue_free()
		return
		
	var fish := fish_instance as LabFish
	
	fish.position = Vector2(
		_rng.randf_range(spawn_x_min, spawn_x_max),
		-40.0
	)

	fish.caught.connect(_on_fish_caught)
	fish.missed.connect(_on_fish_missed)

	fish_container.add_child(fish)
#func spawn_fish() -> void:
	#print("SPAWN FISH")
#
	#if fish_scene == null:
		#push_error("Fish Catch: fish_scene이 null입니다.")
		#return
#
	#var fish_instance := fish_scene.instantiate()
	#print("instantiated: ", fish_instance)
#
	#if fish_instance == null:
		#push_error("Fish Catch: instantiate 실패")
		#return
#
	#if fish_instance is not LabFish:
		#push_error("Fish Catch: fish_scene 루트가 LabFish가 아닙니다.")
		#print("actual type: ", fish_instance.get_class())
		#return
#
	#var fish := fish_instance as LabFish
#
	#fish.position = Vector2(960, 200)
	#fish.fall_speed = 180.0
#
	#fish.caught.connect(_on_fish_caught)
	#fish.missed.connect(_on_fish_missed)
#
	#fish_container.add_child(fish)
	#
	#print("fish visible = ", fish.visible)
	#print("fish global pos = ", fish.global_position)
	#print("container pos = ", fish_container.global_position)
	#print("container scale = ", fish_container.global_scale)
	#print("fish children = ", fish.get_children())
#
	#print("fish added: ", fish, " / pos=", fish.position)
	#print("child count: ", fish_container.get_child_count())
#
	#fish.name = "LabFish"
#
	#fish.position = Vector2(
		#_rng.randf_range(spawn_x_min, spawn_x_max),
		#-80.0
	#)
#
	## 점수가 높아질수록 조금씩 빨라짐
	#fish.fall_speed = (
		#180.0
		#+ _rng.randf_range(0.0, 90.0)
		#+ score * 3.0
	#)
#
	#fish.caught.connect(_on_fish_caught)
	#fish.missed.connect(_on_fish_missed)
#
	#fish_container.add_child(fish)


func _on_fish_caught(fish: FishPiece) -> void:
	if not is_instance_valid(fish):
		return

	score += 1

	fish.queue_free()

	update_ui()


func _on_fish_missed(fish: FishPiece) -> void:
	if not is_instance_valid(fish):
		return

	lives -= 1

	fish.queue_free()

	update_ui()

	if lives <= 0:
		end_game()


func end_game() -> void:
	game_over = true
	lab_player.set_enabled(false)

	for fish in fish_container.get_children():
		fish.queue_free()

	game_over_label.text = (
		"GAME OVER\n"
		+ "Score : %d\n\n" % score
		+ "SPACE 키로 다시 시작"
	)

	game_over_label.show()

	hint_label.text = ""


func restart_game() -> void:
	score = 0
	lives = 3
	spawn_time = 0.0
	game_over = false

	for fish in fish_container.get_children():
		fish.queue_free()

	lab_player.set_enabled(true)

	game_over_label.hide()

	hint_label.text = "A / D 또는 ← / → 로 이동"

	update_ui()


func update_ui() -> void:
	score_label.text = "SCORE : %d" % score
	life_label.text = "LIFE : %d" % lives
