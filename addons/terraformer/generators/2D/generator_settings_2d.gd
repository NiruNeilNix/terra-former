@icon("../generator_settings.svg")
class_name GeneratorSettings2D
extends Resource

@export var modifiers: Array[Modifier2D]  # TODO: Replace with custom control for easier editing. Similar to Blender.

func _init() -> void:
	if resource_name == "":
		resource_name = "Settings"
