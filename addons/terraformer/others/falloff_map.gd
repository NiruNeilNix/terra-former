@tool
class_name FalloffMap
extends Resource

@export var texture: Texture2D
@export_range(0.0, 1.0, 0.01) var falloff_start: float = 0.5:
	set(value):
		falloff_start = value
		_generate()
@export_range(0.0, 1.0, 0.01) var falloff_end: float = 1.0:
	set(value):
		falloff_end = value
		_generate()

var map: Dictionary
var size: Vector2i = Vector2i(256, 256):
	set(value):
		size = value
		_generate()


func _generate() -> void:
	map.clear()

	var image = Image.create(size.x, size.y, false, Image.FORMAT_L8)

	for x in size.x:
		for y in size.y:
			# Values from -1 to 1.
			var i: float = x / float(size.x) * 2 - 1
			var j: float = y / float(size.y) * 2 - 1

			# Get closest to 1.
			var value: float = maxf(absf(i), absf(j))

			if value < falloff_start:
				map[Vector2i(x, y)] = 1.0
			elif value > falloff_end:
				map[Vector2i(x, y)] = 0.0
			else:
				map[Vector2i(x, y)] = smoothstep(1.0, 0.0, inverse_lerp(falloff_start, falloff_end, value))

			var img_color: Color = Color.WHITE
			img_color.v = map[Vector2i(x, y)]
			image.set_pixel(x, y, img_color)

	texture = ImageTexture.create_from_image(image)


func get_value(position: Vector2i) -> float:
	if map.has(position):
		return map[position]
	else:
		return 0.0


func _init() -> void:
	_generate()
