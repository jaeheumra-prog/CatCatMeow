class_name EnemyCat
extends Gamepiece


signal recruit_requested(enemy)


var is_recruited: bool = false

@onready var field_health := $FieldHealth as FieldHealth


func recruit() -> void:
	if is_recruited:
		return

	is_recruited = true

	print("ENEMY CAT RECRUIT REQUEST : ", name)

	recruit_requested.emit(self)
