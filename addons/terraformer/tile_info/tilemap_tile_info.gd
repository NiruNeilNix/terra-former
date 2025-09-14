@tool
class_name TilemapTileInfo
extends TileInfo

enum Type { SINGLE_CELL, TERRAIN, PATTERN } 
@export var type: Type = Type.SINGLE_CELL:
	set(value):
		type = value
		notify_property_list_changed()

@export var tilemap_layer: int = 0
@export var source_id: int = 0
@export var atlas_coord: Vector2i = Vector2i.ZERO
@export var alternative_tile: int = 0
@export var terrain_set: int = 0
@export var terrain: int = 0
@export var pattern_idx: int = 0
@export var pattern_offset: Vector2i = Vector2i.ZERO

# Property Validation

var properties : Dictionary = {
	Type.SINGLE_CELL:
		func (name) -> bool: return name in ["source_id", 
		"atlas_coord", 
		"alternative_tile"],
	Type.TERRAIN:
		func (name) -> bool: return name.begins_with("terrain"),
	Type.PATTERN:
		func (name) -> bool: return name.begins_with("pattern"),
}

func _validate_property(property: Dictionary) -> void:
	var props = properties.keys().filter(func (key): return type != key)
	for prop_type in props:
		if (properties[prop_type] as Callable).call(property.name):
			property.usage = PROPERTY_USAGE_NONE
			return
