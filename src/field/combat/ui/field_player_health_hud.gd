class_name FieldPlayerHealthHUD
extends CanvasLayer

@onready var bar := %HealthBar as FieldHealthBar
@onready var value_label := %ValueLabel as Label
var _bound_health: FieldHealth


func _ready() -> void:
	Player.gamepiece_changed.connect(_queue_refresh_player)
	_queue_refresh_player()


func _queue_refresh_player() -> void:
	# Field가 새 플레이어에게 전투 컴포넌트를 붙인 직후에 바인딩한다.
	_refresh_player.call_deferred()


func _refresh_player() -> void:
	if _bound_health and _bound_health.health_changed.is_connected(_update_label):
		_bound_health.health_changed.disconnect(_update_label)
	var health: FieldHealth = null
	if Player.gamepiece:
		health = Player.gamepiece.get_node_or_null("FieldHealth") as FieldHealth
	bar.bind_health(health)
	_bound_health = health
	if health:
		_update_label(health.health, health.health, health.max_health)
		if not health.health_changed.is_connected(_update_label):
			health.health_changed.connect(_update_label)
	else:
		value_label.text = "-- / --"


func _update_label(current: int, _previous: int, maximum: int) -> void:
	value_label.text = "%d / %d" % [current, maximum]
