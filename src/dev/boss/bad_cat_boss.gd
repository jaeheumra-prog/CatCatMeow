class_name BadCatBoss
extends Node2D

signal defeated
signal player_hit(damage: int)

@export var move_speed := 34.0
@export var contact_damage := 1
@export var attack_distance := 30.0
@export var attack_cooldown := 0.85
@export var visual_scale := Vector2(0.045, 0.045)

var target: Gamepiece
var arena_bounds := Rect2(32, 32, 416, 206)
var active := false
var _cooldown_left := 0.0

@onready var sprite := $Sprite as Sprite2D
@onready var health := $FieldHealth as FieldHealth
@onready var damage_source := $ContactDamage as FieldDamageSource


func _ready() -> void:
	damage_source.damage = contact_damage
	damage_source.source_actor = self
	damage_source.hit_confirmed.connect(
		func(_hit_box: FieldHitBox, damage: int): player_hit.emit(damage)
	)
	health.health_depleted.connect(_on_health_depleted)
	damage_source.set_active(false)
	sprite.scale = Vector2.ZERO
	set_process(false)


func start_battle(player: Gamepiece) -> void:
	target = player
	show()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", visual_scale, 0.65)
	await tween.finished
	active = true
	set_process(true)


func _process(delta: float) -> void:
	if not active or target == null:
		return
	var target_position := target.follower.global_position if target.follower else target.global_position
	var to_target := target_position - global_position
	if to_target.length() > attack_distance:
		global_position += to_target.normalized() * move_speed * delta
		global_position = Vector2(
			clampf(global_position.x, arena_bounds.position.x, arena_bounds.end.x),
			clampf(global_position.y, arena_bounds.position.y, arena_bounds.end.y)
		)

	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if to_target.length() <= attack_distance and is_zero_approx(_cooldown_left):
		_attack()


func _attack() -> void:
	_cooldown_left = attack_cooldown
	damage_source.set_active(true)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", visual_scale * 1.12, 0.08)
	tween.tween_property(sprite, "scale", visual_scale, 0.12)
	await get_tree().create_timer(0.14).timeout
	damage_source.set_active(false)


func _on_health_depleted(_source: Node) -> void:
	if not active:
		return
	active = false
	set_process(false)
	damage_source.set_active(false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.55).set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.45)
	await tween.finished
	hide()
	defeated.emit()

