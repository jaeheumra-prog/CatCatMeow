class_name FieldWorldHealthBar
extends Node2D

@export var offset := Vector2(0, -14)
@onready var bar := $HealthBar as FieldHealthBar

var _gamepiece: Gamepiece


func _ready() -> void:
	top_level = true
	_gamepiece = get_parent() as Gamepiece
	if _gamepiece == null:
		push_error("FieldWorldHealthBar must be a direct child of Gamepiece.")
		return
	bar.bind_health(_gamepiece.get_node_or_null("FieldHealth") as FieldHealth)
	set_process(true)


func _process(_delta: float) -> void:
	if _gamepiece and _gamepiece.follower:
		global_position = _gamepiece.follower.global_position + offset

