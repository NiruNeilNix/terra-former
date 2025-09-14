@tool
class_name NoiseGeneratorSettings
extends GeneratorSettings2D

@export var tiles: Array[NoiseGeneratorData]:
	set(value):
		if value.size() > 0:
			value[-1] = value[-1] if value[-1] is NoiseGeneratorData else NoiseGeneratorData.new()

		tiles = value
		for tile_data in tiles:
			tile_data.settings = self
@export var noise: FastNoiseLite = FastNoiseLite.new()

@export var infinite: bool = false :
	set(value):
		infinite = value
		notify_property_list_changed()
@export var world_size: Vector2i = Vector2i(256, 256):
	set(value):
		world_size = value
		if is_instance_valid(falloff_map):
			falloff_map.size = world_size
@export_group("Falloff", "falloff_")
#
@export var falloff_enabled: bool = false

@export var falloff_map: FalloffMap:
	set(value):
		falloff_map = value
		if falloff_map != null:
			falloff_map.size = world_size


func _validate_property(property: Dictionary) -> void:
	if property.name == "world_size" and infinite == true:
		property.usage = PROPERTY_USAGE_NONE
