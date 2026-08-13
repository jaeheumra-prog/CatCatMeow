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


class_name MiniGamePiece
extends Area2D

@export var move_speed: float = 300.0

var enabled: bool = true

func set_enabled(value: bool)->void:
	enabled = value
