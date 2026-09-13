extends SceneTree

const INPUT := "res://assets/environment/props/estate_domestic/estate_domestic_props.png"
const OUTPUT := "res://assets/environment/props/estate_domestic/estate_domestic_props_alpha.png"


func _init() -> void:
	var image := Image.load_from_file(INPUT)
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var mask := PackedByteArray()
	mask.resize(width * height)
	var queue := PackedInt32Array()
	for x in width:
		_try_add(image, mask, queue, x, 0, width)
		_try_add(image, mask, queue, x, height - 1, width)
	for y in height:
		_try_add(image, mask, queue, 0, y, width)
		_try_add(image, mask, queue, width - 1, y, width)
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var x := index % width
		var y := index / width
		_try_add(image, mask, queue, x - 1, y, width)
		_try_add(image, mask, queue, x + 1, y, width)
		_try_add(image, mask, queue, x, y - 1, width)
		_try_add(image, mask, queue, x, y + 1, width)
	for pass_index in 2:
		var fringe := PackedInt32Array()
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				var index := y * width + x
				if mask[index] == 1 or not _is_fringe(image.get_pixel(x, y)):
					continue
				if mask[index - 1] == 1 or mask[index + 1] == 1 or mask[index - width] == 1 or mask[index + width] == 1:
					fringe.append(index)
		for index in fringe:
			mask[index] = 1
	for index in mask.size():
		if mask[index] == 0:
			continue
		var x := index % width
		var y := index / width
		var color := image.get_pixel(x, y)
		color.a = 0.0
		image.set_pixel(x, y, color)
	var result := image.save_png(OUTPUT)
	print("DOMESTIC ALPHA: ", result, " size=", image.get_size(), " used=", image.get_used_rect())
	quit(0 if result == OK else 1)


func _try_add(image: Image, mask: PackedByteArray, queue: PackedInt32Array, x: int, y: int, width: int) -> void:
	if x < 0 or y < 0 or x >= width or y >= image.get_height():
		return
	var index := y * width + x
	if mask[index] == 1 or not _is_background(image.get_pixel(x, y)):
		return
	mask[index] = 1
	queue.append(index)


func _is_background(color: Color) -> bool:
	var low := minf(color.r, minf(color.g, color.b))
	var high := maxf(color.r, maxf(color.g, color.b))
	return low >= 0.38 and high - low <= 0.12


func _is_fringe(color: Color) -> bool:
	var low := minf(color.r, minf(color.g, color.b))
	var high := maxf(color.r, maxf(color.g, color.b))
	return low >= 0.20 and high - low <= 0.10
