class_name SavePaths
extends RefCounted

## 저장 데이터는 모두 user:// 아래에만 둡니다. res:// 경로는 게임 정의 데이터 전용입니다.
const LEGACY_ROSTER := "user://minion_cat_roster.tres"
const LEGACY_INVENTORY := "user://inventory.tres"

const DEV_ROOT := "user://dev"
const RELEASE_ROOT := "user://saves/slot_01"
const TEST_ROOT := "user://tests"

const DEV_ROSTER := DEV_ROOT + "/minion_cat_roster.tres"
const DEV_INVENTORY := DEV_ROOT + "/inventory.tres"
const RELEASE_ROSTER := RELEASE_ROOT + "/minion_cat_roster.tres"
const RELEASE_INVENTORY := RELEASE_ROOT + "/inventory.tres"

const LEGACY_ROSTER_BACKUP := DEV_ROOT + "/migration_backups/minion_cat_roster.legacy.tres"
const LEGACY_INVENTORY_BACKUP := DEV_ROOT + "/migration_backups/inventory.legacy.tres"


static func is_development_build() -> bool:
	return OS.is_debug_build()


static func get_roster_path() -> String:
	return DEV_ROSTER if is_development_build() else RELEASE_ROSTER


static func get_inventory_path() -> String:
	return DEV_INVENTORY if is_development_build() else RELEASE_INVENTORY


static func get_test_path(file_name: String) -> String:
	var safe_name := file_name.get_file().validate_filename()
	if safe_name.get_extension().is_empty():
		safe_name += ".tres"
	return TEST_ROOT.path_join(safe_name)
