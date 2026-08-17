extends Node

const RESOURCE_EXTENSIONS := ["gd", "tscn", "tres"]
const SKIPPED_DIRECTORIES := [".git", ".godot"]
const RUNTIME_SKIPPED_PREFIXES := ["res://addons/dialogic/Editor"]

var _failed_paths: Array[String] = []
var _loaded_count := 0


func _ready() -> void:
	_scan_directory("res://")
	if _failed_paths.is_empty():
		print("PROJECT RESOURCE SMOKE TEST PASSED (%d resources)" % _loaded_count)
	else:
		push_error("PROJECT RESOURCE SMOKE TEST FAILED:\n%s" % "\n".join(_failed_paths))
	get_tree().quit(0 if _failed_paths.is_empty() else 1)


func _scan_directory(directory_path: String) -> void:
	for skipped_prefix in RUNTIME_SKIPPED_PREFIXES:
		if directory_path.begins_with(skipped_prefix):
			return
	for file_name in DirAccess.get_files_at(directory_path):
		if file_name.get_extension().to_lower() not in RESOURCE_EXTENSIONS:
			continue
		_check_resource(directory_path.path_join(file_name))

	for subdirectory in DirAccess.get_directories_at(directory_path):
		if subdirectory in SKIPPED_DIRECTORIES:
			continue
		_scan_directory(directory_path.path_join(subdirectory))


func _check_resource(resource_path: String) -> void:
	var resource := ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_REUSE)
	if resource == null:
		_failed_paths.append("로드 실패: %s" % resource_path)
		return
	if resource is Script and not resource.can_instantiate():
		_failed_paths.append("스크립트 인스턴스화 불가: %s" % resource_path)
		return
	_loaded_count += 1
