@tool
@icon("../chunk_aware_generator.svg")
class_name ChunkAwareGenerator2D
extends TerraGenerator2D

signal chunk_updated(chunk_position: Vector2i)
signal chunk_generation_finished(chunk_position: Vector2i)
signal chunk_erased(chunk_position: Vector2i)


@export var chunk_size: Vector2i = Vector2i(16, 16)

var generated_chunks: Array[Vector2i] = []


func _ready() -> void:
	if _is_chunk_size_valid():
		super._ready()
		return
	push_error("Invalid chunk size!")


func generate_chunk(chunk_position: Vector2i, starting_grid: MapGrid = null) -> void:
	push_warning("generate_chunk method not overriden at %s" % name)


func erase_chunk(chunk_position: Vector2i) -> void:
	for x in get_chunk_axis_range(chunk_position.x, chunk_size.x):
		for y in get_chunk_axis_range(chunk_position.y, chunk_size.y):
			for layer in grid.get_layer_count():
				grid.erase(Vector2i(x, y), layer)

	(func(): chunk_updated.emit(chunk_position)).call_deferred()  # deferred for threadability
	(func(): chunk_erased.emit(chunk_position)).call_deferred()  # deferred for threadability


func _apply_modifiers_chunk(modifiers: Array[Modifier2D], chunk_position: Vector2i) -> void:
	for modifier in modifiers:
		if not _can_apply_modifier(modifier):
			continue
		modifier.apply_chunk(grid, self, chunk_position)


func unload_chunk(chunk_position: Vector2i) -> void:
	erase_chunk(chunk_position)
	generated_chunks.erase(chunk_position)

	if _has_chunk_aware_next_pass():
		next_pass.unload_chunk(chunk_position)


### Utils ###


func has_chunk(chunk_position: Vector2i) -> bool:
	return generated_chunks.has(chunk_position)


func get_chunk_axis_range(position: int, axis_size: int) -> Array:
	return range(position * axis_size, (position + 1) * axis_size, 1)


## Returns the coordinates of the chunk containing the cell at the given [param map_position].
func map_to_chunk(map_position: Vector2i) -> Vector2i:
	return Vector2i(floori(float(map_position.x) / chunk_size.x), floori(float(map_position.y) / chunk_size.y))


func _is_chunk_size_valid() -> bool:
	return chunk_size.x > 0 and chunk_size.y > 0


func _can_apply_modifier(modifier: Modifier2D) -> bool:
	if not modifier is ChunkAwareModifier2D:
		push_error("%s is not a Chunk compatible modifier!" % modifier.resource_name)
		return false
	if not modifier.enabled:
		return false
	return true


func _has_chunk_aware_next_pass() -> bool:
	return is_instance_valid(next_pass) and next_pass is ChunkAwareGenerator2D
