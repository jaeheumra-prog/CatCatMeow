class_name MinionFollowController
extends GamepieceController


enum State {
	FOLLOW,
	COMBAT,
	RETURN
}


@export_range(1, 12, 1)
var detection_cells := 6

@export_range(1, 5, 1)
var follow_distance_cells := 2

@export_range(0.05, 2.0, 0.05)
var think_interval := 0.15

@export_range(0.1, 5.0, 0.05)
var attack_cooldown := 0.8

@export_range(1, 20, 1)
var attack_damage := 1


var state: State = State.FOLLOW

var _target_enemy: EnemyCat

var _think_left := 0.0
var _attack_left := 0.0


func _ready() -> void:
	super._ready()

	set_process(true)


func _process(delta: float) -> void:
	_attack_left = maxf(
		_attack_left - delta,
		0.0
	)

	_think_left -= delta

	if _think_left > 0.0:
		return

	_think_left = think_interval

	if not is_active:
		return

	if _gamepiece == null:
		return

	if _gamepiece.is_moving():
		return


	var enemy := _find_nearest_enemy()

	if enemy != null:
		_target_enemy = enemy
		state = State.COMBAT

		_run_combat()

		return


	if _target_enemy != null:
		state = State.RETURN

	_target_enemy = null

	_run_follow()


func _find_nearest_enemy() -> EnemyCat:
	var source_cell := GamepieceRegistry.get_cell(
		_gamepiece
	)

	if source_cell == Gameboard.INVALID_CELL:
		return null


	var nearest: EnemyCat = null
	var nearest_distance := detection_cells + 1


	for gamepiece in GamepieceRegistry.get_gamepieces():

		if not gamepiece is EnemyCat:
			continue

		var enemy := gamepiece as EnemyCat

		# 약화된 적은 더 이상 공격하지 않는다
		if not enemy.is_combat_target():
			continue

		var enemy_cell := GamepieceRegistry.get_cell(
			enemy
		)

		if enemy_cell == Gameboard.INVALID_CELL:
			continue


		var distance := _cell_distance(
			source_cell,
			enemy_cell
		)

		if (
			distance <= detection_cells
			and distance < nearest_distance
		):
			nearest = enemy
			nearest_distance = distance


	return nearest


func _run_combat() -> void:
	if not is_instance_valid(_target_enemy):
		return

	if not _target_enemy.is_combat_target():
		state = State.RETURN
		_target_enemy = null
		return


	var source_cell := GamepieceRegistry.get_cell(
		_gamepiece
	)

	var enemy_cell := GamepieceRegistry.get_cell(
		_target_enemy
	)


	if (
		source_cell == Gameboard.INVALID_CELL
		or enemy_cell == Gameboard.INVALID_CELL
	):
		return


	# 바로 옆이면 공격
	if enemy_cell in Gameboard.get_adjacent_cells(
		source_cell
	):
		_gamepiece.direction = (
			Directions.vector_to_direction(
				Vector2(
					enemy_cell - source_cell
				)
			)
		)

		if is_zero_approx(_attack_left):

			_target_enemy.receive_field_damage(
				attack_damage,
				_gamepiece
			)

			_attack_left = attack_cooldown

		return


	# 적 바로 옆 칸까지 이동
	var path := (
		Gameboard.pathfinder
		.get_path_cells_to_adjacent_cell(
			source_cell,
			enemy_cell
		)
	)

	if not path.is_empty():
		move_path = path


func _run_follow() -> void:
	var player := Player.gamepiece

	if player == null:
		return

	if not is_instance_valid(player):
		return


	var source_cell := GamepieceRegistry.get_cell(
		_gamepiece
	)

	var player_cell := GamepieceRegistry.get_cell(
		player
	)


	if (
		source_cell == Gameboard.INVALID_CELL
		or player_cell == Gameboard.INVALID_CELL
	):
		return


	var distance := _cell_distance(
		source_cell,
		player_cell
	)


	if distance <= follow_distance_cells:

		if state == State.RETURN:
			state = State.FOLLOW

		return


	var path := (
		Gameboard.pathfinder
		.get_path_cells_to_adjacent_cell(
			source_cell,
			player_cell
		)
	)

	if not path.is_empty():
		move_path = path


func _cell_distance(
	a: Vector2i,
	b: Vector2i
) -> int:

	var delta := (a - b).abs()

	return delta.x + delta.y
