extends CanvasLayer

const MAIN_SCENE_PATH := "res://src/main.tscn"
const GRLAB_SCENE_PATH := "res://src/dev/dev_test_lab.tscn"
const BOSS_SCENE_PATH := "res://src/dev/boss/boss_arena.tscn"
const MINIGAME1_SCENE_PATH := "res://src/dev/minigames/fish_catch/fish_catch.tscn"
const MINIGAME2_SCENE_PATH := "res://src/dev/minigames/whack_a_mole/mole_minigame.tscn"
const MINIGAME3_SCENE_PATH := "res://src/dev/minigames/runner/runner_minigame.tscn"

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


func go_to_boss() -> void:
	_request_scene_change(BOSS_SCENE_PATH)


func go_to_main() -> void:
	_request_scene_change(_return_scene_path if not _return_scene_path.is_empty() else MAIN_SCENE_PATH)


func go_to_minigame1() -> void:
	_request_scene_change(MINIGAME1_SCENE_PATH)


func go_to_minigame2() -> void:
	_request_scene_change(MINIGAME2_SCENE_PATH)


func go_to_minigame3() -> void:
	_request_scene_change(MINIGAME3_SCENE_PATH)


func _on_command_submitted(raw_command: String) -> void:
	var parts := raw_command.strip_edges().split(" ", false)
	var command := parts[0].to_upper() if not parts.is_empty() else ""
	var args := parts.slice(1)
	_command_input.clear()

	if command.is_empty():
		return

	_history.append_text("[color=#f6c177]> %s[/color]\n" % command)
	match command:
		"CATROOM", "CATS":
			_open_cat_room.call_deferred()
		"CATLIST":
			_write_system_message(MinionCats.get_roster_summary())
		"CATCODEX":
			_write_system_message(MinionCats.get_codex_summary())
		"CATITEMS":
			_write_system_message(MinionCats.get_economy_summary())
		"CATSTATUS":
			_write_system_message(MinionCats.get_cat_summary(_int_arg(args, 0)))
		"CATADD":
			_write_result(MinionCats.add_debug_cat(_string_arg(args, 0, "basic_cat")))
		"CATUNLOCK":
			_write_result(MinionCats.unlock_species(_string_arg(args, 0)))
		"CATWORKUNLOCK":
			_write_result(MinionCats.unlock_work(_string_arg(args, 0)))
		"CATWORK":
			_write_result(MinionCats.start_work(
				_int_arg(args, 0), _string_arg(args, 1), _int_arg(args, 2, -1)))
		"CATCLAIM":
			if _string_arg(args, 0).to_upper() == "ALL":
				_write_result(MinionCats.claim_all_completed())
			else:
				_write_result(MinionCats.claim_work(_int_arg(args, 0)))
		"CATGIFT":
			_write_result(MinionCats.give_item(
				_int_arg(args, 0), _string_arg(args, 1, "catnip")))
		"CATTRAIN":
			_write_result(MinionCats.give_item(
				_int_arg(args, 0), "training_treat", _string_arg(args, 1)))
		"CATGIVEITEM":
			_write_result(MinionCats.debug_give_item(
				_string_arg(args, 0), _int_arg(args, 1, 1)))
		"CATHELP":
			_write_system_message(_cat_help_text())
		"BOSS":
			_write_system_message("보스 전투 공간으로 이동합니다.")
			go_to_boss()
		"GRLAB":
			_write_system_message("GRLAB 개발자 테스트 공간으로 이동합니다.")
			go_to_lab()
		"MAIN", "RETURN":
			_write_system_message("기존 게임으로 돌아갑니다.")
			go_to_main()
		"HELP":
			_write_system_message("BOSS       보스 전투 공간 이동")
			_write_system_message(
				"GRLAB      테스트 공간 이동\n"
				+ "MAIN       기존 게임으로 복귀\n"
				+ "MINIGAME1  생선 받아먹기\n"
				+ "MINIGAME2  두더지 잡기\n"
				+ "MINIGAME3  삐용 러너\n"
				+ "CATROOM    MinionCat 관리 화면\n"
				+ "CATHELP    고양이 시스템 명령어\n"
				+ "CLEAR      콘솔 기록 지우기"
			)
		"CLEAR":
			_history.clear()
		"MINIGAME1":
			_write_system_message("미니게임 1을 실행합니다.")
			go_to_minigame1()
		"MINIGAME2":
			_write_system_message("두더지 잡기 미니게임을 실행합니다.")
			go_to_minigame2()
		"MINIGAME3", "RUNNER":
			_write_system_message("삐용 러너 미니게임을 실행합니다.")
			go_to_minigame3()
		_:
			_write_system_message("알 수 없는 명령어: %s (HELP를 입력하세요.)" % command)

	if _is_open:
		_command_input.grab_focus()


func _open_cat_room() -> void:
	if _is_open:
		set_console_open(false)
	MinionCatCollectionUI.set_open(true)


func _write_result(result: Dictionary) -> void:
	var color := "#9ccfd8" if bool(result.get("ok", false)) else "#eb6f92"
	_history.append_text("[color=%s]%s[/color]\n" % [color, String(result.get("message", ""))])
	_history.scroll_to_line(maxi(0, _history.get_line_count() - 1))


func _string_arg(args: PackedStringArray, index: int, fallback := "") -> String:
	return args[index] if index >= 0 and index < args.size() else fallback


func _int_arg(args: PackedStringArray, index: int, fallback := 0) -> int:
	var value := _string_arg(args, index)
	return value.to_int() if value.is_valid_int() else fallback


func _cat_help_text() -> String:
	return (
		"CATROOM                         관리 화면 열기\n"
		+ "CATLIST                         보유 고양이 목록\n"
		+ "CATSTATUS <번호>                개체 상세 정보\n"
		+ "CATCODEX                        종 도감\n"
		+ "CATITEMS                        재화/아이템/작업 해금 확인\n"
		+ "CATWORK <번호> <작업> [초]      작업 시작 (FISHING/RAID/BATTLE)\n"
		+ "CATCLAIM <번호|ALL>             완료 보상 수령\n"
		+ "CATGIFT <번호> CATNIP           호감도 상승\n"
		+ "CATTRAIN <번호> <스탯>          훈련간식으로 스탯 상승\n"
		+ "개발 시험: CATADD <종>, CATUNLOCK <종>, CATWORKUNLOCK <작업>, CATGIVEITEM <아이템> [수량]"
	)


func _request_scene_change(scene_path: String) -> void:
	if _is_changing_scene:
		return

	var current_scene := get_tree().current_scene
	if current_scene and current_scene.scene_file_path == scene_path:
		_write_system_message("이미 해당 공간에 있습니다.")
		return

	if scene_path in [GRLAB_SCENE_PATH, BOSS_SCENE_PATH] \
			and current_scene and not current_scene.scene_file_path.is_empty():
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
