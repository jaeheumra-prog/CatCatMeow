extends CanvasLayer

var _is_open := false
var _was_tree_paused := false
var _selected_id := ""
var _refresh_left := 0.0

@onready var overlay := $Overlay as Control
@onready var grid := %CatGrid as GridContainer
@onready var count_label := %CountLabel as Label
@onready var species_label := %SpeciesLabel as Label
@onready var economy_label := %EconomyLabel as Label
@onready var empty_label := %EmptyLabel as Label
@onready var detail_label := %DetailLabel as Label
@onready var feedback_label := %FeedbackLabel as Label
@onready var fishing_slot := %FishingSlot as MinionCatWorkSlot
@onready var raid_slot := %RaidSlot as MinionCatWorkSlot
@onready var battle_slot := %BattleSlot as MinionCatWorkSlot


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	MinionCats.roster_changed.connect(_rebuild)
	for slot in [fishing_slot, raid_slot, battle_slot]:
		slot.cat_dropped.connect(_on_cat_dropped)
		slot.claim_requested.connect(_on_claim_requested)
	overlay.hide()
	_rebuild()


func _process(delta: float) -> void:
	if not _is_open:
		return
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = 1.0
	var selected := MinionCats.get_by_id(_selected_id)
	if selected:
		_show_detail(selected)
	for child in grid.get_children():
		if child is MinionCatCard:
			child.refresh()
	_refresh_work_slots(MinionCats.get_all())
	_update_status_labels()


func _input(event: InputEvent) -> void:
	if DeveloperConsole.visible:
		return
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var is_roster_key := key_event.keycode == KEY_1 or key_event.physical_keycode == KEY_1
	if is_roster_key:
		get_viewport().set_input_as_handled()
		set_open(not _is_open)
	elif _is_open and key_event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		set_open(false)


func set_open(value: bool) -> void:
	if value == _is_open:
		return
	_is_open = value
	if _is_open:
		_was_tree_paused = get_tree().paused
		get_tree().paused = true
		_rebuild()
		overlay.show()
	else:
		overlay.hide()
		get_tree().paused = _was_tree_paused


func _rebuild() -> void:
	if not is_node_ready():
		return
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var cats: Array[MinionCatData] = MinionCats.get_all()
	count_label.text = "보유 고양이  %d" % cats.size()
	_update_status_labels()
	empty_label.visible = cats.is_empty()
	_refresh_work_slots(cats)
	if cats.is_empty():
		_selected_id = ""
		detail_label.text = "아직 영입한 고양이가 없습니다.\n적 고양이를 영입하면 이곳에 개체별로 저장됩니다."
		return
	for cat in cats:
		grid.add_child(_create_cat_card(cat))
	var selected := MinionCats.get_by_id(_selected_id)
	_show_detail(selected if selected else cats[0])


func _create_cat_card(cat: MinionCatData) -> MinionCatCard:
	var card := MinionCatCard.new()
	card.setup(cat)
	card.button_pressed = cat.unique_id == _selected_id
	card.pressed.connect(_show_detail.bind(cat))
	return card


func _show_detail(cat: MinionCatData) -> void:
	if cat == null:
		return
	_selected_id = cat.unique_id
	detail_label.text = (
		"[ %s ]\n\n종류  %s\n레벨  %d   EXP %d/%d\n체력  %d / %d\n호감도  %d / 100\n\n"
		+ "전투력  %d\n민첩  %d\n체력  %d\n친화력  %d\n손재주  %d\n\n작업  %s\n\n개체 ID\n%s"
		% [cat.display_name, cat.species_id, cat.level, cat.experience, cat.level * 30,
			cat.current_health, cat.max_health, cat.affection, cat.combat_power, cat.agility,
			cat.stamina, cat.friendliness, cat.dexterity, _work_state(cat), cat.unique_id]
	)
	for child in grid.get_children():
		if child is Button:
			child.button_pressed = String(child.get_meta("cat_id", "")) == cat.unique_id


func _update_status_labels() -> void:
	species_label.text = "도감  %d / %d" % [MinionCats.data.unlocked_species.size(), MinionCats.SPECIES.size()]
	economy_label.text = "참치캔 %d   고등어 %d   연어 %d   명성 %d" % [
		MinionCats.data.tuna_cans, MinionCats.data.mackerels,
		MinionCats.data.salmons, MinionCats.data.reputation]


func _refresh_work_slots(cats: Array[MinionCatData]) -> void:
	fishing_slot.refresh(cats, "FISHING" in MinionCats.data.unlocked_work)
	raid_slot.refresh(cats, "RAID" in MinionCats.data.unlocked_work)
	battle_slot.refresh(cats, "BATTLE" in MinionCats.data.unlocked_work)


func _on_cat_dropped(cat_id: String, work_type: MinionCatData.WorkType) -> void:
	var number := MinionCats.get_number_by_id(cat_id)
	var work_key: String = String(MinionCatData.WorkType.keys()[work_type])
	_show_result(MinionCats.start_work(number, work_key))


func _on_claim_requested(work_type: MinionCatData.WorkType) -> void:
	_show_result(MinionCats.claim_completed_by_type(work_type))


func _show_result(result: Dictionary) -> void:
	feedback_label.text = String(result.get("message", ""))
	feedback_label.add_theme_color_override(
		"font_color", Color("8fe3a3") if bool(result.get("ok", false)) else Color("f07b88"))


func _work_state(cat: MinionCatData) -> String:
	if cat.is_work_complete():
		return "%s 완료 - 수령 가능" % cat.get_work_name()
	if cat.is_working():
		return "%s 중 · %s" % [cat.get_work_name(), _format_seconds(cat.remaining_work_seconds())]
	return "대기"


func _format_seconds(seconds: int) -> String:
	if seconds < 60:
		return "%d초 남음" % seconds
	return "%d분 %02d초 남음" % [seconds / 60, seconds % 60]
