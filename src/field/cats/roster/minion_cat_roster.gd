extends Node

signal roster_changed
signal cat_recruited(cat: MinionCatData)
signal work_completed(cat: MinionCatData)

const DEFAULT_SAVE_PATH := "user://minion_cat_roster.tres"
const DEFAULT_WORK_SECONDS := {
	MinionCatData.WorkType.FISHING: 20 * 60,
	MinionCatData.WorkType.RAID: 30 * 60,
	MinionCatData.WorkType.BATTLE: 45 * 60,
}
const SPECIES: Dictionary = {
	"basic_cat": {
		"name": "마을고양이", "description": "어떤 일도 무난하게 수행하는 균형형 고양이",
		"combat": 2, "agility": 2, "stamina": 2, "friendliness": 2, "dexterity": 2,
		"health": 6,
		"portrait": "res://assets/characters/bbiyong/bbiyong_lab_sheet.png",
		"portrait_region": Rect2(0, 0, 320, 330),
	},
	"scout_cat": {
		"name": "겁쟁이 고양이", "description": "민첩하고 친화력이 높은 정찰 특기 고양이",
		"combat": 1, "agility": 4, "stamina": 2, "friendliness": 4, "dexterity": 2,
		"health": 5,
		"portrait": "res://assets/characters/bbiyong/bbiyong_lab_sheet.png",
		"portrait_region": Rect2(320, 0, 320, 330),
	},
	"thief_cat": {
		"name": "도둑 고양이", "description": "약탈과 아이템 발견에 뛰어난 고양이",
		"combat": 2, "agility": 5, "stamina": 2, "friendliness": 1, "dexterity": 3,
		"health": 6,
		"portrait": "res://assets/characters/bbiyong/bbiyong_lab_sheet.png",
		"portrait_region": Rect2(640, 0, 320, 330),
	},
	"fisher_cat": {
		"name": "낚시 고양이", "description": "손재주가 좋아 희귀 생선을 잘 낚는 고양이",
		"combat": 1, "agility": 2, "stamina": 4, "friendliness": 3, "dexterity": 5,
		"health": 7,
		"portrait": "res://assets/characters/bbiyong/bbiyong_lab_sheet.png",
		"portrait_region": Rect2(960, 0, 320, 330),
	},
	"fighter_cat": {
		"name": "싸움꾼 고양이", "description": "전투력과 체력이 높은 전투 특기 고양이",
		"combat": 5, "agility": 2, "stamina": 4, "friendliness": 1, "dexterity": 1,
		"health": 10,
		"portrait": "res://assets/characters/bbiyong/bbiyong_lab_sheet.png",
		"portrait_region": Rect2(0, 330, 320, 330),
	},
}

var save_path := DEFAULT_SAVE_PATH
var data: MinionCatRosterData
var _completion_poll := 0.0


func _ready() -> void:
	_restore()
	set_process(true)


func _process(delta: float) -> void:
	_completion_poll -= delta
	if _completion_poll > 0.0:
		return
	_completion_poll = 0.5
	var changed := false
	for cat in data.cats:
		if cat.is_work_complete() and not cat.work_ready:
			cat.work_ready = true
			changed = true
			work_completed.emit(cat)
	if changed:
		_save()
		roster_changed.emit()


func register_from_enemy(enemy: EnemyCat) -> MinionCatData:
	if not is_instance_valid(enemy):
		return null
	var species_key := enemy.species_id if SPECIES.has(enemy.species_id) else "basic_cat"
	var cat := MinionCatData.new()
	cat.initialize_from_enemy(enemy, data.cats.size() + 1, SPECIES[species_key])
	cat.species_id = species_key
	data.cats.append(cat)
	unlock_species(species_key, false)
	_save_and_emit()
	cat_recruited.emit(cat)
	return cat


func add_debug_cat(species_key: String = "basic_cat") -> Dictionary:
	species_key = species_key.to_lower()
	if not SPECIES.has(species_key):
		return _result(false, "없는 고양이 종입니다: %s" % species_key)
	var cat := MinionCatData.new()
	cat.initialize_debug(species_key, data.cats.size() + 1, SPECIES[species_key])
	data.cats.append(cat)
	unlock_species(species_key, false)
	_save_and_emit()
	cat_recruited.emit(cat)
	return _result(true, "%s을(를) 보유 목록에 추가했습니다. (#%d)" % [cat.display_name, data.cats.size()])


