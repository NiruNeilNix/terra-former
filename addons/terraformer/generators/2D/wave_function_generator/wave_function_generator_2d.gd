@icon("wave_function_generator.svg")
@tool
class_name WaveFunctionGenerator2D
extends TerraGenerator2D

const ADJACENT_NEIGHBORS: Dictionary = {
	"right": Vector2i.RIGHT, 
	"left": Vector2i.LEFT, 
	"up": Vector2i.UP, 
	"down": Vector2i.DOWN
}

@export var settings: WaveFunctionGenerator2DSettings
## Limit max iterations to avoid infinite loops.
@export var max_iterations: int = 10000

var _wave_function: Dictionary


func generate(starting_grid: MapGrid = null) -> void:
	if not _can_generate():
		return

	generation_started.emit()
	var _time_now: int = Time.get_ticks_msec()

	_assign_starting_grid(starting_grid)

	_initialize_wave_function()
	_perform_wave_function_collapse()
	_place_collapsed_tiles()

	_apply_modifiers(settings.modifiers)
	_wave_function.clear()

	if _has_next_pass():
		next_pass.generate(grid)
		return

	_log_generation_time(_time_now)
	grid_updated.emit()
	generation_finished.emit()

func _collapse(coords: Vector2i) -> void:
	var entries: Array = _wave_function[coords].duplicate()
	if entries.is_empty():
		return

	var chosen_entry = _select_weighted_entry(entries)
	_wave_function[coords] = [chosen_entry]

func _is_collapsed() -> bool:
	for tile in _wave_function:
		if _wave_function[tile].size() != 1:
			return false

	return true

func _propagate(coords: Vector2i) -> void:
	var propagation_stack = [coords]

	while propagation_stack.size() > 0:
		var current_coords = propagation_stack.pop_back()
		_propagate_to_neighbors(current_coords, propagation_stack)

func _get_possible_neighbors(coords: Vector2i, direction: Vector2i) -> Array[WaveFunction2DEntry]:
	var possible_neighbors: Array[WaveFunction2DEntry]
	var dir_key = ADJACENT_NEIGHBORS.find_key(direction)
	for entry in _wave_function[coords]:
		for other_entry in _wave_function[coords + direction]:
			if other_entry.tile_info.id in entry.get("neighbors_%s" % dir_key):
				possible_neighbors.append(other_entry)

	return possible_neighbors

func _get_lowest_entropy_coords() -> Vector2i:
	var lowest_entropy: float = -1.0
	var lowest_entropy_coords: Vector2i = Vector2i.ZERO
	
	for coords in _wave_function:
		if _is_cell_collapsed(coords):
			continue

		var entropy_with_noise: float = _calculate_entropy_with_noise(coords)
		if _is_entropy_lower(entropy_with_noise, lowest_entropy):
			lowest_entropy = entropy_with_noise
			lowest_entropy_coords = coords

	return lowest_entropy_coords


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


func _initialize_wave_function() -> void:
	for x in settings.world_size.x:
		for y in settings.world_size.y:
			_wave_function[Vector2i(x, y)] = settings.entries.duplicate(true)


func _perform_wave_function_collapse() -> void:
	var iterations = 0
	while not _is_collapsed() and iterations < max_iterations:
		iterations += 1
		var coords := _get_lowest_entropy_coords()
		_collapse(coords)
		_propagate(coords)

	if iterations == max_iterations:
		push_error("Generation reached max iterations.")


func _place_collapsed_tiles() -> void:
	for cell in _wave_function:
		grid.set_value(cell, _wave_function[cell][0].tile_info)


func _select_weighted_entry(entries: Array) -> WaveFunction2DEntry:
	var total_weight: float = 0.0
	for entry in entries:
		total_weight += entry.weight

	var random_value := randf_range(0.0, total_weight)
	for entry in entries:
		random_value -= entry.weight
		if random_value < 0.0:
			return entry
	return entries[0]  # fallback


func _propagate_to_neighbors(current_coords: Vector2i, propagation_stack: Array) -> void:
	for direction in ADJACENT_NEIGHBORS.values():
		var neighbor_coords: Vector2i = current_coords + direction
		if not _wave_function.has(neighbor_coords):
			continue

		if _update_neighbor_constraints(current_coords, neighbor_coords, direction):
			if not neighbor_coords in propagation_stack:
				propagation_stack.append(neighbor_coords)


func _update_neighbor_constraints(current_coords: Vector2i, neighbor_coords: Vector2i, direction: Vector2i) -> bool:
	var possible_neighbors := _get_possible_neighbors(current_coords, direction)
	if possible_neighbors.size() == 0:
		return false

	var neighbor_entries: Array = _wave_function[neighbor_coords].duplicate()
	var had_changes = false

	for neighbor_entry in neighbor_entries:
		if not neighbor_entry in possible_neighbors:
			_wave_function[neighbor_coords].erase(neighbor_entry)
			had_changes = true

	return had_changes


func _is_cell_collapsed(coords: Vector2i) -> bool:
	return _wave_function[coords].size() == 1


func _calculate_entropy_with_noise(coords: Vector2i) -> float:
	return _wave_function[coords].size() + (randf() / 1000)


func _is_entropy_lower(entropy: float, current_lowest: float) -> bool:
	return entropy < current_lowest or current_lowest == -1
