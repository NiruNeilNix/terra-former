@tool
class_name TerraGenerator2D
extends TerraGenerator

@export var tile_size: Vector2i = Vector2i(16, 16)
@export var next_pass: TerraGenerator2D

var tile_pool:Array[TilemapTileInfo]

func _ready() -> void:
	grid = MapGrid2D.new()
	super()

func get_grid() -> MapGrid2D:
	if is_instance_valid(grid):
		return grid
	grid = MapGrid2D.new()
	return grid

func global_to_map(pos: Vector2) -> Vector2i:
	return (pos / Vector2(tile_size)).floor()

func map_to_global(map_position: Vector2i) -> Vector2:
	return Vector2(map_position * tile_size)