func get_all() -> Array[MinionCatData]:
	return data.cats.duplicate()


func get_by_id(unique_id: String) -> MinionCatData:
	for cat in data.cats:
		if cat.unique_id == unique_id:
			return cat
	return null


func get_by_number(number: int) -> MinionCatData:
	if number < 1 or number > data.cats.size():
		return null
	return data.cats[number - 1]


func count() -> int:
	return data.cats.size()


func unlock_species(species_key: String, notify := true) -> Dictionary:
	species_key = species_key.to_lower()
	if not SPECIES.has(species_key):
		return _result(false, "없는 고양이 종입니다: %s" % species_key)
	if species_key in data.unlocked_species:
		return _result(true, "이미 해금된 종입니다: %s" % species_key)
	data.unlocked_species.append(species_key)
	if notify:
		_save_and_emit()
	return _result(true, "%s 종을 해금했습니다." % String(SPECIES[species_key].name))


func unlock_work(work_name: String) -> Dictionary:
	var work_type := MinionCatData.parse_work_type(work_name)
	if work_type == MinionCatData.WorkType.NONE:
		return _result(false, "작업은 FISHING, RAID, BATTLE 중 하나여야 합니다.")
	var key := _work_key(work_type)
	if key in data.unlocked_work:
		return _result(true, "이미 해금된 작업입니다: %s" % key)
	data.unlocked_work.append(key)
	_save_and_emit()
	return _result(true, "%s 작업을 해금했습니다." % MinionCatData.work_type_name(work_type))


func start_work(number: int, work_name: String, debug_seconds := -1) -> Dictionary:
	var cat := get_by_number(number)
	if cat == null:
		return _result(false, "고양이 번호를 확인하세요: %d" % number)
	if cat.is_working():
		return _result(false, "%s은(는) 이미 %s 중입니다." % [cat.display_name, cat.get_work_name()])
	var work_type := MinionCatData.parse_work_type(work_name)
	if work_type == MinionCatData.WorkType.NONE:
		return _result(false, "작업은 FISHING, RAID, BATTLE 중 하나여야 합니다.")
	var key := _work_key(work_type)
	if key not in data.unlocked_work:
		return _result(false, "%s 작업은 아직 잠겨 있습니다. CATWORKUNLOCK %s로 시험할 수 있습니다." % [MinionCatData.work_type_name(work_type), key])
	var base_seconds := int(DEFAULT_WORK_SECONDS[work_type])
	var duration := debug_seconds if debug_seconds > 0 else _apply_stamina_duration(base_seconds, cat.stamina)
	var now := int(Time.get_unix_time_from_system())
	cat.work_type = work_type
	cat.work_started_unix = now
	cat.work_ends_unix = now + duration
	cat.work_ready = false
	_save_and_emit()
	return _result(true, "%s: %s 시작 (%s)" % [cat.display_name, cat.get_work_name(), _format_duration(duration)])


func claim_work(number: int) -> Dictionary:
	var cat := get_by_number(number)
	if cat == null:
		return _result(false, "고양이 번호를 확인하세요: %d" % number)
	if not cat.is_working():
		return _result(false, "%s은(는) 수행 중인 작업이 없습니다." % cat.display_name)
	if not cat.is_work_complete():
		return _result(false, "아직 %s 남았습니다." % _format_duration(cat.remaining_work_seconds()))
	var message := _grant_work_reward(cat)
	cat.experience += 10
	while cat.experience >= cat.level * 30:
		cat.experience -= cat.level * 30
		cat.level += 1
	cat.clear_work()
	_save_and_emit()
	return _result(true, "%s 작업 완료: %s" % [cat.display_name, message])


func claim_all_completed() -> Dictionary:
	var messages: Array[String] = []
	for number in range(1, data.cats.size() + 1):
		var cat := get_by_number(number)
		if cat and cat.is_work_complete():
			var result := claim_work(number)
			if result.ok:
				messages.append(String(result.message))
	if messages.is_empty():
		return _result(false, "수령 가능한 완료 작업이 없습니다.")
	return _result(true, "\n".join(messages))


