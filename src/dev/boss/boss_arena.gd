extends Node2D

const CELL_SIZE := 16
const GRID_SIZE := Vector2i(30, 17)
const PLAYER_SCENE := preload("res://src/field/gamepieces/gamepiece.tscn")
const PLAYER_CONTROLLER_SCENE := preload("res://src/field/gamepieces/controllers/player_controller.tscn")
const PLAYER_ANIMATION_SCENE := preload("res://assets/characters/bbiyong/bbiyong_lab_gfx.tscn")
const PLAYER_HEALTH_SCENE := preload("res://src/field/combat/field_health.tscn")
const PLAYER_HITBOX_SCENE := preload("res://src/field/combat/field_hit_box.tscn")
const COMBO_SCENE := preload("res://src/field/combat/field_combo_attack.tscn")
const BOSS_SCENE := preload("res://src/dev/boss/bad_cat_boss.tscn")
const CAMERA_SHAKE_SCRIPT := preload("res://src/common/camera_shake_2d.gd")

var player: Gamepiece
var boss: BadCatBoss
var player_hit_box: FieldHitBox
var _camera_shake

@onready var camera := $Camera2D as Camera2D
@onready var player_bar := %PlayerHealthBar as FieldHealthBar
@onready var boss_bar := %BossHealthBar as FieldHealthBar
@onready var boss_panel := %BossPanel as Control
@onready var result_label := %ResultLabel as Label


func _ready() -> void:
	_setup_gameboard()
	_spawn_player()
	_spawn_boss()
	_camera_shake = CAMERA_SHAKE_SCRIPT.new()
	camera.add_child(_camera_shake)
	camera.make_current()
	queue_redraw()
	_start_battle.call_deferred()


func _process(_delta: float) -> void:
	if player and player_hit_box and player.follower:
		player_hit_box.position = player.follower.position


func _draw() -> void:
	draw_rect(Rect2(0, 0, GRID_SIZE.x * CELL_SIZE, GRID_SIZE.y * CELL_SIZE), Color("17121d"), true)
	draw_rect(Rect2(16, 16, (GRID_SIZE.x - 2) * CELL_SIZE, (GRID_SIZE.y - 2) * CELL_SIZE), Color("463126"), true)
	for x in range(1, GRID_SIZE.x - 1):
		for y in range(1, GRID_SIZE.y - 1):
			var shade := Color("563b2a") if (x + y) % 2 == 0 else Color("503727")
			draw_rect(Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE), shade, true)
	draw_rect(Rect2(16, 16, (GRID_SIZE.x - 2) * CELL_SIZE, (GRID_SIZE.y - 2) * CELL_SIZE), Color("c47a3f"), false, 3.0)


func _setup_gameboard() -> void:
	var properties := GameboardProperties.new()
	properties.extents = Rect2i(Vector2i.ZERO, GRID_SIZE)
	properties.cell_size = Vector2i.ONE * CELL_SIZE
	Gameboard.properties = properties
	Gameboard.pathfinder.clear()
	for y in range(1, GRID_SIZE.y - 1):
		for x in range(1, GRID_SIZE.x - 1):
			var cell := Vector2i(x, y)
			Gameboard.pathfinder.add_point(Gameboard.cell_to_index(cell), Vector2(cell))
	for y in range(1, GRID_SIZE.y - 1):
		for x in range(1, GRID_SIZE.x - 1):
			var cell := Vector2i(x, y)
			for offset: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				var next_cell: Vector2i = cell + offset
				if next_cell.x < GRID_SIZE.x - 1 and next_cell.y < GRID_SIZE.y - 1:
					Gameboard.pathfinder.connect_points(
						Gameboard.cell_to_index(cell), Gameboard.cell_to_index(next_cell)
					)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Gamepiece
	player.name = "BossPlayer"
	player.position = Gameboard.cell_to_pixel(Vector2i(15, 14))
	player.move_speed = 96.0
	player.animation_scene = PLAYER_ANIMATION_SCENE
	var visual_root := player.get_node("PathFollow2D") as PathFollow2D
	visual_root.scale = Vector2(0.05, 0.05)
	var controller := PLAYER_CONTROLLER_SCENE.instantiate() as PlayerController
	controller.dash_enabled = true
	player.add_child(controller)
	add_child(player)
	var health := PLAYER_HEALTH_SCENE.instantiate() as FieldHealth
	health.max_health = 12
	player.add_child(health)
	player_hit_box = PLAYER_HITBOX_SCENE.instantiate() as FieldHitBox
	player_hit_box.team = &"player"
	player_hit_box.health_path = NodePath("../FieldHealth")
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	(player_hit_box.get_node("CollisionShape2D") as CollisionShape2D).shape = shape
	player.add_child(player_hit_box)
	var combo := COMBO_SCENE.instantiate() as FieldComboAttack
	combo.attack_hit.connect(func(step: int, _box: FieldHitBox, damage: int):
		if damage > 0: _camera_shake.start_shake(1.5 + step, 0.1))
	player.add_child(combo)
	Player.gamepiece = player
	player_bar.bind_health(health)
	health.health_depleted.connect(_on_player_depleted)


func _spawn_boss() -> void:
	boss = BOSS_SCENE.instantiate() as BadCatBoss
	boss.position = Vector2(240, 75)
	add_child(boss)
	boss_bar.bind_health(boss.health)
	boss.defeated.connect(_on_boss_defeated)
	boss.player_hit.connect(func(_damage: int): _camera_shake.start_shake(3.0, 0.16))


func _start_battle() -> void:
	boss_panel.modulate.a = 0.0
	boss_panel.position.y -= 30.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(boss_panel, "modulate:a", 1.0, 0.45)
	tween.tween_property(boss_panel, "position:y", boss_panel.position.y + 30.0, 0.45).set_trans(Tween.TRANS_BACK)
	await boss.start_battle(player)


func _on_boss_defeated() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(boss_panel, "modulate:a", 0.0, 0.45)
	tween.tween_property(boss_panel, "position:y", boss_panel.position.y - 30.0, 0.45)
	result_label.text = "BOSS CLEAR!  \\ 키 → MAIN"
	result_label.show()


func _on_player_depleted(_source: Node) -> void:
	result_label.text = "DEFEATED...  \\ 키 → BOSS 재도전"
	result_label.show()
	if boss:
		boss.active = false
