@tool
class_name ChunkAwareModifier2D
extends Modifier2D

@export var salt: int = 134178497321

func _init() -> void:
	salt = randi()

func apply(grid: MapGrid, generator: TerraGenerator) -> void:
	_configure_noise_if_needed(generator)
	_apply_area(generator.grid.get_area(), grid, generator)

func apply_chunk(grid: MapGrid, generator: ChunkAwareGenerator2D, chunk_position: Vector2i) -> void:
	_configure_noise_if_needed(generator)
	var chunk_area := Rect2i(chunk_position * generator.chunk_size, generator.chunk_size)
	_apply_area(chunk_area, grid, generator)

func _apply_area(area: Rect2i, grid: MapGrid, _generator: TerraGenerator) -> void:
	push_warning("%s doesn't have an `_apply_area` implementation" % resource_name)

func _validate_property(property: Dictionary) -> void:
	super(property)
	if property.name == "noise" and self.get("use_generator_noise") == true:
		property.usage = PROPERTY_USAGE_NONE

func _configure_noise_if_needed(generator: TerraGenerator) -> void:
	if not "noise" in self:
		return
	if self.get("use_generator_noise") == true and generator.settings.get("noise") != null:
		self.set("noise", generator.settings.noise)
		return
	var noise := self.get("noise") as FastNoiseLite
	noise.seed = salt + generator.seed
