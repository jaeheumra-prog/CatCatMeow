extends CanvasLayer

const SpeciesDatabase = preload("res://src/field/cats/roster/minion_cat_species_database.gd")
const SpeciesCard = preload("res://src/field/cats/roster/minion_cat_species_card.gd")

enum ViewMode { SPECIES_CATALOG, OWNED_CATS, CAT_DETAIL }

var _is_open := false
var _was_tree_paused := false
var _view_mode := ViewMode.SPECIES_CATALOG
var _selected_stage := 1
var _selected_species_id := ""
var _selected_id := ""
var _refresh_left := 0.0

@onready var overlay := $Overlay as Control
@onready var back_button := %BackButton as Button
@onready var breadcrumb_label := %BreadcrumbLabel as Label
@onready var stage_tabs := %StageTabs as HBoxContainer
@onready var species_area := $Overlay/Panel/Margin/MainVBox/Body/SpeciesArea as Control
@onready var species_header := %SpeciesHeader as Label
@onready var species_grid := %SpeciesGrid as GridContainer
@onready var roster_area := $Overlay/Panel/Margin/MainVBox/Body/RosterArea as Control
@onready var roster_title := %RosterTitle as Label
@onready var grid := %CatGrid as GridContainer
@onready var detail_panel := $Overlay/Panel/Margin/MainVBox/Body/DetailPanel as Control
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
	back_button.pressed.connect(_navigate_back)
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
	if selected and _view_mode == ViewMode.CAT_DETAIL:
		_show_detail(selected)
	for child in grid.get_children():
		if child is MinionCatCard:
			child.refresh()
	_refresh_work_slots(MinionCats.get_all())
	_update_status_labels()


func _input(event: InputEvent) -> void:
	if DeveloperConsole.visible or not event is InputEventKey:
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
		if _view_mode == ViewMode.SPECIES_CATALOG:
			set_open(false)
		else:
			_navigate_back()
	elif _is_open and key_event.keycode == KEY_ENTER and _view_mode == ViewMode.CAT_DETAIL:
		get_viewport().set_input_as_handled()
		_toggle_selected_active()


func set_open(value: bool) -> void:
	if value == _is_open:
		return
	_is_open = value
	if _is_open:
		_was_tree_paused = get_tree().paused
		get_tree().paused = true
		_view_mode = ViewMode.SPECIES_CATALOG
		_selected_id = ""
		_rebuild()
		overlay.show()
	else:
		overlay.hide()
		get_tree().paused = _was_tree_paused


func _rebuild() -> void:
	if not is_node_ready():
		return
	var cats: Array[MinionCatData] = MinionCats.get_all()
	count_label.text = "보유 고양이  %d" % cats.size()
	_update_status_labels()
	_refresh_work_slots(cats)
	_ensure_selected_species()
	_rebuild_stage_tabs()
	_rebuild_species_cards()
	_refresh_current_view()


func _refresh_current_view() -> void:
	match _view_mode:
		ViewMode.OWNED_CATS:
			if MinionCats.is_species_unlocked(_selected_species_id):
				_open_species(_selected_species_id, false)
			else:
				_show_catalog_view()
		ViewMode.CAT_DETAIL:
			var selected := MinionCats.get_by_id(_selected_id)
			if selected:
				_show_detail(selected)
			elif MinionCats.is_species_unlocked(_selected_species_id):
				_open_species(_selected_species_id, false)
			else:
				_show_catalog_view()
		_:
			_show_catalog_view()


func _ensure_selected_species() -> void:
	var stage_species := MinionCats.get_species_ids_for_stage(_selected_stage)
	if _selected_species_id not in stage_species:
		_selected_species_id = stage_species[0] if not stage_species.is_empty() else ""


