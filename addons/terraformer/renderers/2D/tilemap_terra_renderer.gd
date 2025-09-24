@tool
class_name TilemapTerraRenderer
extends TerraRenderer2D

enum NodeType {
	TILEMAP_LAYERS, ## Use [TileMapLayer]s, with an array of them determining which one is which.
	TILEMAP ## Use a single [TileMap] node (not recommended by Godot).
}

@export var node_type: NodeType = NodeType.TILEMAP_LAYERS :
	set(value):
		node_type = value
		notify_property_list_changed()
@export var tile_map_layers: Array[TileMapLayer] :
	set(value):
		tile_map_layers = value
		update_configuration_warnings()
@export var tile_map: TileMap :
	set(value):
		tile_map = value
		update_configuration_warnings()
@export var clear_tile_map_on_draw: bool = true
@export var erase_empty_tiles: bool = true
@export var terrain_gap_fix: bool = false


func _ready() -> void:
	super()

	if !generator:
		push_error("TilemapTerraRenderer needs a TerraGenerator node assigned in its exports.")
		return

	if _is_single_tilemap():
		if not is_instance_valid(tile_map):
			push_error("TilemapTerraRenderer needs TileMap to work.")
			return
		if _tile_size_mismatch(Vector2i(Vector2(tile_map.tile_set.tile_size) * tile_map.scale)):
			push_warning("TileMap's tile size doesn't match with generator's tile size, can cause generation issues.\n\t\t\t\t\t\tThe generator's tile size has been set to the TileMap's tile size.")
			generator.tile_size = Vector2(tile_map.tile_set.tile_size) * tile_map.scale
	elif _is_layers_mode():
		if tile_map_layers.is_empty():
			push_error("TilemapTerraRenderer needs at least one TileMapLayer to work.")
			return
		var layer: TileMapLayer = _first_layer()
		if _tile_size_mismatch(Vector2i(Vector2(layer.tile_set.tile_size) * layer.scale)):
			push_warning("The TileMapLayer's tile size doesn't match with generator's tile size, can cause generation issues.\n\t\t\t\t\t\tThe generator's tile size has been set to the layer's tile size. (Only layer 0 checked)")
			generator.tile_size = Vector2(layer.tile_set.tile_size) * layer.scale

func _draw_area(area: Rect2i) -> void:
	var terrain_groups_by_info: Dictionary

	if _is_single_tilemap() and not is_instance_valid(tile_map):
		push_error("Invalid TileMap, can't draw area.")
		return
	elif _is_layers_mode() and tile_map_layers.is_empty():
		push_error("No TileMapLayers assigned, can't draw area.")
		return

	for x in range(area.position.x, area.end.x + 1):
		for y in range(area.position.y, area.end.y + 1):
			var cell_position := Vector2i(x, y)

			if erase_empty_tiles and _is_position_empty_in_all_layers(cell_position):
				for layer_index in range(_get_tilemap_layers_count()):
					_erase_tilemap_cell(layer_index, cell_position)
				continue

			for layer_index in range(generator.grid.get_layer_count()):
				var tile_info = generator.grid.get_value(cell_position, layer_index)
				if not (tile_info is TilemapTileInfo):
					continue

				match tile_info.type:
					TilemapTileInfo.Type.SINGLE_CELL:
						_set_tile(cell_position, tile_info)
					TilemapTileInfo.Type.TERRAIN:
						if not terrain_groups_by_info.has(tile_info):
							terrain_groups_by_info[tile_info] = [cell_position]
						else:
							terrain_groups_by_info[tile_info].append(cell_position)
					TilemapTileInfo.Type.PATTERN:
						_set_pattern(cell_position, tile_info)

	for tile_info in terrain_groups_by_info:
		_set_terrain(terrain_groups_by_info[tile_info], tile_info)

	(func(): area_rendered.emit(area)).call_deferred()

func _draw() -> void:
	if clear_tile_map_on_draw:
		if _is_single_tilemap():
			tile_map.clear()
		else:
			for layer in tile_map_layers:
				layer.clear()
	super._draw()

