extends Node2D

const MINION_FOLLOW_CONTROLLER_SCRIPT := preload(
	"res://src/field/cats/minion_follow_controller.gd"
)

#네임테그 / nametag / NAMETAGE
const ENEMY_CAT_NAME_COLOR := Color("#ff4d4d")
const MINION_CAT_NAME_COLOR := Color("#4d9dff")

const TEST_ENEMY_CAT_CELL := Vector2i(80, 60)
const ENEMY_CAT_SCENE := preload(
	"res://src/field/cats/enemy_cat.tscn"
)

const MINION_CAT_SCENE := preload(
	"res://src/field/cats/minion_cat.tscn"
)
const CAT_NAME_TAG_SCRIPT := preload("res://src/field/cats/cat_name_tag.gd")
const FIELD_HEALTH_SCENE := preload("res://src/field/combat/field_health.tscn")
const FIELD_HIT_BOX_SCENE := preload("res://src/field/combat/field_hit_box.tscn")
const FIELD_COMBO_ATTACK_SCENE := preload("res://src/field/combat/field_combo_attack.tscn")

const MAP_DATA_PATH := "res://assets/maps/my_map_compact.json"
const MAP_CELL_SIZE := 16.0
const PLAYER_SCENE := preload("res://src/field/gamepieces/gamepiece.tscn")
const PLAYER_CONTROLLER_SCENE := preload("res://src/field/gamepieces/controllers/player_controller.tscn")
const PLAYER_ANIMATION_SCENE := preload("res://assets/characters/bbiyong/bbiyong_lab_gfx.tscn")
const CAMERA_SHAKE_SCRIPT := preload("res://src/common/camera_shake_2d.gd")
# 320x330 삐용 프레임을 메인 16x16 로봇과 비슷한 화면 크기로 맞춥니다.
const PLAYER_VISUAL_SCALE := Vector2(0.05, 0.05)
const CAMERA_ZOOM := Vector2(10.0, 10.0)

const CHARACTER_PREVIEWS := [
	["GoBot", "res://overworld/characters/gobot_gfx.tscn"],
	["Generic", "res://overworld/characters/generic_character_gfx.tscn"],
	["Knight", "res://overworld/characters/knight_gfx.tscn"],
	["Monk", "res://overworld/characters/monk_gfx.tscn"],
	["Thief", "res://overworld/characters/thief_gfx.tscn"],
	["Smith", "res://overworld/characters/smith_gfx.tscn"],
	["Wizard", "res://overworld/characters/wizard_gfx.tscn"],
	["Ghost", "res://overworld/characters/ghost_gfx.tscn"],
]

const BATTLER_PREVIEWS := [
	["Bear", "res://combat/battlers/bear/bear.png"],
	["Squirrel", "res://combat/battlers/squirrel/squirrel.png"],
	["Bugcat", "res://combat/battlers/bugcat/bugcat.png"],
	["Wolf", "res://combat/battlers/wolf/wolf.png"],
]

const ITEM_PREVIEWS := [
	["Key", "res://assets/items/key.atlastex"],
	["Coin", "res://assets/items/coin.atlastex"],
	["Bomb", "res://assets/items/bomb.atlastex"],
	["Red Wand", "res://assets/items/wand_red.atlastex"],
	["Blue Wand", "res://assets/items/wand_blue.atlastex"],
	["Green Wand", "res://assets/items/wand_green.atlastex"],
]

const EMOTE_PREVIEWS := [
	["Empty", "res://assets/gui/emotes/emote__.png"],
	["Combat", "res://assets/gui/emotes/emote_combat.png"],
	["Exclamation", "res://assets/gui/emotes/emote_exclamations.png"],
	["Question", "res://assets/gui/emotes/emote_question.png"],
]

const OTHER_PREVIEWS := [
	["Closed Door", "res://overworld/maps/tilesets/town_tilemap.png", Rect2(17, 119, 16, 16)],
	["Open Door", "res://overworld/maps/tilesets/town_tilemap.png", Rect2(34, 102, 16, 16)],
	["Treasure Chest", "res://overworld/maps/tilesets/dungeon_tilemap.png", Rect2(85, 119, 16, 16)],
	["Destination", "res://assets/gui/path_destination_marker.tres", Rect2()],
]

