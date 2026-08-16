class_name FieldHealth
extends Node

## Lightweight health component for real-time field actors.
signal health_changed(current_health: int, previous_health: int, maximum_health: int)
signal damage_taken(amount: int, source: Node)
signal health_restored(amount: int)
signal health_depleted(source: Node)

@export_range(1, 999999, 1) var max_health := 9:
	set(value):
		max_health = maxi(value, 1)
		if _initialized:
			set_health(mini(health, max_health))

@export_range(0, 999999, 1) var defense := 0
@export var start_at_full_health := true

var health := 0
var _initialized := false


func _ready() -> void:
	if not _initialized:
		health = max_health if start_at_full_health else 0
		_initialized = true


func take_damage(amount: int, source: Node = null, ignore_defense := false) -> int:
	if amount <= 0 or health <= 0:
		return 0

	var final_amount := amount
	if not ignore_defense:
		final_amount = maxi(amount - defense, 0)
	if final_amount == 0:
		return 0

	var previous_health := health
	health = maxi(health - final_amount, 0)
	var applied_damage := previous_health - health

	health_changed.emit(health, previous_health, max_health)
	damage_taken.emit(applied_damage, source)
	if health == 0:
		health_depleted.emit(source)

	return applied_damage


func heal(amount: int) -> int:
	if amount <= 0 or health <= 0:
		return 0

	var previous_health := health
	health = mini(health + amount, max_health)
	var restored_health := health - previous_health
	if restored_health == 0:
		return 0

	health_changed.emit(health, previous_health, max_health)
	health_restored.emit(restored_health)
	return restored_health


func set_health(value: int) -> void:
	var previous_health := health
	health = clampi(value, 0, max_health)
	_initialized = true
	if health != previous_health:
		health_changed.emit(health, previous_health, max_health)


func reset_health() -> void:
	set_health(max_health)


func is_depleted() -> bool:
	return health <= 0
