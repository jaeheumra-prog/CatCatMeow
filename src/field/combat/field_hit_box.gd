class_name FieldHitBox
extends Area2D

## Receives FieldDamageSource overlaps and forwards damage to a FieldHealth component.
signal damage_received(source: FieldDamageSource, applied_damage: int)

@export var team: StringName = &"neutral"
@export_node_path("FieldHealth") var health_path := NodePath("../FieldHealth")
@export var active := true:
	set(value):
		if active == value:
			return
		active = value
		if is_inside_tree():
			_apply_active_state()

var health: FieldHealth


func _ready() -> void:
	health = get_node_or_null(health_path) as FieldHealth
	if health == null:
		push_error("FieldHitBox '%s' could not find FieldHealth at '%s'." % [name, health_path])

	area_entered.connect(_on_area_entered)
	_apply_active_state()


func set_active(value: bool) -> void:
	active = value


func receive_damage(source: FieldDamageSource) -> int:
	if not active or health == null or not source.can_hit(self):
		return 0

	var applied_damage := health.take_damage(
		source.damage,
		source.get_damage_owner(),
		source.ignore_defense
	)
	source.confirm_hit(self, applied_damage)
	damage_received.emit(source, applied_damage)
	return applied_damage


func _on_area_entered(area: Area2D) -> void:
	var source := area as FieldDamageSource
	if source != null:
		receive_damage(source)


func _apply_active_state() -> void:
	monitoring = active
	monitorable = active
	for child in find_children("*", "CollisionShape2D"):
		(child as CollisionShape2D).set_deferred("disabled", not active)
	for child in find_children("*", "CollisionPolygon2D"):
		(child as CollisionPolygon2D).set_deferred("disabled", not active)
