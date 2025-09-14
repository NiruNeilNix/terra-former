@tool
class_name NoiseGeneratorData
extends Resource

@export var title: String = "":
	set(value):
		title = value
		resource_name = title

@export var tile: TileInfo

@export_group("Thresholds")

@export_range(-1.0, 1.0) var min: float = -1.0:
	set(value):
		min = value
		if min > max:
			max = min
		emit_changed()

@export_range(-1.0, 1.0) var max: float = 1.0:
	set(value):
		max = value
		if max < min:
			min = max
		emit_changed()

var settings: NoiseGeneratorSettings:
	set(value):
		settings = value
		settings.noise.changed.connect(emit_changed)
