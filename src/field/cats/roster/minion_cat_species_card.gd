class_name MinionCatSpeciesCard
extends Button

const SpeciesDatabase = preload("res://src/field/cats/roster/minion_cat_species_database.gd")

var species_id := ""
var _definition: Dictionary = {}
var _unlocked := false
var _owned_count := 0

var _portrait: TextureRect
var _name_label: Label
var _state_label: Label
var _description_label: Label


func setup(definition: Dictionary, unlocked: bool, owned_count: int) -> void:
	_definition = definition.duplicate(true)
	species_id = String(_definition.get("id", ""))
	_unlocked = unlocked
	_owned_count = owned_count
	set_meta("species_id", species_id)
	if is_node_ready():
		refresh()


func _ready() -> void:
	_build_card()
	refresh()


func refresh() -> void:
	if not is_node_ready() or _definition.is_empty():
		return
	_portrait.texture = _load_portrait()
	_portrait.modulate = Color.WHITE if _unlocked else Color(0.015, 0.018, 0.025, 1.0)
	_name_label.text = String(_definition.get("name", species_id)) if _unlocked else "?????"
	_state_label.text = "보유 %d마리 · %s형" % [
		_owned_count,
		SpeciesDatabase.get_role_name(String(_definition.get("role_id", "balanced"))),
	] if _unlocked else "미해금"
	_description_label.text = String(_definition.get("description", "")) if _unlocked else "아직 발견하지 못한 종입니다."
	tooltip_text = _description_label.text


func _build_card() -> void:
	custom_minimum_size = Vector2(200, 235)
	toggle_mode = true
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("191e2c")
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color("58637a")
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	add_theme_stylebox_override("normal", normal)
	var selected := normal.duplicate() as StyleBoxFlat
	selected.bg_color = Color("293652")
	selected.border_color = Color("8bc7ff")
	add_theme_stylebox_override("hover", selected)
	add_theme_stylebox_override("pressed", selected)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 9)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(170, 145)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_portrait)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 20)
	content.add_child(_name_label)

	_state_label = Label.new()
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.add_theme_font_size_override("font_size", 14)
	_state_label.add_theme_color_override("font_color", Color("93c8f0"))
	content.add_child(_state_label)

	_description_label = Label.new()
	_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description_label.add_theme_font_size_override("font_size", 13)
	_description_label.add_theme_color_override("font_color", Color("9aa5b9"))
	_description_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(_description_label)


func _load_portrait() -> Texture2D:
	var texture := load(String(_definition.get("portrait", ""))) as Texture2D
	if texture == null:
		return null
	var region: Rect2 = _definition.get("portrait_region", Rect2())
	if region.size == Vector2.ZERO:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas
