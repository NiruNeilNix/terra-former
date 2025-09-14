@tool
@icon("generator.svg")
class_name TerraGenerator

extends Node

signal grid_updated
signal generation_started
signal generation_finished


@export var editor_preview: bool = true:
	set(value):
		editor_preview = value
		if value == false:
			erase()

@export var generate_on_ready: bool = true
@export var random_seed: bool = true:
	set(value):
		random_seed = value
		notify_property_list_changed()
@export var seed: int = 0:
	set = set_seed,
	get = get_seed

var grid: MapGrid:
	get = get_grid

func _ready() -> void:
	if random_seed:
		seed = randi()

	generation_started.connect(_on_generation_started)

	if Engine.is_editor_hint():
		return
		
	await get_tree().process_frame

	if generate_on_ready:
		generate()

func generate(starting_grid: MapGrid = null) -> void:
	push_warning("generate method at %s not overriden" % name)

func run_generation(do_generate: Callable, starting_grid: MapGrid = null, modifiers: Array = []) -> void:
	if not _can_preview_in_editor():
		return

	generation_started.emit()

	var _time_now: int = Time.get_ticks_msec()
	_assign_starting_grid(starting_grid)

	do_generate.call()

	if not modifiers.is_empty():
		_apply_modifiers(modifiers)

	var _time_elapsed: int = Time.get_ticks_msec() - _time_now
	if OS.is_debug_build():
		print("%s: Generating took %s seconds" % [name, float(_time_elapsed) / 1000])

	grid_updated.emit()
	generation_finished.emit()

func erase() -> void:
	if grid != null:
		grid.clear()
		grid_updated.emit()

func get_grid() -> MapGrid:
	return grid

func set_seed(value: int) -> void:
	seed = value

func get_seed() -> int:
	return seed

func serialize() -> PackedByteArray:
	return var_to_bytes(grid.get_grid())

func deserialize(bytes: PackedByteArray):
	grid.set_grid_serialized(bytes)
	grid_updated.emit()


### Modifiers ###
func _apply_modifiers(modifiers) -> void:
	for modifier in modifiers:
		if not (modifier is Modifier) or modifier.enabled == false:
			continue

		modifier.apply(grid, self)

func _on_generation_started() -> void:
	if random_seed:
		seed = randi()

	seed(seed)

func _validate_property(property: Dictionary) -> void:
	if property.name == "seed" and random_seed:
		property.usage = PROPERTY_USAGE_NONE

func _can_preview_in_editor() -> bool:
	if not Engine.is_editor_hint():
		return true
	if editor_preview:
		return true
	push_warning("%s: Editor Preview is not enabled so nothing happened!" % name)
	return false

func _assign_starting_grid(starting_grid: MapGrid) -> void:
	if starting_grid == null:
		erase()
		return
	grid = starting_grid
