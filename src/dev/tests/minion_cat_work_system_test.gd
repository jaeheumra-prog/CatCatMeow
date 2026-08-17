extends Node

const TEST_SAVE := "user://minion_cat_work_system_test.tres"
const ROSTER_SCRIPT := preload("res://src/field/cats/roster/minion_cat_roster.gd")

var _failed := false


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var roster = ROSTER_SCRIPT.new()
	roster.save_path = TEST_SAVE
	add_child(roster)

	_check(roster.count() == 0, "new test roster was not empty")
	_check(roster.add_debug_cat("fisher_cat").ok, "debug cat could not be added")
	_check(roster.count() == 1, "cat count did not increase")
	_check("fisher_cat" in roster.data.unlocked_species, "species was not unlocked")

	var start_result: Dictionary = roster.start_work(1, "FISHING", 1)
	_check(start_result.ok, "fishing did not start")
	var cat: MinionCatData = roster.get_by_number(1)
	cat.work_ends_unix = int(Time.get_unix_time_from_system()) - 1
	var claim_result: Dictionary = roster.claim_work(1)
	_check(claim_result.ok, "completed fishing reward could not be claimed")
	_check(roster.data.tuna_cans > 0, "fishing gave no currency")
	_check(not cat.is_working(), "work state was not cleared after claim")

	_check(not roster.start_work(1, "RAID", 1).ok, "locked raid started")
	_check(roster.unlock_work("RAID").ok, "raid did not unlock")
	_check(roster.start_work(1, "RAID", 1).ok, "unlocked raid did not start")
	cat.work_ends_unix = int(Time.get_unix_time_from_system()) - 1
	_check(roster.claim_work(1).ok, "raid reward could not be claimed")
	_check(int(roster.data.items.catnip) > 0, "raid gave no catnip")

	var old_affection := cat.affection
	_check(roster.give_item(1, "catnip").ok, "catnip could not be used")
	_check(cat.affection > old_affection, "catnip did not increase affection")
	_check(roster.debug_give_item("catnip", 20).ok, "bond test catnip was not granted")
	while cat.affection < 100:
		_check(roster.give_item(1, "catnip").ok, "catnip failed before maximum affection")
	_check(int(roster.data.items.bond_badge) == 1, "100 affection gave no bond badge")
	_check(roster.debug_give_item("training_treat").ok, "training item was not granted")
	var old_dexterity := cat.dexterity
	_check(roster.give_item(1, "training_treat", "DEXTERITY").ok, "training failed")
	_check(cat.dexterity == old_dexterity + 1, "training did not increase stat")

	var loaded := ResourceLoader.load(TEST_SAVE, "", ResourceLoader.CACHE_MODE_IGNORE) as MinionCatRosterData
	_check(loaded != null and loaded.cats.size() == 1, "roster did not persist")

	roster.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	if not _failed:
		print("MINION CAT WORK SYSTEM TEST PASSED")
	get_tree().quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("MINION CAT WORK SYSTEM TEST: %s" % message)
