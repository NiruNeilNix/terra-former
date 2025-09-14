@tool
@icon("walls.svg")
class_name Walls
extends Modifier2D

@export var wall_tile: TileInfo
@export var applies_to: Filter


func _passes_walls_filter(grid: MapGrid, cell, layer:int, generator: TerraGenerator) -> bool:
	if not applies_to or applies_to.filter_type == Filter.FilterType.NONE:
		return grid.get_value(cell, layer) == generator.settings.tile
	else:
		return applies_to._passes_filter(grid, cell)


func apply(grid: MapGrid, generator: TerraGenerator):
	if not generator.get("settings") or not generator.settings.get("tile"):
		push_warning("Walls modifier not compatible with %s" % generator.name)
		return grid

	var _temp_grid: MapGrid = grid.clone()
	for layer in affected_layers:
		for cell in grid.get_cells(layer):
			if not _passes_filter(grid, cell) or not _passes_walls_filter(grid, cell, layer, generator):
				continue

			print("Found ground?")

			var above: Vector2i = cell + Vector2i.UP
			if not _passes_walls_filter(grid, above, layer, generator):
				print("Found top of ground.")
				_temp_grid.set_value(cell, wall_tile)

			#if grid.get_value(cell, layer) == generator.settings.tile:
				#var above: Vector2i = cell + Vector2i.UP
				#if grid.has_cell(above, layer) and grid.get_value(above, layer) != generator.settings.tile:
					#_temp_grid.set_value(cell, wall_tile)

	generator.grid = _temp_grid.clone()
	_temp_grid.unreference()