var _map_data: Dictionary = {}
var _map_origin := Vector2.ZERO
var _map_pixel_size := Vector2.ZERO
var _walkable_cells: Dictionary[Vector2i, bool] = {}
var _lab_properties: GameboardProperties
var _player: Gamepiece
var _map_render_root: Node2D
var _camera_shake

@onready var _test_objects: Node2D = $TestObjects
@onready var _camera: Camera2D = $Camera2D
@onready var _map_info: Label = %MapInfo


func _ready() -> void:
	# GRLAB uses its own camera, so attach the same reusable shake component used by FieldCamera.
	_camera_shake = CAMERA_SHAKE_SCRIPT.new()
	_camera_shake.name = "CameraShake"
	_camera.add_child(_camera_shake)

	_map_data = _load_map_data()
	_setup_map_transform()
	_create_map_renderer()
	_setup_gameboard()
	_create_preview_objects()

	_spawn_player()
	_spawn_active_minion()
	_spawn_test_enemy_cat()
	_camera.make_current()
	queue_redraw()

func _find_enemy_test_cell(player_cell: Vector2i) -> Vector2i:
	var offsets: Array[Vector2i] = [
		Vector2i(4, 0),
		Vector2i(-4, 0),
		Vector2i(0, 4),
		Vector2i(0, -4),

		Vector2i(5, 0),
		Vector2i(-5, 0),
		Vector2i(0, 5),
		Vector2i(0, -5)
	]

	for offset in offsets:
		var cell: Vector2i = player_cell + offset

		# 걸을 수 없는 셀
		if not _walkable_cells.has(cell):
			continue

		# 이미 다른 Gamepiece가 있는 셀
		if GamepieceRegistry.get_gamepiece(cell) != null:
			continue

		return cell

	return Gameboard.INVALID_CELL


func _on_enemy_cat_recruit_requested(enemy) -> void:
	if not is_instance_valid(enemy):
		return

	var enemy_cell: Vector2i = GamepieceRegistry.get_cell(enemy)

	if enemy_cell == Gameboard.INVALID_CELL:
		push_error("Recruit: EnemyCat의 셀을 찾을 수 없습니다.")
		return

	# EnemyCat의 기존 상태 보존
	var old_animation_scene: PackedScene = enemy.animation_scene
	var old_move_speed: float = enemy.move_speed
	var old_direction = enemy.direction
	var old_z_index: int = enemy.z_index
	var old_field_health := enemy.get_node_or_null("FieldHealth") as FieldHealth
	var old_health_value := old_field_health.health if old_field_health != null else 6
	var old_max_health := old_field_health.max_health if old_field_health != null else 6
	# 필드 노드와 별개인 영구 개체 데이터를 먼저 보유 목록에 저장한다.
	var minion_data: MinionCatData = MinionCats.register_from_enemy(enemy)
	if minion_data == null:
		push_error("Recruit: MinionCat 데이터 저장 실패")
		return

	print(
		"ENEMY -> MINION | cell = ",
		enemy_cell
	)

	# =========================
	# EnemyCat 제거
	# =========================

	enemy.queue_free()

	# GamepieceRegistry에서도 완전히 제거될 때까지 기다림
	await enemy.tree_exited


	# =========================
	# MinionCat 생성
	# =========================

	var minion := MINION_CAT_SCENE.instantiate() as MinionCat

	if minion == null:
		push_error("MinionCat 생성 실패")
		return

	minion.name = "MinionCat_%s" % minion_data.unique_id
	minion.minion_id = minion_data.unique_id
	minion.display_name = minion_data.display_name
	minion.position = Gameboard.cell_to_pixel(enemy_cell)
	minion.move_speed = old_move_speed
	minion.z_index = old_z_index

	add_child(minion)

	# 기존 EnemyCat과 같은 그래픽 사용
	minion.animation_scene = old_animation_scene
	if minion.field_health != null:
		minion.field_health.max_health = old_max_health
		minion.field_health.set_health(old_health_value)
	MinionCats.bind_runtime_minion(minion)
	if MinionCats.is_active_minion(
		minion_data
	):
		_attach_minion_ai(
			minion,
			minion_data
		)

	# GRLAB 삐용 그래픽을 임시 사용 중이므로 같은 비율 적용
	_apply_gamepiece_visual_scale(minion)
	_add_cat_name_label(
		minion,
		minion_data.display_name,
		MINION_CAT_NAME_COLOR
	)

	minion.direction = old_direction

	print(
		"RECRUIT COMPLETE : ",
		minion.name
	)
