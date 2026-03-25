extends Node3D
class_name UIGridItem

@export var grid_pos: Vector2i = Vector2i.ZERO
@export var grid_span: Vector2i = Vector2i.ONE

func get_grid_pos() -> Vector2i:
	return grid_pos

func get_grid_span() -> Vector2i:
	return grid_span