func give_item(number: int, item_name: String, stat_name: String = "") -> Dictionary:
	var cat := get_by_number(number)
	if cat == null:
		return _result(false, "고양이 번호를 확인하세요: %d" % number)
	var item := item_name.to_lower()
	if int(data.items.get(item, 0)) <= 0:
		return _result(false, "보유하지 않은 아이템입니다: %s" % item)
	match item:
		"catnip":
			var gain := 8 + cat.friendliness * 2
			cat.affection = mini(cat.affection + gain, 100)
			data.items[item] = int(data.items[item]) - 1
			_check_bond_reward(cat)
			_save_and_emit()
			return _result(true, "%s 호감도 +%d (%d/100)" % [cat.display_name, gain, cat.affection])
		"training_treat":
			if not _increase_stat(cat, stat_name):
				return _result(false, "스탯은 COMBAT, AGILITY, STAMINA, FRIENDLINESS, DEXTERITY 중 하나여야 합니다.")
			data.items[item] = int(data.items[item]) - 1
			_save_and_emit()
			return _result(true, "%s의 %s 스탯이 상승했습니다." % [cat.display_name, stat_name.to_upper()])
		_:
			return _result(false, "현재 사용할 수 없는 아이템입니다: %s" % item)


func debug_give_item(item_name: String, amount := 1) -> Dictionary:
	var item := item_name.to_lower()
	if item not in ["catnip", "training_treat", "bond_badge"]:
		return _result(false, "아이템은 CATNIP, TRAINING_TREAT, BOND_BADGE 중 하나여야 합니다.")
	amount = maxi(amount, 1)
	data.items[item] = int(data.items.get(item, 0)) + amount
	_save_and_emit()
	return _result(true, "%s %d개를 추가했습니다." % [item, amount])


func bind_runtime_minion(minion: MinionCat) -> void:
	var cat := get_by_id(minion.minion_id)
	if cat == null or minion.field_health == null:
		return
	cat.current_health = minion.field_health.health
	cat.max_health = minion.field_health.max_health
	var update := _on_runtime_health_changed.bind(cat.unique_id)
	if not minion.field_health.health_changed.is_connected(update):
		minion.field_health.health_changed.connect(update)
	_save_and_emit()


func get_roster_summary() -> String:
	if data.cats.is_empty():
		return "보유한 MinionCat이 없습니다. CATADD BASIC_CAT으로 시험할 수 있습니다."
	var lines: Array[String] = ["보유 고양이 %d마리" % data.cats.size()]
	for index in data.cats.size():
		var cat := data.cats[index]
		var state := "완료-수령대기" if cat.is_work_complete() else (
			"%s %s 남음" % [cat.get_work_name(), _format_duration(cat.remaining_work_seconds())]
			if cat.is_working() else "대기"
		)
		lines.append("#%d %s | %s | LV.%d | 호감도 %d | %s" % [index + 1, cat.display_name, cat.species_id, cat.level, cat.affection, state])
	return "\n".join(lines)


func get_cat_summary(number: int) -> String:
	var cat := get_by_number(number)
	if cat == null:
		return "고양이 번호를 확인하세요: %d" % number
	return (
		"#%d %s (%s)\nLV.%d EXP %d/%d | HP %d/%d | 호감도 %d/100\n"
		+ "전투 %d  민첩 %d  체력 %d  친화 %d  손재주 %d\n상태: %s\nID: %s"
	) % [number, cat.display_name, cat.species_id, cat.level, cat.experience, cat.level * 30,
		cat.current_health, cat.max_health, cat.affection, cat.combat_power, cat.agility,
		cat.stamina, cat.friendliness, cat.dexterity, _cat_state(cat), cat.unique_id]


func get_codex_summary() -> String:
	var lines: Array[String] = ["고양이 종 도감 %d/%d" % [data.unlocked_species.size(), SPECIES.size()]]
	for key in SPECIES:
		var species: Dictionary = SPECIES[key]
		var unlocked: bool = key in data.unlocked_species
		var owned := _count_species(key)
		lines.append("%s %s | %s | 보유 %d" % ["[해금]" if unlocked else "[잠김]", key, String(species.name) if unlocked else "???", owned])
	return "\n".join(lines)


func get_economy_summary() -> String:
	return "재화 | 참치캔 %d  고등어 %d  연어 %d  명성 %d\n아이템 | 캣닢 %d  훈련간식 %d  유대배지 %d\n작업 해금 | %s" % [
		data.tuna_cans, data.mackerels, data.salmons, data.reputation,
		int(data.items.get("catnip", 0)), int(data.items.get("training_treat", 0)),
		int(data.items.get("bond_badge", 0)), ", ".join(data.unlocked_work)]


