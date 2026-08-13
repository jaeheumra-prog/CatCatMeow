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


extends MiniGamePiece

@export var left_limit: float=160.0
@export var right_limit: float=160.0 # 1760.0은 어디서 나온 숫자인겨

@onready var _gfx: GamepieceAnimation = $BbiyongLabGFX

func _ready() -> void:
	_gfx.set_direction(Directions.Points.SOUTH)
	_gfx.play("idle")
	
	
func _physics_process(delta: float) -> void:
	if not enabled:
		_gfx.play("idle")
		return
		
	var direction := Input.get_axis("ui_left", "ui_right") #이미 세팅?
	
	if is_zero_approx(direction):
		_gfx.play("idle")
		return
		
	position.x += direction * move_speed * delta
	position.x = clamp(position.x, left_limit, right_limit)

	if direction < 0.0:
		_gfx.set_direction(Directions.Points.WEST)
	else:
		_gfx.set_direction(Directions.Points.EAST)

	_gfx.play("run")
		
	
