extends CanvasLayer

const MAIN_SCENE_PATH := "res://src/main.tscn"
const GRLAB_SCENE_PATH := "res://src/dev/dev_test_lab.tscn"

var _is_open := false
var _was_tree_paused := false
var _return_scene_path := MAIN_SCENE_PATH
var _is_changing_scene := false

@onready var _history: RichTextLabel = %History
@onready var _command_input: LineEdit = %CommandInput


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_command_input.text_submitted.connect(_on_command_submitted)
	hide()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var is_console_key := key_event.keycode == KEY_BACKSLASH \
		or key_event.physical_keycode == KEY_BACKSLASH
	if is_console_key:
		get_viewport().set_input_as_handled()
		set_console_open(not _is_open)
	elif _is_open and key_event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		set_console_open(false)


func set_console_open(value: bool) -> void:
	if value == _is_open or _is_changing_scene:
		return

	_is_open = value
	if _is_open:
		_was_tree_paused = get_tree().paused
		get_tree().paused = true
		show()
		_command_input.clear()
		_command_input.grab_focus()
		if _history.text.is_empty():
			_write_system_message("개발자 콘솔입니다. HELP로 명령어를 확인하세요.")
	else:
		_command_input.release_focus()
		hide()
		get_tree().paused = _was_tree_paused


func go_to_lab() -> void:
	_request_scene_change(GRLAB_SCENE_PATH)


func go_to_main() -> void:
	_request_scene_change(_return_scene_path if not _return_scene_path.is_empty() else MAIN_SCENE_PATH)


func _on_command_submitted(raw_command: String) -> void:
	var command := raw_command.strip_edges().to_upper()
	_command_input.clear()

	if command.is_empty():
		return

	_history.append_text("[color=#f6c177]> %s[/color]\n" % command)
	match command:
		"GRLAB":
			_write_system_message("GRLAB 개발자 테스트 공간으로 이동합니다.")
			go_to_lab()
		"MAIN", "RETURN":
			_write_system_message("기존 게임으로 돌아갑니다.")
			go_to_main()
		"HELP":
			_write_system_message("GRLAB  테스트 공간 이동\nMAIN   기존 게임으로 복귀\nCLEAR  콘솔 기록 지우기")
		"CLEAR":
			_history.clear()
		_:
			_write_system_message("알 수 없는 명령어: %s (HELP를 입력하세요.)" % command)

	_command_input.grab_focus()


func _request_scene_change(scene_path: String) -> void:
	if _is_changing_scene:
		return

	var current_scene := get_tree().current_scene
	if current_scene and current_scene.scene_file_path == scene_path:
		_write_system_message("이미 해당 공간에 있습니다.")
		return

	if scene_path == GRLAB_SCENE_PATH and current_scene and not current_scene.scene_file_path.is_empty():
		_return_scene_path = current_scene.scene_file_path

	_change_scene.call_deferred(scene_path)


func _change_scene(scene_path: String) -> void:
	if _is_open:
		set_console_open(false)
	_is_changing_scene = true
	get_tree().paused = false

	await Transition.cover(0.18)
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		await Transition.clear(0.18)
		_is_changing_scene = false
		set_console_open(true)
		_write_system_message("씬을 열 수 없습니다. 오류 코드: %d" % error)
		return

	await get_tree().process_frame
	await Transition.clear(0.18)
	_is_changing_scene = false


func _write_system_message(message: String) -> void:
	_history.append_text("[color=#9ccfd8]%s[/color]\n" % message)
	_history.scroll_to_line(maxi(0, _history.get_line_count() - 1))
