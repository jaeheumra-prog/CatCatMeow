extends Node2D

const MAP_DATA_PATH := "res://assets/maps/my_map_compact.json"
const MAP_CELL_SIZE := 16.0
const PLAYER_SCENE := preload("res://src/field/gamepieces/gamepiece.tscn")
const PLAYER_CONTROLLER_SCENE := preload("res://src/field/gamepieces/controllers/player_controller.tscn")
const PLAYER_ANIMATION_SCENE := preload("res://assets/characters/bbiyong/bbiyong_lab_gfx.tscn")
const CAMERA_ZOOM := Vector2.ONE

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
var _hover_cell := Gameboard.INVALID_CELL
var _lab_properties: GameboardProperties
var _player: Gamepiece

@onready var _test_objects: Node2D = $TestObjects
@onready var _camera: Camera2D = $Camera2D
@onready var _map_info: Label = %MapInfo


func _ready() -> void:
	_map_data = _load_map_data()
	_setup_map_transform()
	_setup_gameboard()
	_create_preview_objects()
	_spawn_player()
	_camera.make_current()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell := Gameboard.pixel_to_cell(get_global_mouse_position())
		_hover_cell = cell if _walkable_cells.has(cell) else Gameboard.INVALID_CELL
		queue_redraw()
	elif event.is_action_released("select") and _hover_cell != Gameboard.INVALID_CELL:
		FieldEvents.cell_selected.emit(_hover_cell)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2(-5000, -5000), Vector2(10000, 10000)), Color("100f19"))
	if _map_data.is_empty():
		return

	var cell_size := MAP_CELL_SIZE
	var map_rect := Rect2(_map_origin, _map_pixel_size)
	draw_rect(map_rect.grow(18), Color("07111d"), true)

	for run in _parse_runs(_map_data.get("ground_runs", "")):
		var rect := Rect2(
			_map_origin + Vector2(run[1], run[0]) * cell_size,
			Vector2(run[2], 1) * cell_size
		)
		draw_rect(rect, _ground_color(run[3]), true)

	for run in _parse_runs(_map_data.get("pool_runs", "")):
		var rect := Rect2(
			_map_origin + Vector2(run[1], run[0]) * cell_size,
			Vector2(run[2], 1) * cell_size
		)
		draw_rect(rect, _packed_color(_map_data.colors.water), true)

	for run in _parse_runs(_map_data.get("object_runs", "")):
		var rect := Rect2(
			_map_origin + Vector2(run[1], run[0]) * cell_size,
			Vector2(run[2], 1) * cell_size
		)
		if run[3] == 5:
			draw_rect(rect, _packed_color(_map_data.colors.tree).darkened(0.2), true)
		else:
			draw_rect(rect, _packed_color(_map_data.colors.fence).darkened(0.15), true)

	for collision_value in String(_map_data.get("collisions", "")).split(",", false):
		var index := collision_value.to_int()
		var x := index % int(_map_data.width)
		var y := index / int(_map_data.width)
		var rect := Rect2(
			_map_origin + Vector2(x, y) * cell_size,
			Vector2.ONE * cell_size
		)
		draw_rect(rect, Color("ff5d73"), true)

	draw_rect(map_rect, Color("9ccfd8"), false, 3.0)
	if _hover_cell != Gameboard.INVALID_CELL:
		var hover_rect := Rect2(
			_map_origin + Vector2(_hover_cell) * cell_size,
			Vector2.ONE * cell_size
		)
		draw_rect(hover_rect, Color(0.96, 0.76, 0.47, 0.32), true)
		draw_rect(hover_rect, Color("f6c177"), false, 1.0)


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
	_player.add_child(PLAYER_CONTROLLER_SCENE.instantiate())
	add_child(_player)
	Player.gamepiece = _player

	_camera.zoom = CAMERA_ZOOM
	_camera.position = _player.position
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(_map_pixel_size.x)
	_camera.limit_bottom = int(_map_pixel_size.y)
	_player.animation_transform.remote_path = _player.animation_transform.get_path_to(_camera)


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


func _ground_color(type: int) -> Color:
	match type:
		0:
			return _packed_color(_map_data.colors.cobblestone).darkened(0.42)
		7:
			return _packed_color(_map_data.colors.sand).darkened(0.22)
		10:
			return _packed_color(_map_data.colors.large_tile).darkened(0.38)
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
