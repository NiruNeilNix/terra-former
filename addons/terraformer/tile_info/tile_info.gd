@tool
@icon("tile_info.svg")
class_name TileInfo
extends Resource

@export var id: String = "":
	set(value):
		id = value
		resource_name = id.to_pascal_case()
@export_range(0, 1000, 1, "or_greater") var layer: int = 0
