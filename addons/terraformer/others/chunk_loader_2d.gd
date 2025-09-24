@tool
@icon("chunk_loader.svg")
class_name ChunkLoader2D
extends Node2D

@export var generator: ChunkAwareGenerator2D
@export var actor: Node2D
@export var loading_radius: Vector2i = Vector2i(2, 2)
@export_range(0, 1, 1, "or_greater", "suffix:ms") var update_rate: int = 0
@export var load_on_ready: bool = true
@export var unload_chunks: bool = true
@export var load_closest_chunks_first: bool = true

var _last_run: int = 0
var _last_position: Vector2i


func _ready() -> void:
	if not _can_initialize():
		return

	await get_tree().process_frame

	generator.erase()
	if load_on_ready:
		_update_loading(_get_actors_position())


func _process(delta: float) -> void:
	if not _can_process():
		return

	var current_time = Time.get_ticks_msec()
	if not _should_update_now(current_time):
		return
	_try_loading()
	_last_run = current_time


# checks if chunk loading is neccessary and executes if true
func _try_loading() -> void:
	var actor_position: Vector2i = _get_actors_position()

	if actor_position == _last_position:
		return

	_last_position = actor_position
	_update_loading(actor_position)


# loads needed chunks around the given position
func _update_loading(actor_position: Vector2i) -> void:
	if not _is_generator_valid():
		return

	var required_chunks: PackedVector2Array = _get_required_chunks(actor_position)

	_unload_old_chunks_if_enabled(required_chunks)
	_load_new_chunks(required_chunks)


func _get_actors_position() -> Vector2i:
	# getting actors positions
	var actor_position := Vector2.ZERO
	if actor != null:
		actor_position = actor.global_position

	var map_position := generator.global_to_map(actor_position)
	var chunk_position := generator.map_to_chunk(map_position)

	return chunk_position


func _get_required_chunks(actor_position: Vector2i) -> PackedVector2Array:
	var chunks: Array[Vector2] = []

	var x_range = range(actor_position.x - abs(loading_radius).x, actor_position.x + abs(loading_radius).x + 1)
	var y_range = range(actor_position.y - abs(loading_radius).y, actor_position.y + abs(loading_radius).y + 1)

	for x in x_range:
		for y in y_range:
			chunks.append(Vector2(x, y))

	if load_closest_chunks_first:
		chunks.sort_custom(
			func(chunk1: Vector2, chunk2: Vector2): return (
				chunk1.distance_squared_to(actor_position) < chunk2.distance_squared_to(actor_position)
			)
		)
	return PackedVector2Array(chunks)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not is_instance_valid(generator):
		warnings.append("Generator is required!")

	return warnings


func _can_initialize() -> bool:
	return not Engine.is_editor_hint() and is_instance_valid(generator)


func _can_process() -> bool:
	return not Engine.is_editor_hint() and is_instance_valid(generator)


func _should_update_now(current_time: int) -> bool:
	return current_time - _last_run > update_rate


func _is_generator_valid() -> bool:
	if generator == null:
		push_error("Chunk loading failed because generator property not set!")
		return false
	return true


func _unload_old_chunks_if_enabled(required_chunks: PackedVector2Array) -> void:
	if not unload_chunks:
		return
	var loaded_chunks: PackedVector2Array = generator.generated_chunks
	for i in range(loaded_chunks.size() - 1, -1, -1):
		var loaded: Vector2 = loaded_chunks[i]
		if not (loaded in required_chunks):
			generator.unload_chunk(loaded)


func _load_new_chunks(required_chunks: PackedVector2Array) -> void:
	for required in required_chunks:
		if not generator.has_chunk(required):
			generator.generate_chunk(required)