func _draw() -> void:
	draw_rect(Rect2(Vector2(-5000, -5000), Vector2(10000, 10000)), Color("100f19"))
	if _map_data.is_empty():
		return

	var map_rect := Rect2(_map_origin, _map_pixel_size)
	draw_rect(map_rect.grow(18), Color("07111d"), true)
	draw_rect(map_rect, Color("9ccfd8"), false, 3.0)


func _create_map_renderer() -> void:
	if _map_data.is_empty():
		return

	var image_size := Vector2i(int(_map_pixel_size.x), int(_map_pixel_size.y))
	var map_image := Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	map_image.fill(_packed_color(_map_data.colors.background).darkened(0.46))

	var ground_cells: Dictionary[Vector2i, int] = {}
	for run in _parse_runs(_map_data.get("ground_runs", "")):
		for cell in _cells_from_run(run):
			ground_cells[cell] = run[3]

	for cell in ground_cells:
		_paint_ground_cell(map_image, cell, ground_cells[cell])
	_paint_region_edges(map_image, ground_cells, Color("17131d"), 2)

	var water_cells: Dictionary[Vector2i, bool] = {}
	for cell in _cells_from_runs(_map_data.get("pool_runs", "")):
		water_cells[cell] = true
		_paint_water_cell(map_image, cell)
	_paint_region_edges(map_image, water_cells, _packed_color(_map_data.colors.water).darkened(0.4), 2)

	var tree_cells: Dictionary[Vector2i, bool] = {}
	var fence_cells: Dictionary[Vector2i, bool] = {}
	for run in _parse_runs(_map_data.get("object_runs", "")):
		if run[3] == 5:
			for cell in _cells_from_run(run):
				tree_cells[cell] = true
		else:
			for cell in _cells_from_run(run):
				fence_cells[cell] = true

	for cell in tree_cells:
		_paint_tree_cell(map_image, cell)
	_paint_region_edges(map_image, tree_cells, Color("172218"), 2)

	for cell in fence_cells:
		_paint_fence_cell(map_image, cell, fence_cells)

	_map_render_root = Node2D.new()
	_map_render_root.name = "MapRenderer"
	_map_render_root.position = _map_origin
	_map_render_root.z_index = 0
	add_child(_map_render_root)
	move_child(_map_render_root, 0)

	var map_sprite := Sprite2D.new()
	map_sprite.name = "MapTexture"
	map_sprite.centered = false
	map_sprite.texture = ImageTexture.create_from_image(map_image)
	map_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_map_render_root.add_child(map_sprite)


func _paint_ground_cell(image: Image, cell: Vector2i, ground_type: int) -> void:
	var rect := _cell_rect(cell)
	var color := _ground_color(ground_type)
	image.fill_rect(rect, color)

	var detail := color.lightened(0.08)
	var seed := posmod(cell.x * 37 + cell.y * 71 + ground_type * 13, 11)
	if ground_type == 10:
		image.fill_rect(Rect2i(rect.position + Vector2i(1, 1), Vector2i(14, 1)), color.darkened(0.08))
		image.fill_rect(Rect2i(rect.position + Vector2i(1, 8), Vector2i(14, 1)), color.darkened(0.06))
	elif ground_type == 7:
		image.fill_rect(Rect2i(rect.position + Vector2i(3 + seed % 7, 4), Vector2i(2, 1)), detail)
		image.fill_rect(Rect2i(rect.position + Vector2i(9, 11 - seed % 4), Vector2i(1, 1)), detail)
	else:
		image.fill_rect(Rect2i(rect.position + Vector2i(2 + seed % 8, 3), Vector2i(3, 1)), detail)
		image.fill_rect(Rect2i(rect.position + Vector2i(7, 10 + seed % 3), Vector2i(2, 1)), color.darkened(0.08))


func _paint_water_cell(image: Image, cell: Vector2i) -> void:
	var rect := _cell_rect(cell)
	var water := _packed_color(_map_data.colors.water)
	image.fill_rect(rect, water)
	var wave_y := 3 + posmod(cell.x * 3 + cell.y * 5, 8)
	image.fill_rect(Rect2i(rect.position + Vector2i(2, wave_y), Vector2i(6, 1)), water.lightened(0.22))
	image.fill_rect(Rect2i(rect.position + Vector2i(10, posmod(wave_y + 6, 14)), Vector2i(3, 1)), water.darkened(0.14))


