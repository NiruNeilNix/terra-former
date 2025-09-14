@tool
@icon("advanced_modifier.svg")
class_name AdvancedModifier2D
extends ChunkAwareModifier2D

@export var conditions: Array[AdvancedModifierCondition]
@export var tile: TileInfo

func _apply_area(area: Rect2i, grid: MapGrid, _generator: TerraGenerator) -> void:
	if conditions.is_empty():
		return

	_configure_seeds(_generator)

	for x in range(area.position.x, area.end.x + 1):
		for y in range(area.position.y, area.end.y + 1):
			var cell_position := Vector2i(x, y)
			if not _passes_filter(grid, cell_position):
				continue

			if _should_place_tile(grid, cell_position):
				grid.set_value(cell_position, tile)

func _configure_seeds(generator: TerraGenerator) -> void:
	seed(generator.seed + salt)

	for condition in conditions:
		if condition.get("noise") != null and condition.get("noise") is FastNoiseLite:
			condition.noise.seed = generator.seed + salt

func _should_place_tile(grid: MapGrid, cell_position: Vector2i) -> bool:
	for condition in conditions:
		var condition_met: bool = condition.is_condition_met(grid, cell_position)
		if condition.mode == AdvancedModifierCondition.Mode.INVERT:
			condition_met = not condition_met

		if not condition_met:
			return false
	return true
