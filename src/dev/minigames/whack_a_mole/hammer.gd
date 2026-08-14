class_name MoleHammer
extends Sprite2D

@export_category("이미지 슬롯")
@export var hammer_image: Texture2D
@export var image_scale := Vector2.ONE

@export_category("동작")
@export var show_duration: float = 0.12

var show_left: float = 0.0

@onready var _fallback: Polygon2D = $Fallback


func _ready() -> void:
	texture = hammer_image
	scale = image_scale
	_fallback.visible = hammer_image == null
	visible = false


func _process(delta: float) -> void:
	global_position = get_global_mouse_position()

	if show_left > 0.0:
		show_left -= delta
		visible = true
	else:
		visible = false


func swing() -> void:
	show_left = show_duration
	visible = true
