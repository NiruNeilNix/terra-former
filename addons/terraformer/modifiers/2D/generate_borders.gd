@tool
@icon("generate_borders.svg")
class_name GenerateBorder
extends Modifier2D

enum Mode {
	ADJACENT_ONLY,  ## Only generates borders at the top, bottom, right and left of tiles.
	INCLUDE_DIAGONALS,  ## Also generates diagonally to tiles.
}

@export var border_tile_info: TileInfo
@export var mode: Mode = Mode.ADJACENT_ONLY
@export var remove_single_walls := false

var _temp_grid: MapGrid

func apply(grid: MapGrid, generator: TerraGenerator) -> void:
	_temp_grid = grid.clone()

	_generate_border_walls(grid)

	generator.grid = _temp_grid.clone()
	_temp_grid.unreference()

func _generate_border_walls(grid: MapGrid) -> void:
	for layer in affected_layers:
		for cell in grid.get_cells(layer):
			var neighbors = MapGrid2D.SURROUNDING.duplicate()

			if mode != Mode.INCLUDE_DIAGONALS:
				for i in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1)]:
					neighbors.erase(i)

			for neighbor in neighbors:
				if not grid.has_cell(cell + neighbor, layer):
					_temp_grid.set_value(cell + neighbor, border_tile_info)
