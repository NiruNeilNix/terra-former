class_name MapGrid
extends Resource

var _cells_by_layer: Dictionary

func set_value(pos, value: Variant, layer: int = -1) -> void:
	if value is RandomTileInfo:
		set_value(pos, value.get_random(), layer)
		return

	if layer < 0:
		if value is TileInfo:
			layer = value.layer
		else:
			layer = 0

	if not has_layer(layer):
		add_layer(layer)

	_cells_by_layer[layer][pos] = value

func get_value(pos, layer: int) -> Variant:
	if not has_layer(layer):
		return null
	return _cells_by_layer[layer].get(pos)

func get_values(layer: int) -> Array[Variant]:
	if not has_layer(layer):
		push_error("Index layer = %s is out of bounds (get_layer_count() = %s)" % [layer, get_layer_count()])
		return []
	return _cells_by_layer[layer].values()


func set_grid(grid: Dictionary) -> void:
	_cells_by_layer = grid

func set_grid_serialized(bytes: PackedByteArray) -> void:
	var grid = bytes_to_var(bytes)
	if not (grid is Dictionary):
		push_error("Attempted to deserialize invalid grid")
		return

	for layer in grid:
		for tile in grid[layer]:
			var object = grid[layer][tile]
			if object is EncodedObjectAsID:
				grid[layer][tile] = instance_from_id(object.get_object_id())
	_cells_by_layer = grid

func get_grid() -> Dictionary:
	return _cells_by_layer

func get_cells(layer: int) -> Array:
	if not has_layer(layer):
		push_error("Index layer = %s is out of bounds (get_layer_count() = %s)" % [layer, get_layer_count()])
		return []
	return _cells_by_layer[layer].keys()

func has_cell(pos, layer: int) -> bool:
	if not has_layer(layer):
		return false
	return _cells_by_layer.has(layer) and _cells_by_layer[layer].has(pos)

func erase(pos, layer: int) -> void:
	if has_cell(pos, layer):
		_cells_by_layer[layer].erase(pos)

func clear() -> void:
	_cells_by_layer.clear()

func erase_invalid() -> void:
	for layer: int in range(get_layer_count()):
		for cell in get_cells(layer):
			if get_value(cell, layer) == null:
				erase(cell, layer)

func has_layer(idx: int) -> bool:
	return _cells_by_layer.has(idx)

func get_layer_count() -> int:
	return _cells_by_layer.size()

func add_layer(idx: int) -> void:
	if _cells_by_layer.has(idx):
		return
		
	_cells_by_layer[idx] = {}

func get_area() -> Variant:
	return null

func clone() -> MapGrid:
	var instance = get_script().new()

	instance.set_grid(_cells_by_layer.duplicate(true))

	return instance
