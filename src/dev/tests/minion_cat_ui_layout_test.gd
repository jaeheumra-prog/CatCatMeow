extends Node

var _failed := false


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	MinionCatCollectionUI.set_open(true)
	await get_tree().process_frame
	await get_tree().process_frame

	var overlay := MinionCatCollectionUI.get_node("Overlay") as Control
	var panel := MinionCatCollectionUI.get_node("Overlay/Panel") as Control
	var slots := MinionCatCollectionUI.get_node("Overlay/Panel/Margin/MainVBox/WorkSection/Slots") as Control
	var battle_slot := MinionCatCollectionUI.get_node("Overlay/Panel/Margin/MainVBox/WorkSection/Slots/BattleSlot") as Control

	_check(panel.position.x >= -0.5, "collection panel overflowed the left edge")
	_check(panel.position.y >= -0.5, "collection panel overflowed the top edge")
	_check(panel.position.x + panel.size.x <= overlay.size.x + 0.5, "collection panel overflowed the right edge")
	_check(panel.position.y + panel.size.y <= overlay.size.y + 0.5, "collection panel overflowed the bottom edge")
	_check(battle_slot.position.x + battle_slot.size.x <= slots.size.x + 0.5, "work slots overflowed horizontally")

	MinionCatCollectionUI.set_open(false)
	if not _failed:
		print("MINION CAT UI LAYOUT TEST PASSED")
	get_tree().quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("MINION CAT UI LAYOUT TEST: %s" % message)
