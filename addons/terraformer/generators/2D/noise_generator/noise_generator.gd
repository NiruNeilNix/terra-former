@tool
@icon("noise_generator.svg")
class_name NoiseGenerator
extends ChunkAwareGenerator2D

@export var settings: NoiseGeneratorSettings


func generate(starting_grid: MapGrid = null) -> void:
	if not _can_generate():
		return

	generation_started.emit()
	var _time_now: int = Time.get_ticks_msec()

	_configure_noise_seed()
	_assign_starting_grid(starting_grid)

	_set_grid()
	_apply_modifiers(settings.modifiers)

	if _has_next_pass():
		next_pass.generate(grid)
		return

	_log_generation_time(_time_now)
	grid_updated.emit()
	generation_finished.emit()


func generate_chunk(chunk_position: Vector2i, starting_grid: MapGrid = null) -> void:
	if not _can_generate_chunk():
		return

	_assign_chunk_starting_grid(chunk_position, starting_grid)

	_set_grid_chunk(chunk_position)
	_apply_modifiers_chunk(settings.modifiers, chunk_position)

	generated_chunks.append(chunk_position)

	if _has_chunk_aware_next_pass():
		next_pass.generate_chunk(chunk_position, grid)
		return

	_emit_chunk_signals(chunk_position)


func _set_grid() -> void:
	_set_grid_area(Rect2i(Vector2i.ZERO, Vector2i(settings.world_size)))


func _set_grid_chunk(chunk_position: Vector2i) -> void:
	_set_grid_area(Rect2i(chunk_position * chunk_size, chunk_size))


func _set_grid_area(rect: Rect2i) -> void:
	for x in range(rect.position.x, rect.end.x):
		if not _is_position_valid(x, settings.world_size.x):
			continue

		for y in range(rect.position.y, rect.end.y):
			if not _is_position_valid(y, settings.world_size.y):
				continue

			var noise_value = _calculate_noise_at_position(x, y)
			_place_tile_if_matches_threshold(x, y, noise_value)


func _can_generate() -> bool:
	if Engine.is_editor_hint() and not editor_preview:
		push_warning("%s: Editor Preview is not enabled so nothing happened!" % name)
		return false
	if not settings:
		push_error("%s doesn't have a settings resource" % name)
		return false
	return true


func _can_generate_chunk() -> bool:
	if Engine.is_editor_hint() and not editor_preview:
		return false
	if not settings:
		push_error("%s doesn't have a settings resource" % name)
		return false
	return true


func _configure_noise_seed() -> void:
	settings.noise.seed = seed


func _assign_starting_grid(starting_grid: MapGrid) -> void:
	if starting_grid == null:
		erase()
		return
	grid = starting_grid


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


func _log_generation_time(start_time: int) -> void:
	var elapsed_time: int = Time.get_ticks_msec() - start_time
	if OS.is_debug_build():
		print("%s: Generating took %s seconds" % [name, float(elapsed_time) / 1000])


func _emit_chunk_signals(chunk_position: Vector2i) -> void:
	(func(): chunk_updated.emit(chunk_position)).call_deferred()
	(func(): chunk_generation_finished.emit(chunk_position)).call_deferred()


func _is_position_valid(position: int, world_size: int) -> bool:
	if settings.infinite:
		return true
	return position >= 0 and position <= world_size


func _calculate_noise_at_position(x: int, y: int) -> float:
	var noise_value = settings.noise.get_noise_2d(x, y)
	if settings.falloff_enabled and settings.falloff_map and not settings.infinite:
		noise_value = ((noise_value + 1) * settings.falloff_map.get_value(Vector2i(x, y))) - 1.0
	return noise_value


func _place_tile_if_matches_threshold(x: int, y: int, noise_value: float) -> void:
	for tile_data in settings.tiles:
		if noise_value >= tile_data.min and noise_value <= tile_data.max:
			grid.set_valuexy(x, y, tile_data.tile)
