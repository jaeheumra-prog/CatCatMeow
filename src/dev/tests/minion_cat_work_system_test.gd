extends Node

const ROSTER_SCRIPT := preload("res://src/field/cats/roster/minion_cat_roster.gd")
const SPECIES_DATABASE := preload("res://src/field/cats/roster/minion_cat_species_database.gd")
const SAVE_PATHS := preload("res://src/data/save_paths.gd")
const SAVE_IO := preload("res://src/data/save_manager.gd")

var _failed := false
var _test_save := SAVE_PATHS.get_test_path("minion_cat_work_system_test.tres")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_check(_test_save.begins_with("user://tests/"), "automated test save escaped the tests directory")
	_check(SAVE_PATHS.DEV_ROSTER != SAVE_PATHS.RELEASE_ROSTER, "debug and release roster paths are identical")
	_check(SAVE_PATHS.LEGACY_ROSTER != SAVE_PATHS.DEV_ROSTER, "legacy and debug roster paths are identical")
	_check(SAVE_PATHS.RELEASE_ROSTER.begins_with("user://saves/slot_01/"), "release save escaped its slot")
	if SAVE_PATHS.is_development_build():
		_check(SAVE_PATHS.get_roster_path() == SAVE_PATHS.DEV_ROSTER, "debug build selected the release save")
	_test_legacy_migration()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_save))
	var roster = ROSTER_SCRIPT.new()
	roster.save_path = _test_save
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

	var loaded := ResourceLoader.load(_test_save, "", ResourceLoader.CACHE_MODE_IGNORE) as MinionCatRosterData
	_check(loaded != null and loaded.cats.size() == 1, "roster did not persist")

	roster.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_save))
	if not _failed:
		print("MINION CAT WORK SYSTEM TEST PASSED")
	get_tree().quit(1 if _failed else 0)


func _test_legacy_migration() -> void:
	var source := SAVE_PATHS.TEST_ROOT.path_join("legacy_roster_source.tres")
	var destination := SAVE_PATHS.TEST_ROOT.path_join("dev_roster_destination.tres")
	var backup := SAVE_PATHS.TEST_ROOT.path_join("legacy_roster_backup.tres")
	for path in [source, destination, backup]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var legacy_data := MinionCatRosterData.new()
	legacy_data.reputation = 17
	_check(SAVE_IO.save_resource(legacy_data, source) == OK, "legacy fixture could not be saved")
	_check(SAVE_IO.migrate_legacy_save(source, destination, backup) == OK, "legacy save migration failed")
	_check(FileAccess.file_exists(source), "legacy save was deleted during migration")
	_check(FileAccess.file_exists(backup), "legacy migration backup was not created")
	var migrated := SAVE_IO.load_resource(destination) as MinionCatRosterData
	_check(migrated != null and migrated.reputation == 17, "migrated save data changed")

	legacy_data.reputation = 99
	SAVE_IO.save_resource(legacy_data, source)
	_check(SAVE_IO.migrate_legacy_save(source, destination, backup) == OK, "repeat migration returned an error")
	migrated = SAVE_IO.load_resource(destination) as MinionCatRosterData
	_check(migrated != null and migrated.reputation == 17, "existing destination was overwritten")

	var inventory_path := SAVE_PATHS.TEST_ROOT.path_join("inventory_cache_test.tres")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(inventory_path))
	var inventory := Inventory.new()
	inventory.add(Inventory.ItemTypes.COIN, 3)
	_check(SAVE_IO.save_resource(inventory, inventory_path) == OK, "inventory fixture could not be saved")
	var inventory_a := SAVE_IO.load_resource(inventory_path, ResourceLoader.CACHE_MODE_REUSE) as Inventory
	var inventory_b := SAVE_IO.load_resource(inventory_path, ResourceLoader.CACHE_MODE_REUSE) as Inventory
	_check(inventory_a != null and inventory_a.get_item_count(Inventory.ItemTypes.COIN) == 3, "inventory data changed")
	_check(inventory_a == inventory_b, "inventory resource cache behavior changed")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(inventory_path))
	for path in [source, destination, backup]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("MINION CAT WORK SYSTEM TEST: %s" % message)
