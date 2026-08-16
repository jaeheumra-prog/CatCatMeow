class_name FieldHealthBar
extends ProgressBar

@export var animate_duration := 0.28
@export var color_full := Color("62e66f")
@export var color_normal := Color("8de83f")
@export var color_low := Color("ffb84d")
@export var color_critical := Color("ff4d5a")
@export_range(0.0, 1.0, 0.01) var low_threshold := 0.35
@export_range(0.0, 1.0, 0.01) var critical_threshold := 0.15

var health: FieldHealth
var _value_tween: Tween
var _fill_style := StyleBoxFlat.new()


func _ready() -> void:
	show_percentage = false
	_fill_style.corner_radius_top_left = 3
	_fill_style.corner_radius_top_right = 3
	_fill_style.corner_radius_bottom_left = 3
	_fill_style.corner_radius_bottom_right = 3
	add_theme_stylebox_override("fill", _fill_style)
	_update_color(value)


func bind_health(value_to_bind: FieldHealth) -> void:
	if health == value_to_bind:
		return
	if health != null and health.health_changed.is_connected(_on_health_changed):
		health.health_changed.disconnect(_on_health_changed)
	health = value_to_bind
	if health == null:
		hide()
		return
	max_value = health.max_health
	value = health.health
	_update_color(value)
	health.health_changed.connect(_on_health_changed)
	show()


func _on_health_changed(current: int, _previous: int, maximum: int) -> void:
	max_value = maximum
	if _value_tween:
		_value_tween.kill()
	_value_tween = create_tween()
	_value_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_value_tween.tween_property(self, "value", float(current), animate_duration)
	_update_color(current)


func _update_color(current: float) -> void:
	var ratio := current / maxf(max_value, 1.0)
	if ratio >= 0.999:
		_fill_style.bg_color = color_full
	elif ratio <= critical_threshold:
		_fill_style.bg_color = color_critical
	elif ratio <= low_threshold:
		_fill_style.bg_color = color_low
	else:
		_fill_style.bg_color = color_normal

