extends Node

var _failed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	_check(MinionCats.data != null, "roster data was not restored")
	_send_roster_key()
	await get_tree().process_frame
	var overlay := MinionCatCollectionUI.get_node("Overlay") as Control
	_check(overlay.visible, "1 key did not open the collection")
	_check(get_tree().paused, "collection did not pause gameplay")
	_send_roster_key()
	await get_tree().process_frame
	_check(not overlay.visible, "second 1 key did not close the collection")
	_check(not get_tree().paused, "closing collection did not restore pause state")

	DeveloperConsole.set_console_open(true)
	DeveloperConsole._on_command_submitted("CATLIST")
	var history := DeveloperConsole.get_node("%History") as RichTextLabel
	_check("보유" in history.get_parsed_text(), "CATLIST command produced no roster output")
	DeveloperConsole._on_command_submitted("CATROOM")
	await get_tree().process_frame
	_check(overlay.visible, "CATROOM command did not open the collection")
	_check(not DeveloperConsole.visible, "CATROOM command left the console open")
	MinionCatCollectionUI.set_open(false)
	if not _failed:
		print("MINION CAT ROSTER SMOKE TEST PASSED")
	get_tree().quit(1 if _failed else 0)


func _send_roster_key() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_1
	event.physical_keycode = KEY_1
	event.pressed = true
	# Headless 환경은 OS 입력 전달을 생략하므로 실제 UI 입력 함수를 직접 검증한다.
	MinionCatCollectionUI._input(event)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("MINION CAT ROSTER SMOKE TEST: %s" % message)
