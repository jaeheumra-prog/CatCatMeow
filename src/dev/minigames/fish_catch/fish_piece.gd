#extends Node
#
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

class_name FishPiece
extends MiniGamePiece

@export var fall_speed: float = 220.0 #속도를 바꿔 여기를 바꿔 가릿?

func update_piece(delta: float) -> void:
	if not enabled:
		return
		
	position.y +- fall_speed * delta
