class_name FieldDamageSource
extends Area2D

## Damage-dealing area activated by an attack, projectile, trap, or hazard.
signal hit_confirmed(hit_box: FieldHitBox, applied_damage: int)

@export_range(0, 999999, 1) var damage := 2
@export var team: StringName = &"neutral"
@export var ignore_defense := false
@export var one_hit_per_activation := true
@export var active := false:
	set(value):
		if active == value:
			return
		active = value
		if active:
			_hit_targets.clear()
		if is_inside_tree():
			_apply_active_state()

var source_actor: Node
var _hit_targets: Dictionary[int, bool] = {}


func _ready() -> void:
	_apply_active_state()


func set_active(value: bool) -> void:
	active = value


func can_hit(hit_box: FieldHitBox) -> bool:
	if not active or hit_box == null:
		return false
	if team != &"neutral" and hit_box.team == team:
		return false
	return not one_hit_per_activation or not _hit_targets.has(hit_box.get_instance_id())


func confirm_hit(hit_box: FieldHitBox, applied_damage: int) -> void:
	if one_hit_per_activation:
		_hit_targets[hit_box.get_instance_id()] = true
	hit_confirmed.emit(hit_box, applied_damage)


func get_damage_owner() -> Node:
	return source_actor if is_instance_valid(source_actor) else self


func _apply_active_state() -> void:
	monitoring = active
	monitorable = active
	for child in find_children("*", "CollisionShape2D"):
		(child as CollisionShape2D).set_deferred("disabled", not active)
	for child in find_children("*", "CollisionPolygon2D"):
		(child as CollisionPolygon2D).set_deferred("disabled", not active)
