extends SceneTree

var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)

	var target := Node2D.new()
	stage.add_child(target)

	var health := FieldHealth.new()
	health.name = "FieldHealth"
	health.max_health = 10
	target.add_child(health)

	var hit_box := FieldHitBox.new()
	hit_box.team = &"player"
	hit_box.collision_layer = 64
	hit_box.collision_mask = 128
	var hit_shape := CollisionShape2D.new()
	var hit_circle := CircleShape2D.new()
	hit_circle.radius = 8.0
	hit_shape.shape = hit_circle
	hit_box.add_child(hit_shape)
	target.add_child(hit_box)

	var source := FieldDamageSource.new()
	source.damage = 4
	source.team = &"enemy"
	source.collision_layer = 128
	source.collision_mask = 64
	var source_shape := CollisionShape2D.new()
	var source_circle := CircleShape2D.new()
	source_circle.radius = 8.0
	source_shape.shape = source_circle
	source.add_child(source_shape)
	stage.add_child(source)
	source.set_active(true)

	await physics_frame
	await physics_frame
	_check(health.health == 6, "overlap should deal exactly 4 damage")

	_check(hit_box.receive_damage(source) == 0, "one activation must not hit twice")
	_check(health.health == 6, "duplicate hit changed health")

	source.set_active(false)
	source.set_active(true)
	_check(hit_box.receive_damage(source) == 4, "reactivation should permit a new hit")
	_check(health.health == 2, "second activation did not apply damage")

	_check(health.heal(99) == 8, "healing should stop at maximum health")
	_check(health.health == 10, "healing exceeded or missed maximum health")

	var friendly_source := FieldDamageSource.new()
	friendly_source.damage = 5
	friendly_source.team = &"player"
	stage.add_child(friendly_source)
	friendly_source.set_active(true)
	_check(hit_box.receive_damage(friendly_source) == 0, "same-team damage should be ignored")
	_check(health.health == 10, "friendly fire changed health")

	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("FIELD COMBAT SMOKE TEST: %s" % message)
	_failed = true