func _rebuild_stage_tabs() -> void:
	_clear_children(stage_tabs)
	for stage_id in range(1, 9):
		var definition := SpeciesDatabase.get_stage_definition(stage_id)
		var species_ids := MinionCats.get_species_ids_for_stage(stage_id)
		var button := Button.new()
		button.toggle_mode = true
		button.button_pressed = stage_id == _selected_stage
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 58)
		button.add_theme_font_size_override("font_size", 17)
		button.text = "%s  %d/%d" % [
			String(definition.get("label", stage_id)),
			MinionCats.get_unlocked_count_for_stage(stage_id),
			species_ids.size(),
		]
		button.tooltip_text = String(definition.get("region", ""))
		button.pressed.connect(_select_stage.bind(stage_id))
		stage_tabs.add_child(button)


func _select_stage(stage_id: int) -> void:
	_selected_stage = stage_id
	_selected_species_id = ""
	_selected_id = ""
	_view_mode = ViewMode.SPECIES_CATALOG
	_rebuild()


func _rebuild_species_cards() -> void:
	_clear_children(species_grid)
	var stage := SpeciesDatabase.get_stage_definition(_selected_stage)
	species_header.text = "%s · %s" % [stage.get("label", ""), stage.get("region", "")]
	for species_id in MinionCats.get_species_ids_for_stage(_selected_stage):
		var definition := MinionCats.get_species_definition(species_id)
		var card := SpeciesCard.new()
		card.setup(
			definition,
			MinionCats.is_species_unlocked(species_id),
			MinionCats.get_cats_by_species(species_id).size()
		)
		card.button_pressed = species_id == _selected_species_id
		card.pressed.connect(_open_species.bind(species_id))
		species_grid.add_child(card)


func _open_species(species_id: String, navigate := true) -> void:
	if species_id.is_empty():
		return
	_selected_species_id = species_id
	for child in species_grid.get_children():
		if child is Button:
			child.button_pressed = String(child.get_meta("species_id", "")) == species_id
	if not MinionCats.is_species_unlocked(species_id):
		_show_result({
			"ok": false,
			"message": "아직 발견하지 못한 종입니다. 실제로 부하 영입해야 열립니다.",
		})
		_show_catalog_view()
		return
	if navigate:
		_selected_id = ""
	_view_mode = ViewMode.OWNED_CATS
	_clear_children(grid)
	var definition := MinionCats.get_species_definition(species_id)
	var cats := MinionCats.get_cats_by_species(species_id)
	roster_title.text = "%s · 보유 %d마리" % [definition.get("name", species_id), cats.size()]
	empty_label.visible = cats.is_empty()
	empty_label.text = "해금되었지만 현재 보유한 개체가 없습니다."
	if cats.is_empty():
		_selected_id = ""
	else:
		for cat in cats:
			grid.add_child(_create_cat_card(cat))
	_apply_view_visibility()


func _create_cat_card(cat: MinionCatData) -> MinionCatCard:
	var card := MinionCatCard.new()
	card.setup(cat)
	card.button_pressed = cat.unique_id == _selected_id
	card.pressed.connect(_show_detail.bind(cat))
	return card


func _show_detail(cat: MinionCatData) -> void:
	if cat == null:
		return
	_selected_species_id = cat.species_id
	_selected_id = cat.unique_id
	_view_mode = ViewMode.CAT_DETAIL
	var definition := MinionCats.get_species_definition(cat.species_id)
	var detail_format := (
		"[ %s ]\n\n종  %s\n역할  %s\n출신  STAGE %d\n"
		+ "레벨  %d   EXP %d/%d\n체력  %d / %d\n호감도  %d / 100\n\n"
		+ "전투력  %d\n민첩  %d\n체력  %d\n친화력  %d\n손재주  %d\n\n작업  %s\n\n개체 ID\n%s"
	)
	detail_label.text = detail_format % [
		cat.display_name,
		definition.get("name", cat.species_id),
		SpeciesDatabase.get_role_name(cat.role_id),
		cat.stage_id,
		cat.level,
		cat.experience,
		cat.level * 30,
		cat.current_health,
		cat.max_health,
		cat.affection,
		cat.combat_power,
		cat.agility,
		cat.stamina,
		cat.friendliness,
		cat.dexterity,
		_work_state(cat),
		cat.unique_id,
	]
	for child in grid.get_children():
		if child is Button:
			child.button_pressed = String(child.get_meta("cat_id", "")) == cat.unique_id
	var deployment_state := "출전 중" if MinionCats.is_active_minion(cat) else "대기"
	detail_label.text += "\n\n필드 상태: %s\n[ENTER] 출전 지정 / 해제" % deployment_state
	_apply_view_visibility()