func _grant_work_reward(cat: MinionCatData) -> String:
	match cat.work_type:
		MinionCatData.WorkType.FISHING:
			var tuna := 2 + cat.dexterity + cat.level
			var mackerel := cat.dexterity / 2
			var salmon := 1 if cat.dexterity + cat.level >= 7 else 0
			data.tuna_cans += tuna
			data.mackerels += mackerel
			data.salmons += salmon
			return "참치캔 %d, 고등어 %d, 연어 %d" % [tuna, mackerel, salmon]
		MinionCatData.WorkType.RAID:
			var catnip := 1 + cat.agility / 3
			data.items["catnip"] = int(data.items.get("catnip", 0)) + catnip
			if cat.agility >= 4:
				data.items["training_treat"] = int(data.items.get("training_treat", 0)) + 1
			return "캣닢 %d%s" % [catnip, ", 훈련간식 1" if cat.agility >= 4 else ""]
		MinionCatData.WorkType.BATTLE:
			var fame := 3 + cat.combat_power * 2 + cat.level
			data.reputation += fame
			data.tuna_cans += cat.combat_power
			return "명성 %d, 참치캔 %d" % [fame, cat.combat_power]
		_:
			return "보상 없음"


func _increase_stat(cat: MinionCatData, stat_name: String) -> bool:
	match stat_name.strip_edges().to_upper():
		"COMBAT", "전투":
			cat.combat_power += 1
		"AGILITY", "민첩":
			cat.agility += 1
		"STAMINA", "체력":
			cat.stamina += 1
		"FRIENDLINESS", "친화":
			cat.friendliness += 1
		"DEXTERITY", "손재주":
			cat.dexterity += 1
		_:
			return false
	return true


func _check_bond_reward(cat: MinionCatData) -> void:
	if cat.affection < 100 or cat.bond_reward_claimed:
		return
	cat.bond_reward_claimed = true
	data.items["bond_badge"] = int(data.items.get("bond_badge", 0)) + 1


func _apply_stamina_duration(base_seconds: int, stamina: int) -> int:
	var reduction := minf(float(maxi(stamina - 1, 0)) * 0.035, 0.25)
	return maxi(int(round(base_seconds * (1.0 - reduction))), 1)


func _count_species(species_key: String) -> int:
	var result := 0
	for cat in data.cats:
		if cat.species_id == species_key:
			result += 1
	return result


func _cat_state(cat: MinionCatData) -> String:
	if cat.is_work_complete():
		return "%s 완료 - 보상 수령 가능" % cat.get_work_name()
	if cat.is_working():
		return "%s 중 - %s 남음" % [cat.get_work_name(), _format_duration(cat.remaining_work_seconds())]
	return "대기"


func _work_key(work_type: MinionCatData.WorkType) -> String:
	return MinionCatData.WorkType.keys()[work_type]


func _format_duration(seconds: int) -> String:
	seconds = maxi(seconds, 0)
	if seconds < 60:
		return "%d초" % seconds
	return "%d분 %02d초" % [seconds / 60, seconds % 60]


func _on_runtime_health_changed(current: int, _previous: int, maximum: int, unique_id: String) -> void:
	var cat := get_by_id(unique_id)
	if cat == null:
		return
	cat.current_health = current
	cat.max_health = maximum
	_save_and_emit()


func _restore() -> void:
	if FileAccess.file_exists(save_path):
		var loaded := ResourceLoader.load(save_path, "", ResourceLoader.CACHE_MODE_IGNORE) as MinionCatRosterData
		if loaded:
			data = loaded
			_migrate_data()
			return
	data = MinionCatRosterData.new()
	_migrate_data()
	_save()


func _migrate_data() -> void:
	if "basic_cat" not in data.unlocked_species:
		data.unlocked_species.append("basic_cat")
	if "FISHING" not in data.unlocked_work:
		data.unlocked_work.append("FISHING")
	for item in ["catnip", "training_treat", "bond_badge"]:
		if not data.items.has(item):
			data.items[item] = 0
	for cat in data.cats:
		if not SPECIES.has(cat.species_id):
			cat.species_id = "basic_cat"
		if cat.is_work_complete():
			cat.work_ready = true


func _save_and_emit() -> void:
	_save()
	roster_changed.emit()


func _save() -> void:
	var error := ResourceSaver.save(data, save_path)
	if error != OK:
		push_error("MinionCatRoster 저장 실패: %d" % error)


func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}
