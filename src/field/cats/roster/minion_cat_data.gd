class_name MinionCatData
extends Resource

enum WorkType { NONE, FISHING, RAID, BATTLE }

const APPEARANCE_TINTS := [
	Color("ffffff"), Color("ffe2bd"), Color("d7e1f2"), Color("f2d6cc"), Color("d8f0cf")
]

## 필드 노드가 사라져도 남아 있는 동료 고양이 한 마리의 영구 데이터입니다.
@export var unique_id := ""
@export var display_name := "동료고양이"
@export var species_id := "basic_cat"
@export var level := 1
@export var current_health := 6
@export var max_health := 6
@export var move_speed := 64.0
@export var animation_scene_path := ""
@export var portrait_path := "res://assets/characters/bbiyong/bbiyong_lab_sheet.png"
@export var portrait_region := Rect2(0, 0, 320, 330)
@export var recruited_at_unix := 0
@export var appearance_variant := 0
@export var appearance_tint := Color.WHITE
@export var appearance_initialized := false

@export_group("성장")
@export_range(0, 100, 1) var affection := 0
@export var combat_power := 1
@export var agility := 1
@export var stamina := 1
@export var friendliness := 1
@export var dexterity := 1
@export var experience := 0
@export var equipped_accessory := ""
@export var bond_reward_claimed := false

@export_group("작업")
@export var work_type: WorkType = WorkType.NONE
@export var work_started_unix := 0
@export var work_ends_unix := 0
@export var work_ready := false


func initialize_from_enemy(enemy: EnemyCat, roster_number: int, species: Dictionary = {}) -> void:
	unique_id = "%d-%06d" % [Time.get_unix_time_from_system(), randi_range(0, 999999)]
	display_name = "동료고양이 %d" % roster_number
	species_id = enemy.species_id
	move_speed = enemy.move_speed
	recruited_at_unix = int(Time.get_unix_time_from_system())
	ensure_appearance()
	_apply_species_stats(species)
	if enemy.animation_scene:
		animation_scene_path = enemy.animation_scene.resource_path
	var health := enemy.get_node_or_null("FieldHealth") as FieldHealth
	if health:
		current_health = health.health
		max_health = health.max_health


func initialize_debug(species_key: String, roster_number: int, species: Dictionary) -> void:
	unique_id = "%d-%06d" % [Time.get_unix_time_from_system(), randi_range(0, 999999)]
	display_name = "%s %d" % [String(species.get("name", "동료고양이")), roster_number]
	species_id = species_key
	recruited_at_unix = int(Time.get_unix_time_from_system())
	ensure_appearance()
	_apply_species_stats(species)
	current_health = max_health


func _apply_species_stats(species: Dictionary) -> void:
	if species.is_empty():
		return
	combat_power = int(species.get("combat", combat_power))
	agility = int(species.get("agility", agility))
	stamina = int(species.get("stamina", stamina))
	friendliness = int(species.get("friendliness", friendliness))
	dexterity = int(species.get("dexterity", dexterity))
	max_health = int(species.get("health", max_health))
	portrait_path = String(species.get("portrait", portrait_path))
	portrait_region = species.get("portrait_region", portrait_region)


func ensure_appearance() -> void:
	if appearance_initialized:
		return
	appearance_variant = absi(unique_id.hash()) % APPEARANCE_TINTS.size()
	appearance_tint = APPEARANCE_TINTS[appearance_variant]
	appearance_initialized = true


func is_working() -> bool:
	return work_type != WorkType.NONE


func is_work_complete(now_unix: int = -1) -> bool:
	if not is_working():
		return false
	var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
	return now >= work_ends_unix


func remaining_work_seconds(now_unix: int = -1) -> int:
	if not is_working():
		return 0
	var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
	return maxi(work_ends_unix - now, 0)


func clear_work() -> void:
	work_type = WorkType.NONE
	work_started_unix = 0
	work_ends_unix = 0
	work_ready = false


func get_work_name() -> String:
	return work_type_name(work_type)


static func work_type_name(value: WorkType) -> String:
	match value:
		WorkType.FISHING:
			return "낚시"
		WorkType.RAID:
			return "약탈"
		WorkType.BATTLE:
			return "전투"
		_:
			return "대기"


static func parse_work_type(value: String) -> WorkType:
	match value.strip_edges().to_upper():
		"FISHING", "FISH", "낚시":
			return WorkType.FISHING
		"RAID", "약탈":
			return WorkType.RAID
		"BATTLE", "전투":
			return WorkType.BATTLE
		_:
			return WorkType.NONE
