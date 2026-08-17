class_name MinionCatCard
extends Button

var cat_data: MinionCatData

var _portrait: TextureRect
var _name_label: Label
var _species_label: Label
var _stats_label: Label
var _state_label: Label


func _ready() -> void:
	_build_card()
	refresh()


func setup(value: MinionCatData) -> void:
	cat_data = value
	set_meta("cat_id", value.unique_id if value else "")
	if is_node_ready():
		refresh()


func refresh() -> void:
	if not is_node_ready() or cat_data == null:
		return
	_portrait.texture = _load_portrait(cat_data)
	_portrait.modulate = cat_data.appearance_tint
	_name_label.text = cat_data.display_name
	_species_label.text = "%s · LV.%d · 호감도 %d" % [cat_data.species_id, cat_data.level, cat_data.affection]
	_stats_label.text = "전투 %d  민첩 %d  체력 %d\n친화 %d  손재주 %d  HP %d/%d" % [
		cat_data.combat_power, cat_data.agility, cat_data.stamina,
		cat_data.friendliness, cat_data.dexterity, cat_data.current_health, cat_data.max_health]
	_state_label.text = _work_state(cat_data)
	_state_label.add_theme_color_override(
		"font_color", Color("f5c96a") if cat_data.is_working() else Color("aeb9cc"))
	modulate.a = 0.72 if cat_data.is_working() else 1.0
	tooltip_text = "개체 ID: %s\n외형 변형: %d" % [cat_data.unique_id, cat_data.appearance_variant]


func _get_drag_data(_at_position: Vector2) -> Variant:
	if cat_data == null or cat_data.is_working():
		return null
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(210, 68)
	var label := Label.new()
	label.text = "%s\n%s" % [cat_data.display_name, cat_data.species_id]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_child(label)
	set_drag_preview(preview)
	return make_drag_payload()


func make_drag_payload() -> Dictionary:
	if cat_data == null:
		return {}
	return {
		"kind": "minion_cat",
		"cat_id": cat_data.unique_id,
		"species_id": cat_data.species_id,
		"appearance_variant": cat_data.appearance_variant,
	}


func _build_card() -> void:
	custom_minimum_size = Vector2(260, 355)
	toggle_mode = true
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("202536")
	normal.border_width_left = 3
	normal.border_width_top = 3
	normal.border_width_right = 3
	normal.border_width_bottom = 3
	normal.border_color = Color("6f7892")
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	add_theme_stylebox_override("normal", normal)
	var selected := normal.duplicate() as StyleBoxFlat
	selected.bg_color = Color("303b58")
	selected.border_color = Color("91c8ff")
	add_theme_stylebox_override("hover", selected)
	add_theme_stylebox_override("pressed", selected)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 5)
	margin.add_child(content)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(210, 190)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_portrait)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 24)
	content.add_child(_name_label)
	_species_label = Label.new()
	_species_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_species_label.add_theme_font_size_override("font_size", 16)
	_species_label.add_theme_color_override("font_color", Color("9bc7ee"))
	content.add_child(_species_label)
	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 17)
	content.add_child(_stats_label)
	_state_label = Label.new()
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.add_theme_font_size_override("font_size", 15)
	_state_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(_state_label)


func _load_portrait(cat: MinionCatData) -> Texture2D:
	var texture := load(cat.portrait_path) as Texture2D
	if texture == null:
		return null
	if cat.portrait_region.size == Vector2.ZERO:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = cat.portrait_region
	return atlas


func _work_state(cat: MinionCatData) -> String:
	if cat.is_work_complete():
		return "%s 완료 · 보상 수령 가능" % cat.get_work_name()
	if cat.is_working():
		return "%s 중 · %s" % [cat.get_work_name(), _format_seconds(cat.remaining_work_seconds())]
	return "대기 · 드래그하여 작업 배치"


func _format_seconds(seconds: int) -> String:
	if seconds < 60:
		return "%d초 남음" % seconds
	return "%d분 %02d초 남음" % [seconds / 60, seconds % 60]
