@tool
@icon("fill.svg")
class_name Fill
extends Modifier2D

@export var tile: TileInfo
@export_group("Expand", "expand_")
@export var expand_left := 1
@export var expand_top := 1
@export var expand_right := 1
@export var expand_bottom := 1

func apply(grid: MapGrid, _generator: TerraGenerator) -> void:
	var rect: Rect2i
	for layer in affected_layers:
		for cell in grid.get_cells(layer):
			if not rect:
				rect = Rect2i(cell, Vector2i.ONE)
			rect = rect.expand(cell)

		rect = rect.grow_individual(expand_left, expand_top, expand_right, expand_bottom)

		for x in range(rect.position.x, rect.end.x + 1):
			for y in range(rect.position.y, rect.end.y + 1):
				var cell: Vector2i = Vector2i(x, y)
				if grid.has_cell(cell, layer):
					continue

				grid.set_value(cell, tile)
