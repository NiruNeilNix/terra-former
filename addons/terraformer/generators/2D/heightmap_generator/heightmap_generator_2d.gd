@tool
@icon("heightmap_generator_2d.svg")
class_name HeightmapGenerator2D
extends ChunkAwareGenerator2D

@export var settings: HeightmapGenerator2DSettings


func generate(starting_grid: MapGrid = null) -> void:
	if not _has_valid_settings():
		return

	_configure_noise_seed()

	run_generation(func():
		_set_grid()
	, starting_grid, settings.modifiers)

	if _has_next_pass():
		next_pass.generate(grid)


func generate_chunk(chunk_position: Vector2i, starting_grid: MapGrid = null) -> void:
	if not _can_generate_chunk():
		return

	_assign_chunk_starting_grid(chunk_position, starting_grid)

	_set_chunk_grid(chunk_position)
	_apply_modifiers_chunk(settings.modifiers, chunk_position)

	generated_chunks.append(chunk_position)

	if _has_chunk_aware_next_pass():
		next_pass.generate_chunk(chunk_position, grid)
		return

	_emit_chunk_signals(chunk_position)


func _set_grid() -> void:
	var max_height: int = _calculate_max_height()
	var area := _create_heightmap_area(max_height)
	_set_grid_area(area)


func _set_chunk_grid(chunk_position: Vector2i) -> void:
	_set_grid_area(Rect2i(chunk_position * chunk_size, chunk_size))


func _set_grid_area(area: Rect2i) -> void:
	for x in range(area.position.x, area.end.x):
		if not _is_x_position_valid(x):
			continue

		var height = _calculate_height_at_x(x)
		_place_tiles_in_height_column(x, height, area)


func _has_valid_settings() -> bool:
	if not settings:
		push_error("%s doesn't have a settings resource" % name)
		return false
	return true


func _can_generate_chunk() -> bool:
	if Engine.is_editor_hint() and not editor_preview:
		push_warning("%s: Editor Preview is not enabled so nothing happened!" % name)
		return false
	if not settings:
		push_error("%s doesn't have a settings resource" % name)
		return false
	return true


func _configure_noise_seed() -> void:
	settings.noise.seed = seed


func _assign_chunk_starting_grid(chunk_position: Vector2i, starting_grid: MapGrid) -> void:
	if starting_grid == null:
		erase_chunk(chunk_position)
		return
	grid = starting_grid


func _has_next_pass() -> bool:
	return is_instance_valid(next_pass)


func _has_chunk_aware_next_pass() -> bool:
	if not is_instance_valid(next_pass):
		return false
	if not next_pass is ChunkAwareGenerator2D:
		push_error("next_pass generator is not a ChunkAwareGenerator2D")
		return false
	return true


func _emit_chunk_signals(chunk_position: Vector2i) -> void:
	(func(): chunk_updated.emit(chunk_position)).call_deferred()
	(func(): chunk_generation_finished.emit(chunk_position)).call_deferred()


func _calculate_max_height() -> int:
	var max_height: int = 0
	for x in range(settings.world_length):
		max_height = maxi(
			floor(settings.noise.get_noise_1d(x) * settings.height_intensity + settings.height_offset), max_height
		) + 1
	return max_height


func _create_heightmap_area(max_height: int) -> Rect2i:
	return Rect2i(
		Vector2i(0, -max_height),
		Vector2i(settings.world_length, max_height - settings.min_height)
	)


func _is_x_position_valid(x: int) -> bool:
	if settings.infinite:
		return true
	return x >= 0 and x <= settings.world_length


func _calculate_height_at_x(x: int) -> int:
	return floor(settings.noise.get_noise_1d(x) * settings.height_intensity + settings.height_offset)


func _place_tiles_in_height_column(x: int, height: int, area: Rect2i) -> void:
	for y in range(area.position.y, area.end.y):
		if _should_place_tile_at_height(y, height):
			grid.set_valuexy(x, y, settings.tile)
		elif _should_place_air_at_height(y, height):
			grid.set_valuexy(x, y, null)


func _should_place_tile_at_height(y: int, height: int) -> bool:
	return y >= -height and y <= -settings.min_height


func _should_place_air_at_height(y: int, height: int) -> bool:
	return y == -height - 1 and settings.air_layer
