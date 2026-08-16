class_name RunnerObstaclePiece
extends Area2D

signal exited_screen(obstacle: RunnerObstaclePiece)

@export var speed_multiplier := 1.0
@export var scroll_speed := 360.0
@export var despawn_y := 1180.0
@export var obstacle_texture: Texture2D

@onready var sprite := $Sprite2D as Sprite2D


func _ready() -> void:
	if obstacle_texture:
		sprite.texture = obstacle_texture
	queue_redraw()


func _process(delta: float) -> void:
	position.y += scroll_speed * speed_multiplier * delta
	if position.y > despawn_y:
		exited_screen.emit(self)
		queue_free()


func get_collision_rect() -> Rect2:
	var shape_node := $CollisionShape2D as CollisionShape2D
	var rectangle := shape_node.shape as RectangleShape2D
	if rectangle == null:
		return Rect2(global_position, Vector2.ZERO)
	var size := rectangle.size * global_scale.abs()
	return Rect2(shape_node.global_position - size * 0.5, size)


func _draw() -> void:
	if sprite and sprite.texture:
		return
	# 돌 이미지가 지정되지 않았을 때 사용하는 기본 바위 모양입니다.
	var points := PackedVector2Array([
		Vector2(-48, 12), Vector2(-38, -25), Vector2(-12, -39),
		Vector2(25, -34), Vector2(48, -8), Vector2(40, 27),
		Vector2(9, 39), Vector2(-29, 34),
	])
	draw_colored_polygon(points, Color("72503a"))
	draw_polyline(points + PackedVector2Array([points[0]]), Color("2d2430"), 6.0, true)
	draw_circle(Vector2(-14, -13), 8.0, Color("9a6b49"))
	draw_circle(Vector2(19, 13), 6.0, Color("50382f"))
