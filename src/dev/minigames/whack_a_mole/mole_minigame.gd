class_name MoleMiniGame
extends Node2D

@export var mole_scene: PackedScene
@export var spawn_interval: float = 0.9
@export var game_duration: float = 30.0

@export_category("이미지 슬롯")
@export var background_image: Texture2D
@export var hole_image: Texture2D
@export var hole_image_scale := Vector2.ONE

@onready var _camera: Camera2D = $Camera2D
@onready var _background_image: TextureRect = $Background/BackgroundImage
@onready var _background_fallback: ColorRect = $Background/BackgroundFallback
@onready var holes: Node2D = $HoleContainer
@onready var mole_container: Node2D = $MoleContainer
@onready var hammer: MoleHammer = $Hammer
@onready var score_label: Label = $UI/ScoreLabel
@onready var time_label: Label = $UI/TimeLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var hint_label: Label = $UI/HintLabel

var score: int = 0
var time_left: float = 30.0
var spawn_left: float = 0.0
var game_over := false
var occupied := {}


func _ready() -> void:
	# FieldCamera와 분리된 미니게임 전용 카메라를 사용한다.
	_camera.make_current()
	time_left = game_duration
	_configure_image_slots()

	for hole in holes.get_children():
		occupied[hole] = false

	game_over_label.hide()
	update_ui()


func _configure_image_slots() -> void:
	_background_image.texture = background_image
	_background_image.visible = background_image != null
	_background_fallback.visible = background_image == null

	for child in holes.get_children():
		var hole := child as Marker2D
		if hole == null:
			continue

		var image := hole.get_node_or_null("Image") as Sprite2D
		var fallback := hole.get_node_or_null("Fallback") as Polygon2D
		if image != null:
			image.texture = hole_image
			image.scale = hole_image_scale
			image.visible = hole_image != null
		if fallback != null:
			fallback.visible = hole_image == null


func _process(delta: float) -> void:
	if game_over:
		return

	time_left = maxf(0.0, time_left - delta)
	if time_left <= 0.0:
		end_game()
		return

	spawn_left -= delta
	if spawn_left <= 0.0:
		spawn_mole()
		spawn_left = maxf(0.3, spawn_interval - float(score) * 0.012)

	update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		if event.is_action_pressed("interact"):
			restart_game()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			hit_with_hammer()
			get_viewport().set_input_as_handled()


func hit_with_hammer() -> void:
	hammer.swing()
	var mouse := get_global_mouse_position()
	var moles := mole_container.get_children()
	moles.reverse()

	for mole in moles:
		if mole is not MolePiece:
			continue
		var mole_piece := mole as MolePiece

		var shape_node := mole_piece.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape_node == null or shape_node.shape is not RectangleShape2D:
			continue

		var local_mouse: Vector2 = mole_piece.to_local(mouse)
		var rectangle := shape_node.shape as RectangleShape2D
		var half: Vector2 = rectangle.size * 0.5
		if absf(local_mouse.x) <= half.x and absf(local_mouse.y) <= half.y:
			mole_piece.register_hit()
			break


func spawn_mole() -> void:
	if mole_scene == null:
		push_error("MINIGAME2: mole_scene이 설정되지 않았습니다.")
		return

	var free_holes: Array[Marker2D] = []
	for child in holes.get_children():
		var hole := child as Marker2D
		if hole != null and not occupied.get(hole, false):
			free_holes.append(hole)

	if free_holes.is_empty():
		return

	var hole: Marker2D = free_holes.pick_random()
	var mole := mole_scene.instantiate() as MolePiece
	if mole == null:
		push_error("MINIGAME2: LabMole 생성 실패")
		return

	occupied[hole] = true
	mole_container.add_child(mole)
	mole.setup(hole.global_position + Vector2(0, 80), 90.0)
	mole.hit.connect(_on_mole_hit)
	mole.disappeared.connect(_on_mole_disappeared.bind(hole))


func _on_mole_hit(_mole: MolePiece) -> void:
	score += 1
	update_ui()


func _on_mole_disappeared(_mole: MolePiece, hole: Marker2D) -> void:
	occupied[hole] = false


func end_game() -> void:
	game_over = true
	time_left = 0.0

	for mole in mole_container.get_children():
		mole.queue_free()

	for hole in occupied.keys():
		occupied[hole] = false

	game_over_label.text = (
		"TIME UP!\n"
		+ "Score : %d\n\n" % score
		+ "SPACE 키로 다시 시작"
	)
	game_over_label.show()
	hint_label.text = "\\ 키 → 콘솔 / MAIN → 돌아가기"
	update_ui()


func restart_game() -> void:
	score = 0
	time_left = game_duration
	spawn_left = 0.0
	game_over = false

	for mole in mole_container.get_children():
		mole.queue_free()

	for hole in occupied.keys():
		occupied[hole] = false

	game_over_label.hide()
	hint_label.text = "마우스 클릭으로 두더지를 때리세요!"
	update_ui()


func update_ui() -> void:
	score_label.text = "SCORE : %d" % score
	time_label.text = "TIME : %d" % int(ceilf(time_left))
