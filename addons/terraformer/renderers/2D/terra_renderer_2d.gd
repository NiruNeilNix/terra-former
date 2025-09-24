class_name TerraRenderer2D
extends TerraRenderer

signal area_rendered(area: Rect2i)

signal chunk_rendered(chunk_position: Vector2i)

func _draw_area(area: Rect2i) -> void:
	push_warning("_draw_area at %s not overriden" % name)

func _draw_chunk(chunk_position: Vector2i) -> void:
	_draw_area(Rect2i(chunk_position * generator.chunk_size, generator.chunk_size))
	chunk_rendered.emit(chunk_position)

func _draw() -> void:
	_draw_area(generator.grid.get_area())
	grid_rendered.emit()

func _connect_signals() -> void:
	super()
	if _generator_supports_chunks():
		generator.chunk_updated.connect(_draw_chunk)

func _generator_supports_chunks() -> bool:
	return generator.has_signal("chunk_updated")
