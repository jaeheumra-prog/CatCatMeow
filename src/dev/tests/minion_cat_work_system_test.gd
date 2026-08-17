extends Node

const TEST_SAVE := "user://minion_cat_work_system_test.tres"
const ROSTER_SCRIPT := preload("res://src/field/cats/roster/minion_cat_roster.gd")
const SPECIES_DATABASE := preload("res://src/field/cats/roster/minion_cat_species_database.gd")

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
	_check("american_shorthair" in roster.data.unlocked_species, "legacy species was not migrated and unlocked")
	var cat: MinionCatData = roster.get_by_number(1)
	_check(cat.species_id == "american_shorthair", "legacy species id was not normalized")
	_check(cat.role_id == "fisher", "legacy role id was not preserved")
	_check(cat.stage_id == 1, "cat did not retain its species stage")
	_check(roster.get_cats_by_species("american_shorthair").size() == 1, "species filtering lost the cat")
	_check(roster.get_species_ids_for_stage(1).size() == 4, "main stage catalog size is wrong")
	_check(SPECIES_DATABASE.SPECIES_ORDER.size() == 33, "catalog does not contain all 33 species")
	_check(not roster.is_species_unlocked("maine_coon"), "unrecruited species was unlocked")
	_check(roster.set_active_minion(1).ok, "cat could not be assigned for field deployment")
	_check(roster.get_active_minion() == cat, "active minion selection was not stored")
	_check(not roster.start_work(1, "FISHING", 1).ok, "deployed cat incorrectly started work")
	_check(roster.set_active_minion(1).ok, "active minion could not be released")
	_check(roster.get_active_minion() == null, "active minion selection was not cleared")
	_check(cat.appearance_initialized, "cat appearance was not initialized")
	var card := MinionCatCard.new()
	card.setup(cat)
	add_child(card)
	await get_tree().process_frame
	_check(card.cat_data == cat, "card does not reference the roster cat object")
	_check(card.get_meta("cat_id", "") == cat.unique_id, "card object id did not match")
	_check(card._portrait.texture != null, "card did not load the cat portrait")
	_check(card._portrait.modulate == cat.appearance_tint, "card did not reflect the cat appearance tint")
	var drag_data: Dictionary = card.make_drag_payload()
	_check(drag_data.get("cat_id", "") == cat.unique_id, "drag data lost the cat object id")
	_check(drag_data.get("species_id", "") == cat.species_id, "drag data lost the cat species")
	_check(drag_data.get("appearance_variant", -1) == cat.appearance_variant, "drag data lost the appearance variant")
	card.queue_free()
	await get_tree().process_frame

	var start_result: Dictionary = roster.start_work(1, "FISHING", 1)
	_check(start_result.ok, "fishing did not start")
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