func _paint_tree_cell(image: Image, cell: Vector2i) -> void:
	var rect := _cell_rect(cell)
	var tree := _packed_color(_map_data.colors.tree)
	image.fill_rect(rect, tree.darkened(0.18))
	image.fill_rect(Rect2i(rect.position + Vector2i(2, 1), Vector2i(12, 12)), tree)
	image.fill_rect(Rect2i(rect.position + Vector2i(5, 3), Vector2i(5, 5)), tree.lightened(0.16))
	image.fill_rect(Rect2i(rect.position + Vector2i(7, 12), Vector2i(3, 4)), Color("694d31"))


func _paint_fence_cell(image: Image, cell: Vector2i, fence_cells: Dictionary[Vector2i, bool]) -> void:
	var origin := cell * int(MAP_CELL_SIZE)
	var fence := _packed_color(_map_data.colors.fence)
	var outline := fence.darkened(0.42)
	var has_horizontal := fence_cells.has(cell + Vector2i.LEFT) or fence_cells.has(cell + Vector2i.RIGHT)
	var has_vertical := fence_cells.has(cell + Vector2i.UP) or fence_cells.has(cell + Vector2i.DOWN)

	if has_horizontal or not has_vertical:
		image.fill_rect(Rect2i(origin + Vector2i(0, 6), Vector2i(16, 5)), outline)
		image.fill_rect(Rect2i(origin + Vector2i(0, 7), Vector2i(16, 3)), fence)
	if has_vertical or not has_horizontal:
		image.fill_rect(Rect2i(origin + Vector2i(6, 0), Vector2i(5, 16)), outline)
		image.fill_rect(Rect2i(origin + Vector2i(7, 0), Vector2i(3, 16)), fence)
	image.fill_rect(Rect2i(origin + Vector2i(5, 5), Vector2i(7, 7)), outline)
	image.fill_rect(Rect2i(origin + Vector2i(7, 6), Vector2i(3, 6)), fence.lightened(0.08))


func _paint_region_edges(image: Image, cells: Dictionary, edge_color: Color, thickness: int) -> void:
	var cell_size := int(MAP_CELL_SIZE)
	for cell: Vector2i in cells:
		var origin := cell * cell_size
		if not cells.has(cell + Vector2i.UP):
			image.fill_rect(Rect2i(origin, Vector2i(cell_size, thickness)), edge_color)
		if not cells.has(cell + Vector2i.DOWN):
			image.fill_rect(Rect2i(origin + Vector2i(0, cell_size - thickness), Vector2i(cell_size, thickness)), edge_color)
		if not cells.has(cell + Vector2i.LEFT):
			image.fill_rect(Rect2i(origin, Vector2i(thickness, cell_size)), edge_color)
		if not cells.has(cell + Vector2i.RIGHT):
			image.fill_rect(Rect2i(origin + Vector2i(cell_size - thickness, 0), Vector2i(thickness, cell_size)), edge_color)


func _cell_rect(cell: Vector2i) -> Rect2i:
	return Rect2i(cell * int(MAP_CELL_SIZE), Vector2i.ONE * int(MAP_CELL_SIZE))


