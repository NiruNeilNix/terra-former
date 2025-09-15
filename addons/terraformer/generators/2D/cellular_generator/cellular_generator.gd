@tool
@icon("cellular_generator.svg")
class_name CellularGenerator
extends TerraGenerator2D
## Generates a random noise grid, then uses cellular automata to smooth it out.
## Useful for islands-like terrain.
## @tutorial(Generators): https://benjatk.github.io/Gaea/#/generators/
## @tutorial(CellularGenerator): https://benjatk.github.io/Gaea/#/generators/cellular

@export var settings: CellularGeneratorSettings


func generate(starting_grid: MapGrid = null) -> void:
	if not _can_generate():
		return

	generation_started.emit()
	var _time_now: int = Time.get_ticks_msec()

	_assign_starting_grid(starting_grid)

	_set_noise()
	_smooth()
	_apply_modifiers(settings.modifiers)

	if _has_next_pass():
		next_pass.generate(grid)
		return

	_log_generation_time(_time_now)
	grid_updated.emit()
	generation_finished.emit()


func _set_noise() -> void:
	for x in range(settings.world_size.x):
		for y in range(settings.world_size.y):
			if randf() > settings.noise_density:
				grid.set_valuexy(x, y, settings.tile)
			else:
				grid.set_valuexy(x, y, null)


func _smooth() -> void:
	for iteration in settings.smooth_iterations:
		var temp_grid: MapGrid = grid.clone()

		for cell in grid.get_cells(settings.tile.layer):
			_apply_smoothing_rules(cell, temp_grid)

		grid = temp_grid

	grid.erase_invalid()


### Editor ###


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not settings:
		warnings.append("Needs CellularGeneratorSettings to work.")

	return warnings


func _can_generate() -> bool:
	if Engine.is_editor_hint() and not editor_preview:
		push_warning("%s: Editor Preview is not enabled so nothing happened!" % name)
		return false
	if not settings:
		push_error("%s doesn't have a settings resource" % name)
		return false
	return true


func _assign_starting_grid(starting_grid: MapGrid) -> void:
	if starting_grid == null:
		erase()
		return
	grid = starting_grid


func _has_next_pass() -> bool:
	return is_instance_valid(next_pass)


func _log_generation_time(start_time: int) -> void:
	var elapsed_time: int = Time.get_ticks_msec() - start_time
	if OS.is_debug_build():
		print("%s: Generating took %s seconds" % [name, float(elapsed_time) / 1000])


func _apply_smoothing_rules(cell: Vector2i, temp_grid: MapGrid) -> void:
	var empty_neighbors_count: int = grid.get_amount_of_empty_neighbors(cell, settings.tile.layer)
	var cell_value = grid.get_value(cell, settings.tile.layer)
	
	if cell_value != null and empty_neighbors_count > settings.max_floor_empty_neighbors:
		temp_grid.set_value(cell, null)
	elif cell_value == null and empty_neighbors_count <= settings.min_empty_neighbors:
		temp_grid.set_value(cell, settings.tile)
