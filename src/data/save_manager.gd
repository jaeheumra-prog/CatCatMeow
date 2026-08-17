class_name SaveManager
extends RefCounted

## 파일 형식이나 게임 데이터를 해석하지 않고, user:// 저장 입출력만 담당합니다.


static func load_resource(
	save_path: String,
	cache_mode := ResourceLoader.CACHE_MODE_IGNORE
) -> Resource:
	if not FileAccess.file_exists(save_path):
		return null
	return ResourceLoader.load(save_path, "", cache_mode)


static func save_resource(resource: Resource, save_path: String) -> Error:
	if resource == null or not save_path.begins_with("user://"):
		return ERR_INVALID_PARAMETER
	var directory_error := ensure_parent_directory(save_path)
	if directory_error != OK:
		return directory_error
	return ResourceSaver.save(resource, save_path)


static func ensure_parent_directory(save_path: String) -> Error:
	if not save_path.begins_with("user://"):
		return ERR_INVALID_PARAMETER
	var absolute_directory := ProjectSettings.globalize_path(save_path.get_base_dir())
	return DirAccess.make_dir_recursive_absolute(absolute_directory)


static func copy_if_absent(source_path: String, destination_path: String) -> Error:
	if FileAccess.file_exists(destination_path):
		return OK
	if not FileAccess.file_exists(source_path):
		return ERR_FILE_NOT_FOUND
	var directory_error := ensure_parent_directory(destination_path)
	if directory_error != OK:
		return directory_error
	return DirAccess.copy_absolute(
		ProjectSettings.globalize_path(source_path),
		ProjectSettings.globalize_path(destination_path)
	)


static func migrate_legacy_save(
	legacy_path: String,
	destination_path: String,
	backup_path: String
) -> Error:
	if FileAccess.file_exists(destination_path) or not FileAccess.file_exists(legacy_path):
		return OK

	# 원본을 먼저 별도 백업한 뒤 대상 경로로 복사합니다. 기존 파일은 삭제하지 않습니다.
	var backup_error := copy_if_absent(legacy_path, backup_path)
	if backup_error != OK:
		return backup_error
	return copy_if_absent(legacy_path, destination_path)