func _show_catalog_view() -> void:
	_view_mode = ViewMode.SPECIES_CATALOG
	_selected_id = ""
	_apply_view_visibility()


func _navigate_back() -> void:
	match _view_mode:
		ViewMode.CAT_DETAIL:
			_open_species(_selected_species_id, false)
		ViewMode.OWNED_CATS:
			_show_catalog_view()
		_:
			return


func _apply_view_visibility() -> void:
	var showing_catalog := _view_mode == ViewMode.SPECIES_CATALOG
	var showing_roster := _view_mode == ViewMode.OWNED_CATS
	stage_tabs.visible = showing_catalog
	species_area.visible = showing_catalog
	roster_area.visible = showing_roster
	detail_panel.visible = _view_mode == ViewMode.CAT_DETAIL
	back_button.visible = not showing_catalog
	var definition := MinionCats.get_species_definition(_selected_species_id)
	var species_name := String(definition.get("name", _selected_species_id))
	match _view_mode:
		ViewMode.OWNED_CATS:
			breadcrumb_label.text = "품종 도감  >  %s  >  보유 개체" % species_name
		ViewMode.CAT_DETAIL:
			var selected := MinionCats.get_by_id(_selected_id)
			breadcrumb_label.text = "품종 도감  >  %s  >  %s  >  개체 상세" % [
				species_name,
				selected.display_name if selected else "고양이",
			]
		_:
			breadcrumb_label.text = "품종 도감"


func _toggle_selected_active() -> void:
	if _selected_id.is_empty():
		_show_result({"ok": false, "message": "출전시킬 고양이 개체를 먼저 선택하세요."})
		return
	var result := MinionCats.set_active_minion_by_id(_selected_id)
	_show_result(result)
	var selected := MinionCats.get_by_id(_selected_id)
	if selected:
		_show_detail(selected)


func _update_status_labels() -> void:
	species_label.text = "도감  %d / %d" % [
		MinionCats.data.unlocked_species.size(),
		SpeciesDatabase.SPECIES_ORDER.size(),
	]
	economy_label.text = "참치캔 %d   고등어 %d   연어 %d   명성 %d" % [
		MinionCats.data.tuna_cans,
		MinionCats.data.mackerels,
		MinionCats.data.salmons,
		MinionCats.data.reputation,
	]


func _refresh_work_slots(cats: Array[MinionCatData]) -> void:
	fishing_slot.refresh(cats, "FISHING" in MinionCats.data.unlocked_work)
	raid_slot.refresh(cats, "RAID" in MinionCats.data.unlocked_work)
	battle_slot.refresh(cats, "BATTLE" in MinionCats.data.unlocked_work)


func _on_cat_dropped(cat_id: String, work_type: MinionCatData.WorkType) -> void:
	var number := MinionCats.get_number_by_id(cat_id)
	var work_key := String(MinionCatData.WorkType.keys()[work_type])
	_show_result(MinionCats.start_work(number, work_key))


func _on_claim_requested(work_type: MinionCatData.WorkType) -> void:
	_show_result(MinionCats.claim_completed_by_type(work_type))


func _show_result(result: Dictionary) -> void:
	feedback_label.text = String(result.get("message", ""))
	feedback_label.add_theme_color_override(
		"font_color",
		Color("8fe3a3") if bool(result.get("ok", false)) else Color("f07b88")
	)


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


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