func _load_map_data() -> Dictionary:
	var file := FileAccess.open(MAP_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("GRLAB map data could not be opened: %s" % MAP_DATA_PATH)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	push_error("GRLAB map data is invalid JSON: %s" % MAP_DATA_PATH)
	return {}


func _setup_map_transform() -> void:
	if _map_data.is_empty():
		return

	_map_pixel_size = Vector2(_map_data.width, _map_data.height) * MAP_CELL_SIZE
	_map_origin = Vector2.ZERO
	_map_info.text = "MyMap.json · RPG Map 2 v%s · %d×%d" % [
		str(_map_data.app_version), int(_map_data.width), int(_map_data.height)
	]


func _setup_gameboard() -> void:
	if _map_data.is_empty():
		return

	_lab_properties = GameboardProperties.new()
	_lab_properties.extents = Rect2i(0, 0, int(_map_data.width), int(_map_data.height))
	_lab_properties.cell_size = Vector2i(int(MAP_CELL_SIZE), int(MAP_CELL_SIZE))
	Gameboard.properties = _lab_properties
	Gameboard.pathfinder.clear()

	for cell in _cells_from_runs(_map_data.get("ground_runs", "")):
		_walkable_cells[cell] = true

	var blocked_cells: Dictionary[Vector2i, bool] = {}
	for cell in _cells_from_runs(_map_data.get("pool_runs", "")):
		blocked_cells[cell] = true
	for cell in _cells_from_runs(_map_data.get("object_runs", "")):
		blocked_cells[cell] = true
	for collision_value in String(_map_data.get("collisions", "")).split(",", false):
		var index := collision_value.to_int()
		blocked_cells[Vector2i(index % int(_map_data.width), index / int(_map_data.width))] = true

	for cell in blocked_cells:
		_walkable_cells.erase(cell)

	for cell in _walkable_cells:
		Gameboard.pathfinder.add_point(Gameboard.cell_to_index(cell), Vector2(cell))

	for cell in _walkable_cells:
		var cell_id := Gameboard.cell_to_index(cell)
		for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbour: Vector2i = cell + offset
			if _walkable_cells.has(neighbour):
				Gameboard.pathfinder.connect_points(cell_id, Gameboard.cell_to_index(neighbour))

	_map_info.text = " 이것은 테스트용 공간이다 이것은 테스트용 공간이다 v%s %d%d %d" % [
		str(_map_data.app_version), int(_map_data.width), int(_map_data.height),
		_walkable_cells.size()
	]
	_map_info.add_theme_font_size_override("font_size", 32)


func _cells_from_runs(value: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for run in _parse_runs(value):
		cells.append_array(_cells_from_run(run))
	return cells


func _cells_from_run(run: PackedInt32Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(run[1], run[1] + run[2]):
		cells.append(Vector2i(x, run[0]))
	return cells


func _spawn_player() -> void:
	var spawn_cell := _find_spawn_cell()
	if spawn_cell == Gameboard.INVALID_CELL:
		push_error("GRLAB could not find a walkable player spawn cell.")
		return

	_player = PLAYER_SCENE.instantiate() as Gamepiece
	_player.name = "LabPlayer"
	_player.position = Gameboard.cell_to_pixel(spawn_cell)
	_player.move_speed = 96.0
	_player.z_index = 100
	_player.animation_scene = PLAYER_ANIMATION_SCENE
	#var visual_root := _player.get_node("PathFollow2D") as PathFollow2D
	#visual_root.scale = PLAYER_VISUAL_SCALE
	_apply_gamepiece_visual_scale(_player)
	var controller := PLAYER_CONTROLLER_SCENE.instantiate() as PlayerController
	controller.dash_enabled = true
	controller.dash_started.connect(_on_player_dash_started)
	_player.add_child(controller)
	add_child(_player)
	_add_field_combat_components(_player, &"player", 12)
	var combo_attack := FIELD_COMBO_ATTACK_SCENE.instantiate() as FieldComboAttack
	combo_attack.attack_hit.connect(_on_player_attack_hit)
	_player.add_child(combo_attack)
	Player.gamepiece = _player

	_camera.zoom = CAMERA_ZOOM
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	_camera.offset = Vector2.ZERO

	_camera.global_position = _player.global_position# 처음부터 플레이어 위치

	_camera.position_smoothing_enabled = false #
	_camera.limit_enabled = false #카메라 중앙 그거 멈춤

	_player.animation_transform.update_position = true
	_player.animation_transform.update_rotation = false
	_player.animation_transform.update_scale = false
	_player.animation_transform.use_global_coordinates = true
	_player.animation_transform.remote_path = \
	_player.animation_transform.get_path_to(_camera)


	#_camera.position_smoothing_speed = 8.0
	#_camera.limit_left = 0
	#_camera.limit_top = 0
	#_camera.limit_right = int(_map_pixel_size.x)
	#_camera.limit_bottom = int(_map_pixel_size.y-100)
	#_player.animation_transform.remote_path = _player.animation_transform.get_path_to(_camera)


func _on_player_dash_started() -> void:
	# CAMERA_ZOOM also magnifies world-space offsets, so a small amplitude is enough in GRLAB.
	_camera_shake.start_shake(4.0, 0.15)


func _on_player_attack_hit(
		combo_step: int,
		_hit_box: FieldHitBox,
		applied_damage: int
) -> void:
	if applied_damage <= 0:
		return
	_camera_shake.start_shake(2.0 + combo_step, 0.1)


func _add_field_combat_components(
		gamepiece: Gamepiece,
		team: StringName,
		max_health: int
) -> void:
	if gamepiece == null or gamepiece.has_node("FieldHealth"):
		return

	var health := FIELD_HEALTH_SCENE.instantiate() as FieldHealth
	health.max_health = max_health
	gamepiece.add_child(health)

	var follower := gamepiece.get_node_or_null("PathFollow2D") as PathFollow2D
	if follower == null:
		push_error("Field combat setup failed: '%s' has no PathFollow2D." % gamepiece.name)
		health.queue_free()
		return

	var hit_box := FIELD_HIT_BOX_SCENE.instantiate() as FieldHitBox
	hit_box.team = team
	hit_box.health_path = NodePath("../../FieldHealth")
	follower.add_child(hit_box)


func _find_spawn_cell() -> Vector2i:
	if _walkable_cells.is_empty():
		return Gameboard.INVALID_CELL

	var center := Vector2i(int(_map_data.width) / 2, int(_map_data.height) / 2)
	for radius in range(maxi(int(_map_data.width), int(_map_data.height))):
		for y in range(center.y - radius, center.y + radius + 1):
			for x in range(center.x - radius, center.x + radius + 1):
				if abs(x - center.x) != radius and abs(y - center.y) != radius:
					continue
				var cell := Vector2i(x, y)
				if _walkable_cells.has(cell):
					return cell
	return Gameboard.INVALID_CELL


func _create_preview_objects() -> void:
	var columns := 8
	var spacing := Vector2(210, 170)
	var start := Vector2(_map_origin.x + 100, _map_origin.y + 150)
	var index := 0

	for preview in CHARACTER_PREVIEWS:
		var animation_scene := load(preview[1]) as PackedScene
		if animation_scene:
			var animation := animation_scene.instantiate() as GamepieceAnimation
			if animation:
				_add_preview_card(animation, preview[0], start, spacing, columns, index, Vector2(4.5, 4.5))
				index += 1

	for preview in ITEM_PREVIEWS:
		var sprite := _make_sprite(preview[1])
		if sprite:
			_add_preview_card(sprite, preview[0], start, spacing, columns, index, Vector2(3.5, 3.5))
			index += 1

	for preview in EMOTE_PREVIEWS:
		var sprite := _make_sprite(preview[1])
		if sprite:
			_add_preview_card(sprite, preview[0], start, spacing, columns, index, Vector2(1.9, 1.9))
			index += 1

	for preview in OTHER_PREVIEWS:
		var sprite := _make_sprite(preview[1], preview[2])
		if sprite:
			_add_preview_card(sprite, preview[0], start, spacing, columns, index, Vector2(4.0, 4.0))
			index += 1

	var battler_start_index := index
	for preview in BATTLER_PREVIEWS:
		var sprite := _make_sprite(preview[1])
		if sprite:
			_add_preview_card(sprite, preview[0], start, spacing, columns, index, Vector2(0.28, 0.28))
			index += 1

	var badge := Label.new()
	badge.text = "PROJECT OBJECT GALLERY · %d previews" % index
	badge.position = Vector2(start.x - 80, start.y - 120)
	badge.add_theme_font_size_override("font_size", 26)
	badge.add_theme_color_override("font_color", Color("f6c177"))
	_test_objects.add_child(badge)

	var battler_note := Label.new()
	battler_note.text = "전투 원화"
	battler_note.position = _preview_position(start, spacing, columns, battler_start_index) + Vector2(-75, -115)
	battler_note.add_theme_font_size_override("font_size", 18)
	battler_note.add_theme_color_override("font_color", Color("ebbcba"))
	_test_objects.add_child(battler_note)


func _add_preview_card(node: Node2D, title: String, start: Vector2, spacing: Vector2,
		columns: int, index: int, preview_scale: Vector2) -> void:
	var card := Node2D.new()
	card.name = title.replace(" ", "")
	card.position = _preview_position(start, spacing, columns, index)
	_test_objects.add_child(card)

	var backdrop := Polygon2D.new()
	backdrop.polygon = PackedVector2Array([
		Vector2(-86, -64), Vector2(86, -64), Vector2(86, 78), Vector2(-86, 78)
	])
	backdrop.color = Color(0.027, 0.043, 0.075, 0.84)
	card.add_child(backdrop)

	node.scale = preview_scale
	node.position = Vector2(0, -6)
	card.add_child(node)

	var label := Label.new()
	label.text = title
	label.position = Vector2(-86, 48)
	label.size = Vector2(172, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("e5e7eb"))
	card.add_child(label)


func _make_sprite(texture_path: String, region := Rect2()) -> Sprite2D:
	var texture := load(texture_path) as Texture2D
	if not texture:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = texture
	if region.has_area():
		sprite.region_enabled = true
		sprite.region_rect = region
	return sprite


func _preview_position(start: Vector2, spacing: Vector2, columns: int, index: int) -> Vector2:
	return start + Vector2(index % columns, index / columns) * spacing


func _ground_color(ground_type: int) -> Color:
	match ground_type:
		0:
			return _packed_color(_map_data.colors.cobblestone).darkened(0.12)
		7:
			return _packed_color(_map_data.colors.sand).darkened(0.08)
		10:
			return _packed_color(_map_data.colors.large_tile).darkened(0.1)
		_:
			return _packed_color(_map_data.colors.background)


func _packed_color(value) -> Color:
	return Color.hex(int(value) * 256 + 255)


func _parse_runs(value: String) -> Array[PackedInt32Array]:
	var parsed_runs: Array[PackedInt32Array] = []
	for encoded_run in value.split(";", false):
		var values := encoded_run.split(",", false)
		if values.size() != 4:
			continue
		parsed_runs.append(PackedInt32Array([
			values[0].to_int(), values[1].to_int(), values[2].to_int(), values[3].to_int()
		]))
	return parsed_runs


func _exit_tree() -> void:
	if Player.gamepiece == _player:
		Player.gamepiece = null
	if Gameboard.properties == _lab_properties:
		Gameboard.pathfinder.clear()



func _on_return_pressed() -> void:
	DeveloperConsole.go_to_main()

func _spawn_test_enemy_cat() -> void:
	var enemy_cell: Vector2i = TEST_ENEMY_CAT_CELL

	# 지정 위치 검사
	if not _walkable_cells.has(enemy_cell):
		push_error(
			"EnemyCat 테스트: 지정한 셀이 걸을 수 없는 위치입니다. cell=%s"
			% enemy_cell
		)
		return

	if GamepieceRegistry.get_gamepiece(enemy_cell) != null:
		push_error(
			"EnemyCat 테스트: 지정한 셀에 이미 다른 Gamepiece가 있습니다. cell=%s"
			% enemy_cell
		)
		return

	# =========================
	# EnemyCat 생성
	# =========================

	var enemy := ENEMY_CAT_SCENE.instantiate() as EnemyCat

	if enemy == null:
		push_error("EnemyCat 생성 실패")
		return

	enemy.name = "TestEnemyCat"
	enemy.position = Gameboard.cell_to_pixel(enemy_cell)
	enemy.move_speed = 64.0
	enemy.z_index = 100

	# 임시로 삐용 그래픽
	enemy.animation_scene = PLAYER_ANIMATION_SCENE

	# 삐용과 같은 크기
	_apply_gamepiece_visual_scale(enemy)


	add_child(enemy)
	# 이름표
	_add_cat_name_label(
		enemy,
		"적고양이",
		ENEMY_CAT_NAME_COLOR
	)

	# 편입 신호
	enemy.recruit_requested.connect(
		_on_enemy_cat_recruit_requested
	)

	#add_child(enemy)

	print(
		"ENEMY CAT SPAWNED | cell = ",
		enemy_cell,
		" | pixel = ",
		Gameboard.cell_to_pixel(enemy_cell)
	)
func _apply_gamepiece_visual_scale(gamepiece: Gamepiece) -> void:  #삐용이 크기로 통일하도록 만드는 개쩔어버리는 시발 함수
	if gamepiece == null:
		return

	var visual_root := gamepiece.get_node_or_null("PathFollow2D") as PathFollow2D

	if visual_root == null:
		push_warning(
			"Gamepiece '%s'에 PathFollow2D가 없습니다."
			% gamepiece.name
		)
		return

	visual_root.scale = PLAYER_VISUAL_SCALE

#이름표 생성함수
func _add_cat_name_label(
	gamepiece: Gamepiece,
	display_name: String,
	name_color: Color
) -> void:

	if gamepiece == null:
		return

	var follower := gamepiece.get_node_or_null("PathFollow2D") as PathFollow2D

	if follower == null:
		push_warning(
			"Gamepiece '%s'에 PathFollow2D가 없습니다."
			% gamepiece.name
		)
		return

	if follower.has_node("CatNameTag"):
		return


	# =========================
	# 이름표 루트
	# =========================

	var tag_root := CAT_NAME_TAG_SCRIPT.new() as CatNameTag
	tag_root.name = "CatNameTag"
	tag_root.z_index = 4096
	follower.add_child(tag_root)
	tag_root.setup(follower, _camera)


	# =========================
	# 실제 이름
	# =========================

	var label := Label.new()

	label.name = "CatNameLabel"
	label.text = "<%s>" % display_name

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	label.add_theme_font_size_override(
		"font_size",
		16
	)

	label.add_theme_color_override(
		"font_color",
		name_color
	)

	tag_root.add_child(label)

	# Control 노드는 트리에 들어갈 때 레이아웃 값이 다시 계산될 수 있으므로,
	# 자식으로 추가한 다음 이름표의 중심 위치와 크기를 확정한다.
	label.set_deferred("size", Vector2(120.0, 26.0))
	label.set_deferred("position", Vector2(-60.0, -13.0))


func _spawn_active_minion() -> void:
	var data := MinionCats.get_active_minion()

	if data == null:
		print("ACTIVE MINION : NONE")
		return


	var spawn_cell := _find_minion_spawn_cell()

	if spawn_cell == Gameboard.INVALID_CELL:
		push_warning(
			"출전 MinionCat을 생성할 빈 셀이 없습니다."
		)
		return


	var minion := (
		MINION_CAT_SCENE.instantiate()
		as MinionCat
	)

	if minion == null:
		return


	minion.name = (
		"MinionCat_%s"
		% data.unique_id
	)

	minion.minion_id = data.unique_id
	minion.display_name = data.display_name

	minion.position = Gameboard.cell_to_pixel(
		spawn_cell
	)

	minion.move_speed = data.move_speed
	minion.z_index = 100


	add_child(minion)


	# 저장된 외형
	if not data.animation_scene_path.is_empty():

		var animation_scene := load(
			data.animation_scene_path
		) as PackedScene

		if animation_scene:
			minion.animation_scene = animation_scene

	else:
		minion.animation_scene = (
			PLAYER_ANIMATION_SCENE
		)


	if minion.field_health:
		minion.field_health.max_health = (
			data.max_health
		)

		minion.field_health.set_health(
			data.current_health
		)


	MinionCats.bind_runtime_minion(
		minion
	)

	_apply_gamepiece_visual_scale(
		minion
	)

	_add_cat_name_label(
		minion,
		data.display_name,
		MINION_CAT_NAME_COLOR
	)

	_attach_minion_ai(
		minion,
		data
	)


	print(
		"ACTIVE MINION SPAWNED : ",
		data.display_name
	)


func _find_minion_spawn_cell() -> Vector2i:
	var player_cell := GamepieceRegistry.get_cell(
		_player
	)

	if player_cell == Gameboard.INVALID_CELL:
		return Gameboard.INVALID_CELL


	var offsets: Array[Vector2i] = [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN,

		Vector2i(-2, 0),
		Vector2i(2, 0),
		Vector2i(0, -2),
		Vector2i(0, 2),
	]


	for offset in offsets:

		var cell := player_cell + offset

		if not _walkable_cells.has(cell):
			continue

		if (
			GamepieceRegistry.get_gamepiece(cell)
			!= null
		):
			continue

		return cell


	return Gameboard.INVALID_CELL

func _attach_minion_ai(
	minion: MinionCat,
	data: MinionCatData
) -> void:

	if minion == null:
		return


	var controller := (
		MINION_FOLLOW_CONTROLLER_SCRIPT.new()
		as MinionFollowController
	)


	# 4순위에서 이 부분을 훨씬 강화 예정
	controller.attack_damage = maxi(
		data.combat_power,
		1
	)

	controller.attack_cooldown = maxf(
		0.35,
		0.95 - float(data.agility) * 0.06
	)

	minion.add_child(
		controller
	)
