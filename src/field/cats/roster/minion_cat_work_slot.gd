class_name MinionCatWorkSlot
extends PanelContainer

signal cat_dropped(cat_id: String, work_type: MinionCatData.WorkType)
signal claim_requested(work_type: MinionCatData.WorkType)

@export var work_type: MinionCatData.WorkType = MinionCatData.WorkType.FISHING

var _unlocked := false

@onready var title_label := $Margin/VBox/Title as Label
@onready var lock_label := $Margin/VBox/LockLabel as Label
@onready var drop_hint := $Margin/VBox/DropHint as Label
@onready var assigned_list := $Margin/VBox/AssignedList as VBoxContainer
@onready var claim_button := $Margin/VBox/ClaimButton as Button


func _ready() -> void:
	claim_button.pressed.connect(func(): claim_requested.emit(work_type))
	_update_style()


func refresh(cats: Array[MinionCatData], unlocked: bool) -> void:
	_unlocked = unlocked
	title_label.text = MinionCatData.work_type_name(work_type)
	lock_label.visible = not _unlocked
	drop_hint.visible = _unlocked
	drop_hint.text = "대기 중인 고양이 카드를 여기에 놓기"
	for child in assigned_list.get_children():
		assigned_list.remove_child(child)
		child.queue_free()
	var completed_count := 0
	var assigned_count := 0
	for cat in cats:
		if cat.work_type != work_type:
			continue
		assigned_count += 1
		if cat.is_work_complete():
			completed_count += 1
		var label := Label.new()
		label.text = "%s  ·  %s" % [cat.display_name, _cat_work_text(cat)]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_color_override("font_color", Color("8fe3a3") if cat.is_work_complete() else Color("d9d4c7"))
		assigned_list.add_child(label)
	if assigned_count == 0 and _unlocked:
		var empty := Label.new()
		empty.text = "배치된 고양이 없음"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 15)
		empty.add_theme_color_override("font_color", Color("7d879a"))
		assigned_list.add_child(empty)
	claim_button.visible = _unlocked
	claim_button.disabled = completed_count == 0
	claim_button.text = "완료 보상 받기 (%d)" % completed_count
	_update_style()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not _unlocked or not (data is Dictionary):
		return false
	if String(data.get("kind", "")) != "minion_cat":
		return false
	var cat := MinionCats.get_by_id(String(data.get("cat_id", "")))
	return cat != null and not cat.is_working()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(Vector2.ZERO, data):
		return
	cat_dropped.emit(String(data.cat_id), work_type)


func _update_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("171c2a") if _unlocked else Color("15161c")
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color("6496c8") if _unlocked else Color("44454d")
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", style)


func _cat_work_text(cat: MinionCatData) -> String:
	if cat.is_work_complete():
		return "완료"
	var seconds := cat.remaining_work_seconds()
	if seconds < 60:
		return "%d초" % seconds
	return "%d분 %02d초" % [seconds / 60, seconds % 60]
