extends Node

var _failed := false


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_check(InputMap.has_action("attack"), "attack input action is missing")

	var properties := GameboardProperties.new()
	properties.extents = Rect2i(0, 0, 4, 4)
	properties.cell_size = Vector2i(16, 16)
	Gameboard.properties = properties

	var stage := Node2D.new()
	get_tree().root.add_child(stage)

	var player_scene := load("res://src/field/gamepieces/gamepiece.tscn") as PackedScene
	var player := player_scene.instantiate() as Gamepiece
	player.name = "ComboTestPlayer"
	player.position = Gameboard.cell_to_pixel(Vector2i(1, 1))
	stage.add_child(player)

	var combo_scene := load("res://src/field/combat/field_combo_attack.tscn") as PackedScene
	var combo := combo_scene.instantiate() as FieldComboAttack
	player.add_child(combo)

	var target := Node2D.new()
	target.position = player.position + Vector2.DOWN * 16.0
	stage.add_child(target)

	var health := FieldHealth.new()
	health.name = "FieldHealth"
	health.max_health = 10
	target.add_child(health)

	var hit_box := FieldHitBox.new()
	hit_box.team = &"enemy"
	hit_box.collision_layer = 64
	hit_box.collision_mask = 128
	var hit_shape := CollisionShape2D.new()
	var hit_circle := CircleShape2D.new()
	hit_circle.radius = 8.0
	hit_shape.shape = hit_circle
	hit_box.add_child(hit_shape)
	target.add_child(hit_box)

	_check(combo.request_attack(), "first attack did not start")
	await get_tree().create_timer(0.12).timeout
	_check(combo.request_attack(), "second attack was not queued")

	await get_tree().create_timer(0.34).timeout
	_check(combo.get_combo_step() == 1, "combo did not advance to step 2")
	_check(combo.request_attack(), "third attack was not queued")

	await get_tree().create_timer(0.75).timeout
	_check(not combo.is_attacking(), "combo did not finish")
	_check(health.health == 5, "1 + 1 + 3 combo damage was not applied exactly once")

	print("FIELD COMBO SMOKE TEST PASSED" if not _failed else "FIELD COMBO SMOKE TEST FAILED")
	get_tree().quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("FIELD COMBO SMOKE TEST: %s" % message)
	_failed = true
