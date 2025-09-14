class_name WaveFunction2DEntry
extends Resource

@export var tile_info: TileInfo

@export var weight: float = 1.0
@export_group("Valid Neighbors", "neighbors_")

@export var neighbors_up: Array[StringName]
@export var neighbors_down: Array[StringName]
@export var neighbors_left: Array[StringName]
@export var neighbors_right: Array[StringName]
