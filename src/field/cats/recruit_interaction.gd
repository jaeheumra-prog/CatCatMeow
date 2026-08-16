extends Interaction


func _execute() -> void:
	var enemy = get_parent()

	if enemy == null:
		push_error("RecruitInteraction: 부모가 없습니다.")
		return

	if not enemy.has_method("recruit"):
		push_error(
			"RecruitInteraction: 부모에 recruit() 함수가 없습니다. parent=%s"
			% enemy.name
		)
		return

	print("RECRUIT INTERACTION : ", enemy.name)

	enemy.recruit()
