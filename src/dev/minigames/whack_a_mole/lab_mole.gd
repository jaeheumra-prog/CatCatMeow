extends MolePiece

@export_category("이미지 슬롯")
@export var mole_image: Texture2D
@export var hit_image: Texture2D
@export var hit_effect_image: Texture2D
@export var mole_image_scale := Vector2.ONE
@export var hit_effect_scale := Vector2.ONE

@export_category("피격 이펙트")
@export var hit_effect_duration: float = 0.15

@onready var _mole_sprite: Sprite2D = $MoleImage
@onready var _mole_fallback: Polygon2D = $MoleFallback
@onready var _hit_effect_sprite: Sprite2D = $HitEffectImage
@onready var _hit_effect_fallback: Polygon2D = $HitEffectFallback

var _hit_effect_left: float = 0.0


func _ready() -> void:
	_mole_sprite.scale = mole_image_scale
	_hit_effect_sprite.scale = hit_effect_scale
	_show_mole_visual(mole_image)
	_hide_hit_effect()


func _process(delta: float) -> void:
	super._process(delta)

	if _hit_effect_left <= 0.0:
		return

	_hit_effect_left -= delta
	if _hit_effect_left <= 0.0:
		_hide_hit_effect()


func register_hit() -> void:
	var was_hittable: bool = state == &"rising" or state == &"up"
	super.register_hit()
	if not was_hittable:
		return

	_show_mole_visual(hit_image)
	_show_hit_effect()


func _show_mole_visual(image: Texture2D) -> void:
	_mole_sprite.texture = image
	_mole_sprite.visible = image != null
	_mole_fallback.visible = image == null


func _show_hit_effect() -> void:
	_hit_effect_left = hit_effect_duration
	_hit_effect_sprite.texture = hit_effect_image
	_hit_effect_sprite.visible = hit_effect_image != null
	_hit_effect_fallback.visible = hit_effect_image == null


func _hide_hit_effect() -> void:
	_hit_effect_sprite.hide()
	_hit_effect_fallback.hide()