func _set_tile(cell: Vector2i, tile_info: TilemapTileInfo) -> void:
	_adapter_set_cell(
		tile_info.tilemap_layer,
		cell,
		tile_info.source_id,
		tile_info.atlas_coord,
		tile_info.alternative_tile
	)

func _set_terrain(cells: Array, tile_info: TilemapTileInfo) -> void:
	_adapter_set_terrain(
		tile_info.tilemap_layer,
		cells,
		tile_info.terrain_set,
		tile_info.terrain
	)

func _set_pattern(cell:Vector2i, tile_info: TilemapTileInfo):
	var layer:TileMapLayer = tile_map_layers[tile_info.tilemap_layer]
	if (layer.tile_set.get_patterns_count() > tile_info.pattern_idx):
		var pattern:TileMapPattern = layer.tile_set.get_pattern(tile_info.pattern_idx)
		var position:Vector2i = cell + tile_info.pattern_offset
		for tile in pattern.get_used_cells():
			var pos = position + tile
			layer.set_pattern(pos, pattern)

func _get_tilemap_layers_count() -> int:
	return _adapter_layers_count()

func _erase_tilemap_cell(layer: int, cell: Vector2i) -> void:
	_adapter_erase_cell(layer, cell)

## Adapter helpers to unify TileMap and TileMapLayer operations
func _adapter_layers_count() -> int:
	if _is_single_tilemap():
		return tile_map.get_layers_count()
	return tile_map_layers.size()

func _adapter_set_cell(layer_index: int, cell: Vector2i, source_id: int, atlas_coord: Vector2i, alternative_tile: int) -> void:
	if _is_single_tilemap():
		tile_map.call_thread_safe("set_cell",
			layer_index,
			cell,
			source_id,
			atlas_coord,
			alternative_tile
		)
	else:
		tile_map_layers[layer_index].call_thread_safe("set_cell",
			cell,
			source_id,
			atlas_coord,
			alternative_tile
		)

func _adapter_set_terrain(layer_index: int, cells: Array, terrain_set: int, terrain: int) -> void:
	if _is_single_tilemap():
		tile_map.set_cells_terrain_connect.call_deferred(
				layer_index,
				cells,
				terrain_set,
				terrain,
				!terrain_gap_fix
			)
	else:
		tile_map_layers[layer_index].set_cells_terrain_connect.call_deferred(
				cells,
				terrain_set,
				terrain,
				!terrain_gap_fix
			)

func _adapter_erase_cell(layer_index: int, cell: Vector2i) -> void:
	if _is_single_tilemap():
		tile_map.call_thread_safe("erase_cell", layer_index, cell)
	else:
		tile_map_layers[layer_index].call_thread_safe("erase_cell", cell)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	warnings.append_array(super._get_configuration_warnings())

	if _is_single_tilemap() and not is_instance_valid(tile_map):
		warnings.append("Needs a TileMap to work.")
	elif _is_layers_mode() and tile_map_layers.is_empty():
		warnings.append("Needs at least one TileMapLayer to work.")

	return warnings

func _validate_property(property: Dictionary) -> void:
	if property.name == "tile_map" and _is_layers_mode():
		property.usage = PROPERTY_USAGE_NONE
	elif property.name == "tile_map_layers" and _is_single_tilemap():
		property.usage = PROPERTY_USAGE_NONE

func _is_single_tilemap() -> bool:
	return node_type == NodeType.TILEMAP

func _is_layers_mode() -> bool:
	return node_type == NodeType.TILEMAP_LAYERS

func _first_layer() -> TileMapLayer:
	return tile_map_layers.front()

func _tile_size_mismatch(candidate: Vector2i) -> bool:
	return candidate != generator.tile_size

func _is_position_empty_in_all_layers(cell_position: Vector2i) -> bool:
	for layer_index in range(generator.grid.get_layer_count()):
		if generator.grid.has_cell(cell_position, layer_index):
			return false
	return true
